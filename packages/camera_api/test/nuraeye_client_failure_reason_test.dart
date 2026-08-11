import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test(
    'a rejected request\'s CameraFailure.reason contains the HTTP status code as text '
    '(regression: add_camera_credentials_screen.dart string-matches reason.contains(\'401\') '
    'to show "Incorrect username or password" — the firmware\'s error_msg alone, e.g. '
    '"Invalid credentials", never contains the digits "401")',
    () async {
      final nuraeye = NuraeyeClient(
        const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'wrong'),
        httpClient: mockNuraeyeRest(
          routeByPath({
            '/nuraeye/wifi': (request) => jsonError(401, 'Invalid credentials'),
          }),
        ),
      );

      final result = await nuraeye.call('GetWiFiInfo');

      expect(result, isA<CameraFailure<Map<String, dynamic>>>());
      final reason = (result as CameraFailure<Map<String, dynamic>>).reason;
      expect(reason, contains('401'));
      expect(reason, contains('Invalid credentials'));
    },
  );

  test(
    'a rejected session/login itself (wrong password, digest mismatch) also carries the HTTP '
    'status code as text — real bug found 2026-08-11: entering a wrong password during '
    'add-camera always showed "Could not reach the camera" instead of "Incorrect username or '
    'password", because a login rejection was discarded down to a bare, status-code-less '
    "'NuraEye REST session login failed' string before add_camera_credentials_screen.dart's "
    "reason.contains('401') check ever saw it",
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/nuraeye/session/login') {
          return http.Response(
            jsonEncode({'error_code': 401, 'error_msg': 'digest mismatch', 'output': {}}),
            401,
          );
        }
        return http.Response('{"error_code":404,"error_msg":"not found","output":{}}', 404);
      });

      final nuraeye = NuraeyeClient(
        const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'wrong'),
        httpClient: client,
      );

      final result = await nuraeye.call('GetWiFiInfo');

      expect(result, isA<CameraFailure<Map<String, dynamic>>>());
      final reason = (result as CameraFailure<Map<String, dynamic>>).reason;
      expect(reason, contains('401'));
      expect(reason, contains('digest mismatch'));
    },
  );
}
