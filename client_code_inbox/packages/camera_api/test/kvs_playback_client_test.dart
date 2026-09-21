import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('getPlaybackUrl sends the ID token as a Bearer header and streamName as a query param', () async {
    http.Request? captured;
    final client = KvsPlaybackClient(
      idTokenProvider: () => 'fake-id-token',
      client: MockClient((request) async {
        captured = request;
        return http.Response('{"hlsStreamingSessionUrl":"https://example.com/hls"}', 200);
      }),
    );

    final url = await client.getPlaybackUrl('VZL-CAM-000001');

    expect(url, 'https://example.com/hls');
    expect(captured!.headers['Authorization'], 'Bearer fake-id-token');
    expect(captured!.url.queryParameters['streamName'], 'VZL-CAM-000001');
  });

  test('a 401 response throws with the Lambda\'s error message', () async {
    final client = KvsPlaybackClient(
      idTokenProvider: () => 'fake-id-token',
      client: MockClient(
        (request) async => http.Response('{"error":"Invalid token: expired"}', 401),
      ),
    );

    expect(
      () => client.getPlaybackUrl('VZL-CAM-000001'),
      throwsA(predicate((e) => e.toString().contains('Invalid token: expired'))),
    );
  });

  test('a 403 response (out-of-fleet stream name) throws', () async {
    final client = KvsPlaybackClient(
      idTokenProvider: () => 'fake-id-token',
      client: MockClient(
        (request) async =>
            http.Response('{"error":"streamName outside this fleet\'s naming convention"}', 403),
      ),
    );

    expect(client.getPlaybackUrl('not-a-vizenlink-stream'), throwsException);
  });

  test('throws StateError when unauthenticated (no ID token)', () async {
    final client = KvsPlaybackClient(idTokenProvider: () => null);

    expect(client.getPlaybackUrl('VZL-CAM-000001'), throwsStateError);
  });
}
