import 'dart:async';
import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'alerts_api_config.dart';
import 'aws_sigv4.dart';

/// Runs in `flutter_foreground_task`'s background isolate — entry point registered via
/// `FlutterForegroundTask.startService(callback: cameraAlertsStartCallback)`.
@pragma('vm:entry-point')
void cameraAlertsStartCallback() {
  FlutterForegroundTask.setTaskHandler(CameraAlertsTaskHandler());
}

/// Background-isolate half of the always-on WAN alert listener. Maintains one direct
/// MQTT-over-WSS subscription per watched camera to `vizenlink/alerts/<thing>` — kept alive
/// independent of any single screen's lifecycle.
///
/// **Credentials and camera list are pushed in from the main isolate** (`CameraAlertsHub`), not
/// fetched here — this isolate has no direct access to the app's auth session (deliberately:
/// keeps exactly one place, the main isolate, responsible for auth/token refresh).
class CameraAlertsTaskHandler extends TaskHandler {
  final Map<String, MqttServerClient> _clients = {};
  Set<String> _desiredThingNames = {};
  String? _region;
  String? _iotEndpoint;
  AlertsCredentials? _credentials;
  FlutterLocalNotificationsPlugin? _notifications;
  int _notificationId = 2000;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await plugin.initialize(
        settings: const InitializationSettings(android: androidInit),
      );
      _notifications = plugin;
    } catch (_) {
      // Best-effort — camera state still reaches the UI via sendDataToMain even if a local
      // notification can't be shown for some reason.
    }
  }

  /// Data pushed from `CameraAlertsHub` (main isolate) via `sendDataToTask`:
  /// `{"action": "sync", "region": ..., "iotEndpoint": ..., "credentials": {...}, "cameras":
  /// [{"thingName": ...}, ...]}`.
  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (map['action'] != 'sync') return;

    _region = map['region'] as String?;
    _iotEndpoint = map['iotEndpoint'] as String?;
    final credsMap = map['credentials'] as Map?;
    if (credsMap != null) {
      _credentials = AlertsCredentials(
        accessKeyId: credsMap['accessKeyId'] as String,
        secretKey: credsMap['secretKey'] as String,
        sessionToken: credsMap['sessionToken'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          credsMap['expiresAtMs'] as int,
          isUtc: true,
        ),
      );
    }
    final cameras = (map['cameras'] as List?)?.cast<Object?>() ?? const [];
    _desiredThingNames = cameras
        .map((c) => (c as Map)['thingName'] as String)
        .toSet();

    _reconcile();
  }

  void _reconcile() {
    final toRemove = _clients.keys.where((t) => !_desiredThingNames.contains(t)).toList();
    for (final thingName in toRemove) {
      _clients.remove(thingName)?.disconnect();
    }
    for (final thingName in _desiredThingNames) {
      if (!_clients.containsKey(thingName)) {
        unawaited(_connect(thingName));
      }
    }
    _reportStatus();
  }

  Future<void> _connect(String thingName) async {
    final creds = _credentials;
    final region = _region;
    final endpoint = _iotEndpoint;
    if (creds == null || region == null || endpoint == null) return;

    try {
      final url = AwsSigV4.presignWebSocketUrl(
        credentials: creds,
        endpoint: endpoint,
        region: region,
      );
      // Client ID must be prefixed `vizenlink-` — required by the app's IoT policy's
      // `iot:Connect` resource scope.
      final clientId = 'vizenlink-${DateTime.now().microsecondsSinceEpoch}';
      final client = MqttServerClient(url.toString(), clientId)
        ..useWebSocket = true
        ..port = 443
        ..websocketProtocols = MqttClientConstants.protocolsSingleDefault
        ..keepAlivePeriod = 30
        // [AI Fix] deliberately NOT the library's own autoReconnect: the presigned WS URL is
        // SigV4-signed against the credentials active at connect time, so it goes stale exactly
        // when the temp credentials it was signed with expire. mqtt_client's built-in
        // autoReconnect would keep retrying against that same, now-permanently-invalid URL
        // string forever. Reconnects are instead driven entirely by this class: onDisconnected
        // below drops the stale entry, and onRepeatEvent/_reconcile() rebuild a fresh signed URL
        // from whatever credentials CameraAlertsHub most recently pushed down.
        ..autoReconnect = false
        ..logging(on: false);
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean();
      client.onDisconnected = () {
        // Only drop our own record if this is still the active client for this camera — avoids
        // a stale callback (from a client _reconcile() already replaced) clobbering a newer,
        // healthy connection's entry.
        if (identical(_clients[thingName], client)) {
          _clients.remove(thingName);
          _reportStatus();
        }
      };

      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        client.disconnect();
        return;
      }

      _clients[thingName] = client;
      client.subscribe('vizenlink/alerts/$thingName', MqttQos.atMostOnce);
      client.updates?.listen((events) => _onMessages(thingName, events));
      _reportStatus();
    } catch (_) {
      // Will retry on the next reconcile (either a fresh `sync` push or the periodic
      // onRepeatEvent self-heal below) — best-effort, this isolate has no UI to surface an
      // error to directly. Most common real cause: _credentials are stale (expired since the
      // last sync) — the retry only succeeds once a fresh sync arrives, same as any other
      // connect failure.
    }
  }

  void _onMessages(String thingName, List<MqttReceivedMessage<MqttMessage?>> events) {
    for (final event in events) {
      final message = event.payload;
      if (message is! MqttPublishMessage) continue;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      _handleAlertPayload(thingName, payload);
    }
  }

  void _handleAlertPayload(String thingName, String payload) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final eventName = decoded['event'];
    FlutterForegroundTask.sendDataToMain({
      'type': 'alert',
      'thingName': thingName,
      'event': eventName,
      'body': decoded,
    });

    // Dispatch plumbing above is already generic — a new alert type is just another case here.
    // Real-device finding 2026-08-15: PersonDetected had no case here at all — the alert still
    // reached AlertHistoryStore via sendDataToMain above (so it showed up as "logged" in the
    // Alerts tab), but no push notification was ever shown for it, unlike the two cases below.
    if (eventName == 'VideoModeChanged') {
      final mode = decoded['mode'];
      final label = mode == 'day' ? 'Day' : 'Night';
      unawaited(_showAlertNotification(
        'Day/Night mode changed',
        'Camera $thingName is now $label',
      ));
    } else if (eventName == 'PrivacyModeChanged') {
      final isOn = decoded['mode'] == 'on';
      unawaited(_showAlertNotification(
        'Privacy Mode changed',
        'Camera $thingName privacy mode is now ${isOn ? 'ON' : 'OFF'}',
      ));
    } else if (eventName == 'PersonDetected') {
      final personCount = (decoded['person_count'] as num?)?.toInt() ?? 1;
      unawaited(_showAlertNotification(
        'Person detected',
        personCount > 1
            ? 'Camera $thingName detected $personCount people'
            : 'Camera $thingName detected a person',
      ));
    }
  }

  Future<void> _showAlertNotification(String title, String body) async {
    final notifications = _notifications;
    if (notifications == null) return;
    const androidDetails = AndroidNotificationDetails(
      'camera_alerts',
      'Camera Alerts',
      channelDescription: 'Alerts from your VizenLink cameras',
      importance: Importance.high,
      priority: Priority.high,
    );
    try {
      await notifications.show(
        id: _notificationId++,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(android: androidDetails),
      );
    } catch (_) {
      // Best-effort.
    }
  }

  void _reportStatus() {
    FlutterForegroundTask.sendDataToMain({
      'type': 'status',
      'connected': _clients.keys.toList(),
      'watched': _desiredThingNames.toList(),
    });
  }

  /// Belt-and-suspenders alongside `onDisconnected` above — a graceless drop (e.g. the phone
  /// briefly losing all connectivity) doesn't always fire that callback promptly, so this also
  /// directly checks each client's real `connectionStatus.state` and drops any that's no longer
  /// `connected`, so the loop below reconnects it with fresh credentials rather than leaving a
  /// dead entry sitting in `_clients` forever.
  void _pruneStaleConnections() {
    final stale = _clients.entries
        .where((e) => e.value.connectionStatus?.state != MqttConnectionState.connected)
        .map((e) => e.key)
        .toList();
    for (final thingName in stale) {
      _clients.remove(thingName);
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _pruneStaleConnections();
    // Self-heal: retry any desired camera that isn't currently connected — either a transient
    // failure on the last _connect() attempt, or a drop just caught by the prune above (most
    // often caused by the temp credentials it was signed with expiring) — without waiting for
    // the main isolate to push a fresh `sync`. A reconnect this triggers uses whatever
    // credentials are currently held, which may itself still be stale until CameraAlertsHub's
    // own periodic re-sync (well inside the credential lifetime) lands — this just keeps
    // retrying every tick until a fresh sync makes it succeed.
    for (final thingName in _desiredThingNames) {
      if (!_clients.containsKey(thingName)) {
        unawaited(_connect(thingName));
      }
    }
    _reportStatus();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    for (final client in _clients.values) {
      client.disconnect();
    }
    _clients.clear();
  }

  /// `[AI Fix]` real-device finding: on Android 14+ the platform lets the user swipe away a
  /// foreground service's notification without stopping the service (the plugin only wires
  /// `setDeleteIntent`/this callback from `UPSIDE_DOWN_CAKE` onward) — but leaving this as a
  /// no-op meant a swiped notification just stayed gone, with nothing confirming (or restoring
  /// visibility into) whether the service and its MQTT connections were still actually alive
  /// underneath. Proactively re-posts the ongoing notification so it doesn't silently disappear,
  /// and doubles as a canary: if alerts still stop arriving after this fires, that points at the
  /// process/isolate itself having been killed (an OEM battery manager overriding the Android 14
  /// "dismiss doesn't stop the service" guarantee — common on non-stock skins), not just a
  /// missing notification. **No explicit battery-optimization/OEM-whitelist request is made** —
  /// documented known limitation, see this package's `API_REFERENCE.md`.
  @override
  void onNotificationDismissed() {
    FlutterForegroundTask.updateService(
      notificationTitle: 'VizenLink is monitoring your cameras',
      notificationText: 'Listening for camera alerts…',
    );
  }
}
