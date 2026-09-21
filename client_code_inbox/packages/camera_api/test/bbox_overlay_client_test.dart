import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

const _connection = CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw');

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('isBboxOverlayEnabled parses {"enabled": true} from GET /nuraeye/events/bbox-overlay', () async {
    final client = BboxOverlayClient(
      NuraeyeClient(
        _connection,
        httpClient: mockNuraeyeRest(routeByPath({
          '/nuraeye/events/bbox-overlay': (request) {
            expect(request.method, 'GET');
            return jsonOk({'enabled': true});
          },
        })),
      ),
    );

    final result = await client.isBboxOverlayEnabled();

    expect(result, isA<CameraSuccess<bool>>());
    expect((result as CameraSuccess<bool>).value, true);
  });

  test('setBboxOverlayEnabled POSTs {"enabled": false} to /nuraeye/events/bbox-overlay', () async {
    Map<String, dynamic>? captured;
    final client = BboxOverlayClient(
      NuraeyeClient(
        _connection,
        httpClient: mockNuraeyeRest(routeByPath({
          '/nuraeye/events/bbox-overlay': (request) {
            captured = {'method': request.method, 'body': request.body};
            return jsonOk(const {});
          },
        })),
      ),
    );

    final result = await client.setBboxOverlayEnabled(false);

    expect(result, isA<CameraSuccess<void>>());
    expect(captured!['method'], 'POST');
    expect(captured!['body'], '{"enabled":false}');
  });

  test('isBboxOverlayEnabled reports CameraFailure when "enabled" is missing from the response', () async {
    final client = BboxOverlayClient(
      NuraeyeClient(
        _connection,
        httpClient: mockNuraeyeRest(routeByPath({
          '/nuraeye/events/bbox-overlay': (request) => jsonOk(const {}),
        })),
      ),
    );

    final result = await client.isBboxOverlayEnabled();

    expect(result, isA<CameraFailure<bool>>());
  });
}
