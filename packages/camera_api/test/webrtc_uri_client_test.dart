import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('getWebRtcUri parses port/url from a successful GetWebRtcUri response', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/webrtc-uri': (request) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'profile_token': 'Profile_2'});
          return jsonOk({'port': 8444, 'url': 'http://192.168.1.50:8444/webrtc'});
        },
      })),
    );
    final client = WebRtcUriClient(nuraeye);

    final result = await client.getWebRtcUri('Profile_2');

    expect(result, isA<CameraSuccess<WebRtcTarget>>());
    final target = (result as CameraSuccess<WebRtcTarget>).value;
    expect(target.port, 8444);
    expect(target.signalingUrl.toString(), 'http://192.168.1.50:8444/webrtc');
  });

  test('getWebRtcUri surfaces a CameraFailure for an unknown profile_token (HTTP 400)', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/webrtc-uri': (request) => jsonError(400, 'unknown profile_token'),
      })),
    );
    final client = WebRtcUriClient(nuraeye);

    final result = await client.getWebRtcUri('Profile_99');

    expect(result, isA<CameraFailure<WebRtcTarget>>());
  });
}
