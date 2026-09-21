import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('reuses a fresh session across calls without re-logging in', () async {
    var loginCalls = 0;
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(
        routeByPath({
          '/nuraeye/privacy-mode': (request) => jsonOk({'mode': 'None'}),
        }),
        onLogin: () => loginCalls++,
      ),
    );

    final first = await nuraeye.call('GetPrivacyMode');
    expect(first, isA<CameraSuccess<Map<String, dynamic>>>());
    expect(loginCalls, 1);

    // Second call immediately after — session is fresh (1800s expiry, 15s leeway), must reuse
    // the cached token without another login.
    final second = await nuraeye.call('GetPrivacyMode');
    expect(second, isA<CameraSuccess<Map<String, dynamic>>>());
    expect(loginCalls, 1);
  });

  test(
    'proactively re-logs in once the cached session is past its expires_in_sec, without ever '
    'needing a 401 to find out',
    () async {
      var loginCalls = 0;
      var privacyModeCalls = 0;
      final nuraeye = NuraeyeClient(
        const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
        httpClient: mockNuraeyeRest(
          routeByPath({
            // Every real call succeeds regardless of which/whether a token is presented — this
            // test only cares about how many times the client *chooses* to log in, not about
            // the firmware ever rejecting a request. With expires_in_sec: 0, the session's
            // validUntil is already behind the expiry leeway the instant login returns, so the
            // very next call must trigger a fresh login even though nothing here ever 401s.
            '/nuraeye/privacy-mode': (request) {
              privacyModeCalls++;
              return jsonOk({'mode': 'None'});
            },
          }),
          expiresInSec: 0,
          onLogin: () => loginCalls++,
        ),
      );

      await nuraeye.call('GetPrivacyMode');
      await nuraeye.call('GetPrivacyMode');

      expect(privacyModeCalls, 2);
      expect(loginCalls, 2); // proactive re-login before the second call, no 401 involved
    },
  );

  test('an actively-used session is extended, not proactively re-logged-into, on every successful call', () async {
    var loginCalls = 0;
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(
        routeByPath({
          '/nuraeye/privacy-mode': (request) => jsonOk({'mode': 'None'}),
        }),
        onLogin: () => loginCalls++,
      ),
    );

    // Ten sequential calls on the same still-valid session must all reuse the one login.
    for (var i = 0; i < 10; i++) {
      final result = await nuraeye.call('GetPrivacyMode');
      expect(result, isA<CameraSuccess<Map<String, dynamic>>>());
    }
    expect(loginCalls, 1);
  });

  test('a 401 from the firmware (e.g. LRU-evicted by another client) still triggers exactly one retry login', () async {
    var loginCalls = 0;
    var privacyModeCalls = 0;
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(
        routeByPath({
          '/nuraeye/privacy-mode': (request) {
            privacyModeCalls++;
            // First real request fails as if the session were evicted server-side despite this
            // client believing it was still valid (e.g. another client's login stole the slot)
            // — the proactive expiry check can't catch this, only the reactive 401 retry can.
            if (privacyModeCalls == 1) return jsonError(401, 'Missing or invalid session token');
            return jsonOk({'mode': 'None'});
          },
        }),
        onLogin: () => loginCalls++,
      ),
    );

    final result = await nuraeye.call('GetPrivacyMode');

    expect(result, isA<CameraSuccess<Map<String, dynamic>>>());
    expect(loginCalls, 2); // initial login + one retry login after the 401
    expect(privacyModeCalls, 2); // initial rejected attempt + one successful retry
  });
}
