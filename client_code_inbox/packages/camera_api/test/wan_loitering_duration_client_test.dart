import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

// FR-NE-121's WAN mirror (GetLoiteringDuration/SetLoiteringDuration, commands 72/71) --
// hardware-verified against the real firmware via testing_utilities/loitering_duration_test.py
// (LDC-MQTT-01/02), but that only proves the wire protocol; this exercises the Dart client
// itself. Mirrors wan_audio_volume_client_test.dart's shape.
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
  test('getLoiteringDuration parses loitering_duration_seconds from GetLoiteringDuration', () async {
    final transport = _FakeTransport((_) async => {
      'status': 'ok',
      'output': {'loitering_duration_seconds': 15},
    });
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanLoiteringDurationClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.getLoiteringDuration();

    expect(transport.captured!['command'], IotCommandClient.getLoiteringDuration);

    switch (result) {
      case CameraSuccess(:final value):
        expect(value, 15);
      default:
        fail('Expected CameraSuccess, got $result');
    }
  });

  test(
    'setLoiteringDuration sends the requested seconds and reports success once the camera replies',
    () async {
      final transport = _FakeTransport((_) async => {'status': 'ok', 'output': <String, dynamic>{}});
      final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

      final client = WanLoiteringDurationClient('VZL-CAM-000001', iotCommandClient: iot);
      final result = await client.setLoiteringDuration(90);

      expect(transport.captured!['command'], IotCommandClient.setLoiteringDuration);
      expect(transport.captured!['params'], {'loitering_duration_seconds': 90});
      expect(result, isA<CameraSuccess<void>>());
    },
  );

  test('a camera timeout (no reply, even after the one-shot retry) surfaces as CameraFailure, not a thrown exception', () async {
    final transport = _FakeTransport((_) async => null);
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanLoiteringDurationClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.getLoiteringDuration();

    expect(result, isA<CameraFailure<int>>());
  });
}
