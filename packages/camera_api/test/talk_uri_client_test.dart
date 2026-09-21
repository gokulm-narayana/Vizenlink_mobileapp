import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('getTalkUri parses a well-formed rtsps-transport response', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/talk-uri': (request) {
          expect(request.body.trim(), anyOf('', '{}'));
          return jsonOk({
            'transport': 'rtsps',
            'port': 560,
            'path': '/talk',
            'url': 'rtsps://192.168.1.50:560/talk',
          });
        },
      })),
    );
    final client = TalkUriClient(nuraeye);

    final result = await client.getTalkUri();

    expect(result, isA<CameraSuccess<TalkTarget>>());
    final target = (result as CameraSuccess<TalkTarget>).value;
    expect(target.port, 560);
    expect(target.mediaUri.toString(), 'rtsps://192.168.1.50:560/talk');
  });

  test('getTalkUri surfaces a CameraFailure when the build lacks AUDIO_ENABLED (HTTP 400)', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/talk-uri': (request) => jsonError(400, 'Two-way talk unavailable on this build'),
      })),
    );
    final client = TalkUriClient(nuraeye);

    final result = await client.getTalkUri();

    expect(result, isA<CameraFailure<TalkTarget>>());
  });

  test('getTalkUri rejects an unexpected transport value', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/talk-uri': (request) => jsonOk({
              'transport': 'webrtc',
              'port': 560,
              'path': '/talk',
              'url': 'rtsps://192.168.1.50:560/talk',
            }),
      })),
    );
    final client = TalkUriClient(nuraeye);

    final result = await client.getTalkUri();

    expect(result, isA<CameraFailure<TalkTarget>>());
  });
}
