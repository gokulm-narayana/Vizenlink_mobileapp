import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

// `FR-NE-078`'s WAN mirror (`SetAudioRecording`/`GetAudioRecording`, commands 17/18) was
// hardware-verified in firmware since 2026-07-28 but never wired into `WanAudioVolumeClient`
// until 2026-08-11 — see that class's doc comment for the full history. Mirrors
// `wan_night_vision_client_test.dart`'s shape.
class _FakeTransport implements IotTransport {
  _FakeTransport(this.publishAndWaitImpl);

  final Future<Map<String, dynamic>?> Function(Map<String, dynamic> body) publishAndWaitImpl;
  Map<String, dynamic>? captured;

  @override
  Future<void> publish(String thingName, Map<String, dynamic> body) async {}

  @override
  Future<Map<String, dynamic>?> publishAndWait(
    String thingName,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    captured = body;
    return publishAndWaitImpl(body);
  }
}

void main() {
  test('isAudioRecordingEnabled parses enabled from GetAudioRecording', () async {
    final transport = _FakeTransport((_) async => {
      'status': 'ok',
      'output': {'enabled': true},
    });
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanAudioVolumeClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.isAudioRecordingEnabled();

    expect(transport.captured!['command'], IotCommandClient.getAudioRecording);

    switch (result) {
      case CameraSuccess(:final value):
        expect(value, true);
      default:
        fail('Expected CameraSuccess, got $result');
    }
  });

  test(
    'setAudioRecordingEnabled sends the enabled flag and reports success once the camera replies',
    () async {
      final transport = _FakeTransport((_) async => {'status': 'ok', 'output': <String, dynamic>{}});
      final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

      final client = WanAudioVolumeClient('VZL-CAM-000001', iotCommandClient: iot);
      final result = await client.setAudioRecordingEnabled(false);

      expect(transport.captured!['command'], IotCommandClient.setAudioRecording);
      expect(transport.captured!['params'], {'enabled': false});
      expect(result, isA<CameraSuccess<void>>());
    },
  );

  test('a camera timeout (no reply, even after the one-shot retry) surfaces as CameraFailure, not a thrown exception', () async {
    final transport = _FakeTransport((_) async => null);
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanAudioVolumeClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.isAudioRecordingEnabled();

    expect(result, isA<CameraFailure<bool>>());
  });
}
