import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

const _connection = CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw');

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('isAudioRecordingEnabled parses {"enabled": true} from GET /nuraeye/audio/recording', () async {
    final client = AudioVolumeClient(
      _connection,
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/audio/recording': (request) {
          expect(request.method, 'GET');
          return jsonOk({'enabled': true});
        },
      })),
    );

    final result = await client.isAudioRecordingEnabled();

    expect(result, isA<CameraSuccess<bool>>());
    expect((result as CameraSuccess<bool>).value, true);
  });

  test('setAudioRecordingEnabled POSTs {"enabled": false} to /nuraeye/audio/recording', () async {
    Map<String, dynamic>? captured;
    final client = AudioVolumeClient(
      _connection,
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/audio/recording': (request) {
          captured = {'method': request.method, 'body': request.body};
          return jsonOk(const {});
        },
      })),
    );

    final result = await client.setAudioRecordingEnabled(false);

    expect(result, isA<CameraSuccess<void>>());
    expect(captured!['method'], 'POST');
    expect(captured!['body'], '{"enabled":false}');
  });
}
