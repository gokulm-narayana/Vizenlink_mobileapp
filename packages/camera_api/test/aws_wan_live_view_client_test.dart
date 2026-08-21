import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

// `AwsWanLiveViewClient` had no dedicated test file before 2026-08-14 — every existing test
// (`live_view_controller_test.dart`) exercised it only through a hand-written `_FakeWanClient`
// implementing the `WanLiveViewClient` interface, which never actually ran this class's real
// logic. That gap is exactly why `getCloudStreamingStatus()` was missing the `try`/`catch` its
// three sibling methods all had, since a real device's transient network failure had never once
// been simulated against the real class. `startCloudStreaming`/`stopCloudStreaming` (matching
// their two sibling shape) are trusted by the same pattern already proven for those siblings —
// this file focuses on `getCloudStreamingStatus`, the one that was actually broken.

/// Fake [IotTransport] — [publishAndWaitImpl] lets each test script the reply (or throw, to
/// simulate a transport-level failure like the real-device `SocketException` this file's first
/// test regresses against).
class _FakeTransport implements IotTransport {
  _FakeTransport(this.publishAndWaitImpl);

  final Future<Map<String, dynamic>?> Function(int callCount) publishAndWaitImpl;
  int callCount = 0;

  @override
  Future<void> publish(String thingName, Map<String, dynamic> body) async {}

  @override
  Future<Map<String, dynamic>?> publishAndWait(
    String thingName,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    callCount++;
    return publishAndWaitImpl(callCount);
  }
}

void main() {
  test(
    'getCloudStreamingStatus returns CameraFailure, not an uncaught exception, when the relay '
    'call throws (regression: real-device SocketException crashed past every caller\'s '
    'CameraResult switch, 2026-08-14)',
    () async {
      final transport = _FakeTransport((_) async => throw Exception('Network is unreachable'));
      final iot = IotCommandClient('VZL-CAM-000001', transport: transport);
      final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

      final result = await client.getCloudStreamingStatus();

      expect(result, isA<CameraFailure<StreamStatus>>());
      expect((result as CameraFailure<StreamStatus>).reason, contains('Network is unreachable'));
    },
  );

  test('getCloudStreamingStatus parses an active status on the first attempt, no retry', () async {
    final transport = _FakeTransport((_) async => {
      'status': 'ok',
      'output': {'stream_status': 'active'},
    });
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);
    final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

    final result = await client.getCloudStreamingStatus();

    expect(result, isA<CameraSuccess<StreamStatus>>());
    expect((result as CameraSuccess<StreamStatus>).value, StreamStatus.active);
    expect(transport.callCount, 1);
  });

  test(
    'getCloudStreamingStatus retries on idle up to 3 attempts before giving up',
    () async {
      final transport = _FakeTransport((_) async => {
        'status': 'ok',
        'output': {'stream_status': 'idle'},
      });
      final iot = IotCommandClient('VZL-CAM-000001', transport: transport);
      final client = AwsWanLiveViewClient(
        'VZL-CAM-000001',
        iotCommandClient: iot,
      );

      final result = await client.getCloudStreamingStatus();

      expect(result, isA<CameraSuccess<StreamStatus>>());
      expect((result as CameraSuccess<StreamStatus>).value, StreamStatus.idle);
      expect(transport.callCount, 3);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  test('getCloudStreamingStatus returns CameraFailure for an unrecognized stream_status value', () async {
    final transport = _FakeTransport((_) async => {
      'status': 'ok',
      'output': {'stream_status': 'something_new'},
    });
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);
    final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

    final result = await client.getCloudStreamingStatus();

    expect(result, isA<CameraFailure<StreamStatus>>());
  });

  test(
    'getCloudStreamingStatus returns CameraFailure (not an uncaught exception) when no reply '
    'arrives at all',
    () async {
      // No reply at all (not "a reply with no output" — see `iot_command_client_test.dart`'s
      // "a successful reply with no output field..." regression test for why those are
      // different: a Get* command's success reply always carries `output`; only Set*/Delete*
      // omit it, and sendCommandWithResponse() now defaults that to an empty map rather than
      // null). When neither of `IotCommandClient`'s two attempts gets a reply at all, it throws
      // rather than returning null (same as the old Lambda-relay-backed implementation did on a
      // double-504) — the `output == null` branch below is therefore unreachable in practice;
      // this test exercises the real path instead: the thrown exception, caught here and
      // surfaced as CameraFailure.
      final transport = _FakeTransport((_) async => null);
      final iot = IotCommandClient('VZL-CAM-000001', transport: transport);
      final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

      final result = await client.getCloudStreamingStatus();

      expect(result, isA<CameraFailure<StreamStatus>>());
      expect((result as CameraFailure<StreamStatus>).reason, contains('timed out'));
    },
  );
}
