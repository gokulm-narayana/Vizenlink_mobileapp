import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// `AwsWanLiveViewClient` had no dedicated test file before 2026-08-14 — every existing test
// (`live_view_controller_test.dart`) exercised it only through a hand-written `_FakeWanClient`
// implementing the `WanLiveViewClient` interface, which never actually ran this class's real
// logic. That gap is exactly why `getCloudStreamingStatus()` was missing the `try`/`catch` its
// three sibling methods all had, since a real device's transient network failure had never once
// been simulated against the real class. `startCloudStreaming`/`stopCloudStreaming` (matching
// their two sibling shape) are trusted by the same pattern already proven for those siblings —
// this file focuses on `getCloudStreamingStatus`, the one that was actually broken.

http.Client _iotMock(Future<http.Response> Function(http.Request) handler) => MockClient(handler);

IotCommandClient _iotClient(Future<http.Response> Function(http.Request) handler) =>
    IotCommandClient('VZL-CAM-000001', idTokenProvider: () => 'fake-id-token', httpClient: _iotMock(handler));

void main() {
  test(
    'getCloudStreamingStatus returns CameraFailure, not an uncaught exception, when the relay '
    'call throws (regression: real-device SocketException crashed past every caller\'s '
    'CameraResult switch, 2026-08-14)',
    () async {
      final iot = _iotClient((request) async => http.Response('{"error":"Network is unreachable"}', 504));
      final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

      final result = await client.getCloudStreamingStatus();

      expect(result, isA<CameraFailure<StreamStatus>>());
      expect((result as CameraFailure<StreamStatus>).reason, contains('Network is unreachable'));
    },
  );

  test('getCloudStreamingStatus parses an active status on the first attempt, no retry', () async {
    var callCount = 0;
    final iot = _iotClient((request) async {
      callCount++;
      return http.Response(
        jsonEncode({'output': {'stream_status': 'active'}}),
        200,
      );
    });
    final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

    final result = await client.getCloudStreamingStatus();

    expect(result, isA<CameraSuccess<StreamStatus>>());
    expect((result as CameraSuccess<StreamStatus>).value, StreamStatus.active);
    expect(callCount, 1);
  });

  test(
    'getCloudStreamingStatus retries on idle up to 3 attempts before giving up',
    () async {
      var callCount = 0;
      final iot = _iotClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({'output': {'stream_status': 'idle'}}),
          200,
        );
      });
      final client = AwsWanLiveViewClient(
        'VZL-CAM-000001',
        iotCommandClient: iot,
      );

      final result = await client.getCloudStreamingStatus();

      expect(result, isA<CameraSuccess<StreamStatus>>());
      expect((result as CameraSuccess<StreamStatus>).value, StreamStatus.idle);
      expect(callCount, 3);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  test('getCloudStreamingStatus returns CameraFailure for an unrecognized stream_status value', () async {
    final iot = _iotClient(
      (request) async => http.Response(
        jsonEncode({'output': {'stream_status': 'something_new'}}),
        200,
      ),
    );
    final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

    final result = await client.getCloudStreamingStatus();

    expect(result, isA<CameraFailure<StreamStatus>>());
  });

  test('getCloudStreamingStatus returns CameraTimeout when the relay reports no output', () async {
    final iot = _iotClient(
      (request) async => http.Response(jsonEncode({'output': null}), 200),
    );
    final client = AwsWanLiveViewClient('VZL-CAM-000001', iotCommandClient: iot);

    final result = await client.getCloudStreamingStatus();

    expect(result, isA<CameraTimeout<StreamStatus>>());
  });
}
