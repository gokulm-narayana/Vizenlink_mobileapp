import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// `FR-NE-078`'s WAN mirror (`SetAudioRecording`/`GetAudioRecording`, commands 17/18) was
// hardware-verified in firmware since 2026-07-28 but never wired into `WanAudioVolumeClient`
// until 2026-08-11 — see that class's doc comment for the full history. Mirrors
// `wan_night_vision_client_test.dart`'s shape.
void main() {
  test(
    'isAudioRecordingEnabled parses enabled from GetAudioRecording',
    () async {
      http.Request? captured;
      final iot = IotCommandClient(
        'VZL-CAM-000001',
        idTokenProvider: () => 'fake-id-token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"output":{"enabled":true}}', 200);
        }),
      );

      final client = WanAudioVolumeClient(
        'VZL-CAM-000001',
        iotCommandClient: iot,
      );
      final result = await client.isAudioRecordingEnabled();

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['action'], 'commandWithResponse');
      expect(body['command'], IotCommandClient.getAudioRecording);

      switch (result) {
        case CameraSuccess(:final value):
          expect(value, true);
        default:
          fail('Expected CameraSuccess, got $result');
      }
    },
  );

  test(
    'setAudioRecordingEnabled sends the enabled flag and reports success once the camera replies',
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

      final client = WanAudioVolumeClient(
        'VZL-CAM-000001',
        iotCommandClient: iot,
      );
      final result = await client.setAudioRecordingEnabled(false);

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['command'], IotCommandClient.setAudioRecording);
      expect(body['params'], {'enabled': false});
      expect(result, isA<CameraSuccess<void>>());
    },
  );

  test(
    'a Lambda-reported camera timeout surfaces as CameraFailure, not a thrown exception',
    () async {
      final iot = IotCommandClient(
        'VZL-CAM-000001',
        idTokenProvider: () => 'fake-id-token',
        httpClient: MockClient(
          (request) async => http.Response(
            '{"error":"No response from camera (timed out)"}',
            504,
          ),
        ),
      );

      final client = WanAudioVolumeClient(
        'VZL-CAM-000001',
        iotCommandClient: iot,
      );
      final result = await client.isAudioRecordingEnabled();

      expect(result, isA<CameraFailure<bool>>());
    },
  );
}
