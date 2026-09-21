import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('getLiveStreamUri parses a webrtc-transport response', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/live-stream-uri': (request) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'profile_token': 'Profile_2'});
          return jsonOk({
            'transport': 'webrtc',
            'port': 8444,
            'path': '/webrtc',
            'url': 'http://192.168.1.50:8444/webrtc',
          });
        },
      })),
    );
    final client = LiveStreamUriClient(nuraeye);

    final result = await client.getLiveStreamUri('Profile_2');

    expect(result, isA<CameraSuccess<LiveStreamTarget>>());
    final target = (result as CameraSuccess<LiveStreamTarget>).value;
    expect(target.transport, LiveStreamTransport.webrtc);
    expect(target.port, 8444);
    expect(target.mediaUri.toString(), 'http://192.168.1.50:8444/webrtc');
  });

  test('getLiveStreamUri parses an rtsp-transport response', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/live-stream-uri': (request) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'profile_token': 'Profile_3'});
          return jsonOk({
            'transport': 'rtsp',
            'port': 556,
            'path': '/mobile',
            'url': 'rtsps://192.168.1.50:556/mobile',
          });
        },
      })),
    );
    final client = LiveStreamUriClient(nuraeye);

    final result = await client.getLiveStreamUri('Profile_3');

    expect(result, isA<CameraSuccess<LiveStreamTarget>>());
    final target = (result as CameraSuccess<LiveStreamTarget>).value;
    expect(target.transport, LiveStreamTransport.rtsp);
    expect(target.port, 556);
    expect(target.mediaUri.toString(), 'rtsps://192.168.1.50:556/mobile');
  });

  test('getLiveStreamUri surfaces a CameraFailure for an unknown profile_token (HTTP 400)', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/live-stream-uri': (request) => jsonError(400, 'unknown profile_token'),
      })),
    );
    final client = LiveStreamUriClient(nuraeye);

    final result = await client.getLiveStreamUri('Profile_99');

    expect(result, isA<CameraFailure<LiveStreamTarget>>());
  });

  test('getLiveStreamUri surfaces a CameraFailure for a 501 (WebRTC not built in) response', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/live-stream-uri': (request) => jsonError(501, 'WebRTC streaming not supported in this build'),
      })),
    );
    final client = LiveStreamUriClient(nuraeye);

    final result = await client.getLiveStreamUri('Profile_1');

    expect(result, isA<CameraFailure<LiveStreamTarget>>());
  });

  test(
    'getLiveStreamUri surfaces a CameraFailure on a 404 (no legacy GetWebRtcUri fallback anymore)',
    () async {
      final nuraeye = NuraeyeClient(
        const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
        // No '/nuraeye/live-stream-uri' route registered -> routeByPath's own default 404.
        httpClient: mockNuraeyeRest(routeByPath({})),
      );
      final client = LiveStreamUriClient(nuraeye);

      final result = await client.getLiveStreamUri('Profile_2');

      expect(result, isA<CameraFailure<LiveStreamTarget>>());
    },
  );
}
