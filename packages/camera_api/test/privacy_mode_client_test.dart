import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('getPrivacyMode parses mode', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/privacy-mode': (request) {
          expect(request.method, 'GET');
          return jsonOk({'mode': 'Zone'});
        },
      })),
    );
    final client = PrivacyModeClient(nuraeye);

    final result = await client.getPrivacyMode();

    expect(result, isA<CameraSuccess<PrivacyMode>>());
    expect((result as CameraSuccess<PrivacyMode>).value, PrivacyMode.zone);
  });

  test('setPrivacyMode sends the wire value for Full', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/privacy-mode': (request) {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'mode': 'Full'});
          return jsonOk(const {});
        },
      })),
    );
    final client = PrivacyModeClient(nuraeye);

    final result = await client.setPrivacyMode(PrivacyMode.full);

    expect(result, isA<CameraSuccess<void>>());
  });
}
