import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

// FR-NE-123's WAN mirror (GetBboxOverlayEnabled/SetBboxOverlayEnabled, commands 74/73) --
// hardware-verified against the real firmware via testing_utilities/bbox_overlay_test.py
// (BBOX-MQTT-01/02), but that only proves the wire protocol; this exercises the Dart client
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
  test('isBboxOverlayEnabled parses enabled from GetBboxOverlayEnabled', () async {
    final transport = _FakeTransport((_) async => {
      'status': 'ok',
      'output': {'enabled': true},
    });
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanBboxOverlayClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.isBboxOverlayEnabled();

    expect(transport.captured!['command'], IotCommandClient.getBboxOverlayEnabled);

    switch (result) {
      case CameraSuccess(:final value):
        expect(value, true);
      default:
        fail('Expected CameraSuccess, got $result');
    }
  });

  test(
    'setBboxOverlayEnabled sends the enabled flag and reports success once the camera replies',
    () async {
      final transport = _FakeTransport((_) async => {'status': 'ok', 'output': <String, dynamic>{}});
      final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

      final client = WanBboxOverlayClient('VZL-CAM-000001', iotCommandClient: iot);
      final result = await client.setBboxOverlayEnabled(false);

      expect(transport.captured!['command'], IotCommandClient.setBboxOverlayEnabled);
      expect(transport.captured!['params'], {'enabled': false});
      expect(result, isA<CameraSuccess<void>>());
    },
  );

  test('a camera timeout (no reply, even after the one-shot retry) surfaces as CameraFailure, not a thrown exception', () async {
    final transport = _FakeTransport((_) async => null);
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanBboxOverlayClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.isBboxOverlayEnabled();

    expect(result, isA<CameraFailure<bool>>());
  });
}
