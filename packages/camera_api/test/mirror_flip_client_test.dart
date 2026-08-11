import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('getMirrorFlip parses mode', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/video/mirror-flip': (request) {
          expect(request.method, 'GET');
          return jsonOk({'mode': 'Both'});
        },
      })),
    );
    final client = MirrorFlipClient(nuraeye);

    final result = await client.getMirrorFlip();

    expect(result, isA<CameraSuccess<MirrorFlipMode>>());
    expect((result as CameraSuccess<MirrorFlipMode>).value, MirrorFlipMode.both);
  });

  test('setMirrorFlip sends the wire value for Mirror', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/video/mirror-flip': (request) {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'mode': 'Mirror'});
          return jsonOk(const {});
        },
      })),
    );
    final client = MirrorFlipClient(nuraeye);

    final result = await client.setMirrorFlip(MirrorFlipMode.mirror);

    expect(result, isA<CameraSuccess<void>>());
  });
}
