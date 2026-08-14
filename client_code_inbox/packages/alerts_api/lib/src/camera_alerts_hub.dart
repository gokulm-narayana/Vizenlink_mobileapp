import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'alerts_api_config.dart';
import 'camera_alerts_task_handler.dart';

/// One alert relayed up from `CameraAlertsTaskHandler`'s background isolate.
class CameraAlertEvent {
  const CameraAlertEvent({
    required this.thingName,
    required this.event,
    required this.body,
  });

  final String thingName;

  /// e.g. `"VideoModeChanged"` — matches the camera's alert JSON `event` field exactly.
  final String event;

  final Map<String, dynamic> body;
}

/// App-wide hooks this package falls back to when [ensureRunning] is called with no per-call
/// override — mirrors `camera_api`'s `WanAuth` pattern exactly. **Set these once, at app
/// startup, before the first [CameraAlertsHub.ensureRunning] call.**
///
/// This package never reads a dart-define or an app-specific camera-list store directly — every
/// value it needs is supplied through these hooks, so it stays reusable independent of any one
/// app's auth/onboarding implementation.
class AlertsAuth {
  AlertsAuth._();

  static AlertsApiConfig? config;

  /// Returns the cameras that should currently be watched. Called on every [ensureRunning].
  static Future<List<WatchedCamera>> Function()? cameraListProvider;

  /// Returns fresh AWS credentials to sign the MQTT connection with, or throws/returns via
  /// exception if unavailable (e.g. unauthenticated) — [ensureRunning] treats a thrown exception
  /// as "nothing to sync yet" and returns silently, matching every other best-effort method on
  /// this class.
  static Future<AlertsCredentials> Function()? credentialsProvider;
}

/// Main-isolate half of the always-on WAN alert listener — owns the foreground service
/// lifecycle. Any screen that wants live camera-alert state listens to [events] and filters by
/// `thingName`, instead of opening its own WAN MQTT connection. [statusUpdates] additionally
/// exposes connectivity health (added 2026-08-12 — previously collected internally but never
/// surfaced to the UI).
class CameraAlertsHub {
  CameraAlertsHub._();
  static final CameraAlertsHub instance = CameraAlertsHub._();

  final _eventsController = StreamController<CameraAlertEvent>.broadcast();
  Stream<CameraAlertEvent> get events => _eventsController.stream;

  final _statusController = StreamController<AlertsStatus>.broadcast();

  /// Broadcasts whenever the set of currently-connected cameras changes — e.g. to show "alerts
  /// unavailable/reconnecting" in the UI. Emits synchronously-available cached data has no
  /// initial value; subscribe before or after [ensureRunning] as needed, same as [events].
  Stream<AlertsStatus> get statusUpdates => _statusController.stream;

  AlertsStatus? _lastStatus;

  /// The most recently reported connectivity snapshot, or `null` if none has arrived yet.
  AlertsStatus? get lastStatus => _lastStatus;

  bool _initialized = false;
  Timer? _refreshTimer;

  void _init() {
    if (_initialized || !Platform.isAndroid) return;
    _initialized = true;

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'camera_alerts_service',
        channelName: 'Camera Alerts Service',
        channelDescription:
            'Keeps a live connection to your VizenLink cameras for instant alerts.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  void _onTaskData(Object data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    switch (map['type']) {
      case 'alert':
        _onAlert(map);
      case 'status':
        _onStatus(map);
    }
  }

  void _onAlert(Map<String, dynamic> map) {
    final thingName = map['thingName'];
    final event = map['event'];
    final body = map['body'];
    if (thingName is String && event is String && body is Map) {
      final decodedBody = Map<String, dynamic>.from(body);
      _eventsController.add(CameraAlertEvent(
        thingName: thingName,
        event: event,
        body: decodedBody,
      ));
      onAlertPersist?.call(thingName, event, decodedBody);
    }
  }

  void _onStatus(Map<String, dynamic> map) {
    final connected = (map['connected'] as List?)?.cast<String>().toSet() ?? const {};
    final watched = (map['watched'] as List?)?.cast<String>().toSet() ?? const {};
    final status = AlertsStatus(connectedThingNames: connected, watchedThingNames: watched);
    _lastStatus = status;
    _statusController.add(status);
  }

  /// Optional hook called on every received alert, before broadcasting on [events] — for an app
  /// that wants to persist alert history without needing its own separate subscription. Not a
  /// static [AlertsAuth] hook (unlike config/credentials) since it's instance-scoped state, not
  /// startup wiring — set it directly on [instance] if needed.
  void Function(String thingName, String event, Map<String, dynamic> body)? onAlertPersist;

  /// Starts (or updates) the background alert listener for every camera [AlertsAuth
  /// .cameraListProvider] currently returns, and pushes fresh credentials down to it via
  /// [AlertsAuth.credentialsProvider]. Call after login, on app resume, and periodically while
  /// signed in. Best-effort and silent: never throws, since this must never block a screen or
  /// login flow — a failure here just means live alerts stay unavailable until the next call
  /// succeeds.
  Future<void> ensureRunning() async {
    if (!Platform.isAndroid) return; // iOS foreground-service model differs; not built yet.
    final config = AlertsAuth.config;
    final cameraListProvider = AlertsAuth.cameraListProvider;
    final credentialsProvider = AlertsAuth.credentialsProvider;
    if (config == null || cameraListProvider == null || credentialsProvider == null) return;

    _init();

    final cameras = await cameraListProvider();
    if (cameras.isEmpty) {
      await stop();
      return;
    }

    final AlertsCredentials creds;
    try {
      creds = await credentialsProvider();
    } catch (_) {
      return; // Unauthenticated or credential fetch failed — nothing to sync yet.
    }

    try {
      final permission = await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      if (!await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.startService(
          serviceId: 257,
          serviceTypes: const [ForegroundServiceTypes.dataSync],
          notificationTitle: 'VizenLink is monitoring your cameras',
          notificationText: 'Listening for camera alerts…',
          callback: cameraAlertsStartCallback,
        );
      }

      FlutterForegroundTask.sendDataToTask({
        'action': 'sync',
        'region': config.region,
        'iotEndpoint': config.iotEndpoint,
        'credentials': {
          'accessKeyId': creds.accessKeyId,
          'secretKey': creds.secretKey,
          'sessionToken': creds.sessionToken,
          'expiresAtMs': creds.expiresAt.millisecondsSinceEpoch,
        },
        'cameras': [
          for (final c in cameras) {'thingName': c.thingName},
        ],
      });
    } catch (_) {
      // Best-effort — see doc comment above.
    }

    _refreshTimer ??= Timer.periodic(const Duration(minutes: 20), (_) => ensureRunning());
  }

  /// Stops the service entirely — call on logout, since the background isolate otherwise has
  /// no way to know the user signed out and would keep retrying with a now-invalid session.
  Future<void> stop() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _lastStatus = null;
    if (Platform.isAndroid && await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
