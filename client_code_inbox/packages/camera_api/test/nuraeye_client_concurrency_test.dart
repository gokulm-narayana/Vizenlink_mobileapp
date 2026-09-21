import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test(
    'concurrent calls for the same host share one session login, not one each '
    '(regression: real-hardware session-table churn found 2026-08-10 — two concurrent '
    'live-view requests each independently logging in evicted each other\'s session)',
    () async {
      var loginCalls = 0;
      final nuraeye = NuraeyeClient(
        const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
        httpClient: mockNuraeyeRest(
          routeByPath({
            '/nuraeye/video/mode': (request) => jsonOk({'configured_mode': 'Auto', 'effective_state': 'day'}),
            '/nuraeye/live-stream-uri': (request) => jsonOk({
                  'transport': 'webrtc',
                  'port': 8444,
                  'path': '/webrtc',
                  'url': 'http://192.168.1.50:8444/webrtc',
                }),
          }),
          onLogin: () => loginCalls++,
        ),
      );

      // Two independent, concurrent authenticated calls for the same camera — mirrors
      // live_view_screen.dart's GetVideoMode racing LiveViewController's GetLiveStreamUri on
      // screen open, both starting with an empty token cache.
      final results = await Future.wait([
        nuraeye.call('GetVideoMode'),
        nuraeye.call('GetLiveStreamUri', params: {'profile_token': 'Profile_2'}),
      ]);

      expect(results[0], isA<CameraSuccess<Map<String, dynamic>>>());
      expect(results[1], isA<CameraSuccess<Map<String, dynamic>>>());
      expect(loginCalls, 1);
    },
  );
}
