import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('getSupportedTimezones parses the timezones array (stateless, always-live)', () async {
    // 2026-08-28: `camera_api` no longer caches `GetSupportedTimezones` responses itself — that
    // moved to the app layer (`mobile_app/lib/features/settings/camera_settings_cache.dart`'s
    // `NetworkAnswerCache`), so `camera_api` stays "just network client only." Every call must
    // hit the network.
    var requestCount = 0;
    final client = NetworkInfoClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/timezones': (request) {
          requestCount++;
          return jsonOk({
            'timezones': [
              {'code': 'UTC', 'name': 'Coordinated Universal Time (UTC)'},
              {'code': 'IST-5:30', 'name': 'India Standard Time - Kolkata (UTC+05:30)'},
            ],
          });
        },
      })),
    );

    final first = await client.getSupportedTimezones();
    expect(first, isA<CameraSuccess<List<TimezoneOption>>>());
    final options = (first as CameraSuccess<List<TimezoneOption>>).value;
    expect(options, hasLength(2));
    expect(options[0].code, 'UTC');
    expect(options[1].name, 'India Standard Time - Kolkata (UTC+05:30)');
    expect(requestCount, 1);

    // Second call is a fresh network round trip — no caching in this package any more.
    final second = await client.getSupportedTimezones();
    expect(second, isA<CameraSuccess<List<TimezoneOption>>>());
    expect(requestCount, 2);
  });

  test('setupWifi POSTs ssid, psk, and verify (default true) to /nuraeye/wifi', () async {
    final client = NetworkInfoClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/wifi': (request) {
          expect(request.method, 'POST');
          expect(request.body, contains('"ssid":"HomeNet"'));
          expect(request.body, contains('"psk":"secretpw"'));
          expect(request.body, contains('"verify":true'));
          return jsonOk(const {});
        },
      })),
    );

    final result = await client.setupWifi(ssid: 'HomeNet', psk: 'secretpw');

    expect(result, isA<CameraSuccess<void>>());
  });

  test('setupWifi(verify: false) sends verify:false for pre-configure-only', () async {
    final client = NetworkInfoClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/wifi': (request) {
          expect(request.body, contains('"verify":false'));
          return jsonOk(const {});
        },
      })),
    );

    final result = await client.setupWifi(ssid: 'HomeNet', psk: 'secretpw', verify: false);

    expect(result, isA<CameraSuccess<void>>());
  });
}
