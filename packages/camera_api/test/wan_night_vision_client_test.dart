import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

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
  test('getNightVisionType parses the same fields as the LAN client', () async {
    final transport = _FakeTransport((_) async => {
      'status': 'ok',
      'output': {'type': 'Color', 'color_capable': true, 'smart_capable': false},
    });
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanNightVisionClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.getNightVisionType();

    expect(transport.captured!['command'], IotCommandClient.getNightVisionType);

    switch (result) {
      case CameraSuccess(:final value):
        expect(value.type, NightVisionType.color);
        expect(value.colorCapable, true);
        expect(value.smartCapable, false);
      default:
        fail('Expected CameraSuccess, got $result');
    }
  });

  test('getNightVisionType parses sub_state when type is Smart', () async {
    final transport = _FakeTransport((_) async => {
      'status': 'ok',
      'output': {
        'type': 'Smart',
        'sub_state': 'Grey',
        'color_capable': true,
        'smart_capable': true,
      },
    });
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanNightVisionClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.getNightVisionType();

    switch (result) {
      case CameraSuccess(:final value):
        expect(value.type, NightVisionType.smart);
        expect(value.subState, NightVisionType.grey);
      default:
        fail('Expected CameraSuccess, got $result');
    }
  });

  test(
    'setNightVisionType sends the wire type and reports success once the camera replies',
    () async {
      final transport = _FakeTransport((_) async => {'status': 'ok', 'output': <String, dynamic>{}});
      final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

      final client = WanNightVisionClient('VZL-CAM-000001', iotCommandClient: iot);
      final result = await client.setNightVisionType(NightVisionType.color);

      expect(transport.captured!['command'], IotCommandClient.setNightVisionType);
      expect(transport.captured!['params'], {'type': 'Color'});
      expect(result, isA<CameraSuccess<void>>());
    },
  );

  test('a camera timeout (no reply, even after the one-shot retry) surfaces as CameraFailure, not a thrown exception', () async {
    final transport = _FakeTransport((_) async => null);
    final iot = IotCommandClient('VZL-CAM-000001', transport: transport);

    final client = WanNightVisionClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.getNightVisionType();

    expect(result, isA<CameraFailure<NightVisionStatus>>());
  });
}
