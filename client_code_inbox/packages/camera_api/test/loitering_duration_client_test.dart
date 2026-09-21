import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

const _connection = CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw');

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test(
    'getLoiteringDuration parses {"loitering_duration_seconds": 15} from GET /nuraeye/events/loitering-duration',
    () async {
      final client = LoiteringDurationClient(
        NuraeyeClient(
          _connection,
          httpClient: mockNuraeyeRest(routeByPath({
            '/nuraeye/events/loitering-duration': (request) {
              expect(request.method, 'GET');
              return jsonOk({'loitering_duration_seconds': 15});
            },
          })),
        ),
      );

      final result = await client.getLoiteringDuration();

      expect(result, isA<CameraSuccess<int>>());
      expect((result as CameraSuccess<int>).value, 15);
    },
  );

  test(
    'setLoiteringDuration POSTs {"loitering_duration_seconds": 90} to /nuraeye/events/loitering-duration',
    () async {
      Map<String, dynamic>? captured;
      final client = LoiteringDurationClient(
        NuraeyeClient(
          _connection,
          httpClient: mockNuraeyeRest(routeByPath({
            '/nuraeye/events/loitering-duration': (request) {
              captured = {'method': request.method, 'body': request.body};
              return jsonOk(const {});
            },
          })),
        ),
      );

      final result = await client.setLoiteringDuration(90);

      expect(result, isA<CameraSuccess<void>>());
      expect(captured!['method'], 'POST');
      expect(captured!['body'], '{"loitering_duration_seconds":90}');
    },
  );

  test('setLoiteringDuration surfaces a rejected out-of-range value as CameraFailure', () async {
    final client = LoiteringDurationClient(
      NuraeyeClient(
        _connection,
        httpClient: mockNuraeyeRest(routeByPath({
          '/nuraeye/events/loitering-duration': (request) =>
              jsonError(400, 'loitering_duration_seconds out of range'),
        })),
      ),
    );

    final result = await client.setLoiteringDuration(0);

    expect(result, isA<CameraFailure<void>>());
  });
}
