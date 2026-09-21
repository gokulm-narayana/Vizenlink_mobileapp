import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'aws_sigv4.dart';
import 'wan_auth.dart';

/// Plain `print()` (not `dart:developer`'s `log()`, and not `debugPrint` since `camera_api` has
/// no `package:flutter` dependency by design) — **`dart:developer.log()` was tried first and
/// found to be silent in a normal installed run** (it only surfaces when a debugger/VM service
/// is attached, e.g. `flutter run` from a dev machine — not a real device's own logcat), which
/// made a real hardware test of this logging come back with zero output despite the transport
/// demonstrably running (confirmed independently via AWS IoT's own CloudWatch connection logs).
/// `print()` reliably reaches `adb logcat` under the "flutter" tag the same way this app's
/// existing `debugPrint()` calls (`[LiveView]` etc.) already do.
void _log(String message) => print('[IotMqttTransport] $message');

/// Seam `IotCommandClient` talks through instead of `IotMqttTransport` directly, so tests can
/// substitute a fake with no real network/MQTT broker involved.
abstract class IotTransport {
  /// Fire-and-forget publish — no reply expected (`StartCloudStreaming`/`StopCloudStreaming`'s
  /// older command shape, predates the request/response pattern).
  Future<void> publish(String thingName, Map<String, dynamic> body);

  /// Publish [body] (which must include a `request_id`) to `vizenlink/command/<thingName>` and
  /// wait up to [timeout] for a reply carrying the same `request_id` on
  /// `vizenlink/response/<thingName>`. Returns `null` on timeout (no reply arrived) — same
  /// contract the Lambda relay this replaces used to have.
  Future<Map<String, dynamic>?> publishAndWait(
    String thingName,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 12),
  });
}

/// Direct MQTT-over-WSS connection to AWS IoT Core for the command/response channel — replaces
/// the `cloud_backend/kvs_playback_lambda` relay `IotCommandClient` used until 2026-08-18.
///
/// **Why this exists (again)**: the relay was introduced 2026-07-31
/// (`kb/raw/2026-07-31-fix-iot-command-lambda-relay.md`) after real-device testing found AWS
/// rejecting this app's Cognito Identity Pool-federated credentials for direct `iot-data:Publish`
/// and MQTT-over-WSS with `ForbiddenException`, regardless of IAM policy. Re-tested live
/// 2026-08-18 (`kb/raw/2026-08-18-fix-direct-iot-mqtt-restored.md`) after a latency report (the
/// relay's `_publish_and_wait()` costs up to ~12s per command — a brand new MQTT connection on
/// every single invocation) — the restriction no longer reproduces: a real per-user Cognito
/// session can publish and subscribe directly today, confirmed with a real `GetVideoMode` round
/// trip completing in 0.43s. Root cause of the original restriction was never conclusively
/// isolated (IAM-policy-propagation delay vs. a since-lifted AWS-side restriction are both
/// plausible, see that note), so this remains something to re-verify if it ever regresses — but
/// there's no reason to keep paying the relay's latency cost once direct access works.
///
/// **One persistent connection, reused across every `IotCommandClient` instance/thingName** —
/// not per-call like the old relay or `testing_utilities/day_night_mode_test.py`'s test harness.
/// A fresh connect+subscribe on every command is exactly the overhead this change removes;
/// staying connected (self-healing on drop/credential expiry, same pattern as `alerts_api`'s
/// `CameraAlertsTaskHandler`) is what gets a warm connection down to sub-second round trips.
class IotMqttTransport implements IotTransport {
  IotMqttTransport._();

  static final IotMqttTransport instance = IotMqttTransport._();

  MqttServerClient? _client;
  final Set<String> _subscribedTopics = {};
  final Map<String, Completer<void>> _subscribing = {};
  final Map<String, Map<int, String>> _chunkBuffers = {};
  final Map<String, Map<String, dynamic>> _chunkExtraFields = {};
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  Future<MqttServerClient>? _connectFuture;

  Future<MqttServerClient> _ensureConnected() {
    final existing = _client;
    if (existing != null && existing.connectionStatus?.state == MqttConnectionState.connected) {
      return Future.value(existing);
    }
    return _connectFuture ??= _connect().whenComplete(() => _connectFuture = null);
  }

  Future<MqttServerClient> _connect() async {
    _log('connecting...');
    final credsProvider = WanAuth.awsCredentialsProvider;
    final endpoint = WanAuth.awsIotEndpoint;
    final region = WanAuth.awsRegion;
    if (credsProvider == null || endpoint == null || region == null) {
      _log('connect FAILED: WanAuth.awsCredentialsProvider/awsIotEndpoint/awsRegion not set');
      throw StateError(
        'IotMqttTransport used before WanAuth.awsCredentialsProvider/awsIotEndpoint/awsRegion set',
      );
    }
    final creds = await credsProvider();
    if (creds == null) {
      _log('connect FAILED: unauthenticated (awsCredentialsProvider returned null)');
      throw StateError('IotMqttTransport used while unauthenticated');
    }

    final url = AwsSigV4.presignWebSocketUrl(credentials: creds, endpoint: endpoint, region: region);
    final clientId = 'vizenlink-cmd-${DateTime.now().microsecondsSinceEpoch}';
    _log('connecting as $clientId to $endpoint');
    final client = MqttServerClient(url.toString(), clientId)
      ..useWebSocket = true
      ..port = 443
      ..websocketProtocols = MqttClientConstants.protocolsSingleDefault
      ..keepAlivePeriod = 30
      // Deliberately not the library's own autoReconnect — same reasoning as
      // CameraAlertsTaskHandler: the presigned WS URL is SigV4-signed against credentials active
      // at connect time, so it goes stale exactly when those credentials expire. Reconnects are
      // instead driven by _ensureConnected() re-signing a fresh URL from whatever
      // WanAuth.awsCredentialsProvider currently returns, on the next call after a drop.
      ..autoReconnect = false
      ..logging(on: false);
    client.connectionMessage = MqttConnectMessage().withClientIdentifier(clientId).startClean();
    client.onDisconnected = () {
      _log('disconnected (clientId=$clientId)');
      if (identical(_client, client)) {
        _client = null;
        _subscribedTopics.clear();
        for (final pending in _subscribing.values) {
          if (!pending.isCompleted) {
            pending.completeError(StateError('AWS IoT connection dropped while subscribing'));
          }
        }
        _subscribing.clear();
      }
    };
    // Real cause of "camera applied it but the app still showed a timeout": `client.subscribe()`
    // below only *queues* the SUBSCRIBE packet — it does not wait for the broker's SUBACK. With
    // the old Lambda relay, the relay's own per-invocation overhead (fresh TLS/WSS handshake,
    // Lambda cold path) gave AWS IoT Core's subscription plenty of time to actually take effect
    // before the wait loop started. This transport's whole point is a *warm*, persistent
    // connection with sub-second round trips (0.43s measured) — fast enough that a command
    // published right after `subscribe()` can reach the camera and get a reply *before* the
    // broker has finished propagating the subscription, so that reply is silently dropped
    // (never delivered to a subscription that wasn't actually active yet). `onSubscribed`/
    // `onSubscribeFail` fire once the broker actually confirms — `_ensureSubscribed` below now
    // waits for one of those before returning, closing the race.
    client.onSubscribed = (topic) {
      _log('subscribe OK: $topic');
      _subscribing.remove(topic)?.complete();
    };
    client.onSubscribeFail = (topic) {
      _log('subscribe FAILED: $topic');
      _subscribing.remove(topic)?.completeError(StateError('AWS IoT subscribe to $topic failed'));
    };

    try {
      await client.connect();
    } catch (e) {
      _log('connect FAILED: $e');
      rethrow;
    }
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      _log('connect FAILED: status=${client.connectionStatus}');
      throw StateError('AWS IoT MQTT connect failed: ${client.connectionStatus}');
    }
    _log('connected (clientId=$clientId)');
    client.updates?.listen(_onMessages);
    _client = client;
    _subscribedTopics.clear();
    return client;
  }

  Future<void> _ensureSubscribed(MqttServerClient client, String topic) async {
    if (_subscribedTopics.contains(topic)) return;
    // A concurrent call for the same topic reuses this call's in-flight completer instead of
    // issuing a second SUBSCRIBE — `putIfAbsent` only calls `client.subscribe()` the first time.
    final alreadySubscribing = _subscribing.containsKey(topic);
    final completer = _subscribing.putIfAbsent(topic, () => Completer<void>());
    if (!alreadySubscribing) {
      _log('subscribing: $topic');
      client.subscribe(topic, MqttQos.atLeastOnce);
    }
    try {
      await completer.future.timeout(const Duration(seconds: 10));
      _subscribedTopics.add(topic);
    } on TimeoutException {
      _log('subscribe TIMED OUT waiting for SUBACK: $topic');
      rethrow;
    } finally {
      _subscribing.remove(topic);
    }
  }

  /// Reassembles a chunked reply (`FR-NE-108`, e.g. `GetPreviewSnapshot`'s encrypted image,
  /// which doesn't fit AWS IoT Core's ~128KB message cap in one publish) — port of the Lambda's
  /// `_accumulate_reply()`. A reply with no `chunk_index` field (every other command) is handled
  /// as before, one message, no accumulation. Returns the assembled reply once every chunk has
  /// arrived, or `null` if more are still expected.
  Map<String, dynamic>? _accumulateReply(String requestId, Map<String, dynamic> data) {
    if (!data.containsKey('chunk_index') || !data.containsKey('total_chunks')) {
      return data;
    }
    final chunks = _chunkBuffers.putIfAbsent(requestId, () => {});
    final extraFields = _chunkExtraFields.putIfAbsent(requestId, () => {});
    chunks[(data['chunk_index'] as num).toInt()] = data['data'] as String? ?? '';
    for (final entry in data.entries) {
      if (!{'request_id', 'chunk_index', 'total_chunks', 'data'}.contains(entry.key)) {
        extraFields.putIfAbsent(entry.key, () => entry.value);
      }
    }
    final totalChunks = (data['total_chunks'] as num).toInt();
    if (chunks.length != totalChunks) return null;

    final reassembled = List.generate(totalChunks, (i) => chunks[i] ?? '').join();
    _chunkBuffers.remove(requestId);
    _chunkExtraFields.remove(requestId);
    return {
      'request_id': requestId,
      'status': 'ok',
      'output': {...extraFields, 'data': reassembled},
    };
  }

  void _onMessages(List<MqttReceivedMessage<MqttMessage?>> events) {
    for (final event in events) {
      final message = event.payload;
      if (message is! MqttPublishMessage) continue;
      final payloadStr = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(payloadStr) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final requestId = decoded['request_id'] as String?;
      if (requestId == null) continue;
      if (!_pending.containsKey(requestId)) {
        _log('message on ${event.topic} for request_id=$requestId — no matching waiter (late/duplicate reply?)');
        continue;
      }

      final reply = _accumulateReply(requestId, decoded);
      if (reply == null) continue; // more chunks still expected
      _log('reply matched: request_id=$requestId');
      _pending.remove(requestId)?.complete(reply);
    }
  }

  @override
  Future<void> publish(String thingName, Map<String, dynamic> body) async {
    final client = await _ensureConnected();
    _log('publish (fire-and-forget): command=${body['command']} thingName=$thingName');
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(body));
    client.publishMessage('vizenlink/command/$thingName', MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  Future<Map<String, dynamic>?> publishAndWait(
    String thingName,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final requestId = body['request_id'] as String;
    final client = await _ensureConnected();
    await _ensureSubscribed(client, 'vizenlink/response/$thingName');

    final completer = Completer<Map<String, dynamic>>();
    _pending[requestId] = completer;

    try {
      final builder = MqttClientPayloadBuilder()..addString(jsonEncode(body));
      _log('publish: command=${body['command']} thingName=$thingName request_id=$requestId '
          '(waiting up to ${timeout.inMilliseconds}ms)');
      client.publishMessage('vizenlink/command/$thingName', MqttQos.atLeastOnce, builder.payload!);
      final reply = await completer.future.timeout(timeout);
      return reply;
    } on TimeoutException {
      _log('TIMED OUT waiting for reply: request_id=$requestId '
          '(connectionStatus=${client.connectionStatus?.state})');
      return null;
    } finally {
      _pending.remove(requestId);
      _chunkBuffers.remove(requestId);
      _chunkExtraFields.remove(requestId);
    }
  }
}
