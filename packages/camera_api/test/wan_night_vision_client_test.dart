import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('getNightVisionType parses the same fields as the LAN client', () async {
    http.Request? captured;
    final iot = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"output":{"type":"Color","color_capable":true,"smart_capable":false}}',
          200,
        );
      }),
    );

    final client = WanNightVisionClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.getNightVisionType();

    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['action'], 'commandWithResponse');
    expect(body['command'], IotCommandClient.getNightVisionType);

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
    final iot = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient(
        (request) async => http.Response(
          '{"output":{"type":"Smart","sub_state":"Grey","color_capable":true,"smart_capable":true}}',
          200,
        ),
      ),
    );

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
      http.Request? captured;
      final iot = IotCommandClient(
        'VZL-CAM-000001',
        idTokenProvider: () => 'fake-id-token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"output":{}}', 200);
        }),
      );

      final client = WanNightVisionClient('VZL-CAM-000001', iotCommandClient: iot);
      final result = await client.setNightVisionType(NightVisionType.color);

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['command'], IotCommandClient.setNightVisionType);
      expect(body['params'], {'type': 'Color'});
      expect(result, isA<CameraSuccess<void>>());
    },
  );

  test('a Lambda-reported camera timeout surfaces as CameraFailure, not a thrown exception', () async {
    final iot = IotCommandClient(
      'VZL-CAM-000001',
      idTokenProvider: () => 'fake-id-token',
      httpClient: MockClient(
        (request) async => http.Response('{"error":"No response from camera (timed out)"}', 504),
      ),
    );

    final client = WanNightVisionClient('VZL-CAM-000001', iotCommandClient: iot);
    final result = await client.getNightVisionType();

    expect(result, isA<CameraFailure<NightVisionStatus>>());
  });
}
