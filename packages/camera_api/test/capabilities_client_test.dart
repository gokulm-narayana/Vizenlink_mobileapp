import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  // NuraeyeClient caches session tokens and GetCapabilities responses per host for the process
  // lifetime (`.claude/rules/mobile-app.md`'s caching convention) — clear between tests so one
  // test's mocked response can't leak into the next via that static cache.
  setUp(NuraeyeClient.debugClearCaches);

  test('getCapabilities parses wan_command_capable and wan_live_view_capable', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/capabilities': (request) {
          expect(request.method, 'GET');
          return jsonOk({'wan_command_capable': true, 'wan_live_view_capable': true});
        },
      })),
    );
    final client = CapabilitiesClient(nuraeye);

    final result = await client.getCapabilities();

    expect(result, isA<CameraSuccess<CameraCapabilities>>());
    final caps = (result as CameraSuccess<CameraCapabilities>).value;
    expect(caps.wanCommandCapable, true);
    expect(caps.wanLiveViewCapable, true);
  });

  test(
    'getCapabilities reports AWS commands capable but KVS not (cost-constrained SKU, FR-CF-137)',
    () async {
      final nuraeye = NuraeyeClient(
        const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
        httpClient: mockNuraeyeRest(routeByPath({
          '/nuraeye/capabilities': (request) =>
              jsonOk({'wan_command_capable': true, 'wan_live_view_capable': false}),
        })),
      );
      final client = CapabilitiesClient(nuraeye);

      final result = await client.getCapabilities();

      final caps = (result as CameraSuccess<CameraCapabilities>).value;
      expect(caps.wanCommandCapable, true);
      expect(caps.wanLiveViewCapable, false);
    },
  );

  test('getCapabilities reports both false for an unprovisioned/AWS-disabled build', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/capabilities': (request) =>
            jsonOk({'wan_command_capable': false, 'wan_live_view_capable': false}),
      })),
    );
    final client = CapabilitiesClient(nuraeye);

    final result = await client.getCapabilities();

    final caps = (result as CameraSuccess<CameraCapabilities>).value;
    expect(caps.wanCommandCapable, false);
    expect(caps.wanLiveViewCapable, false);
  });

  test('getCapabilities surfaces CameraFailure on a malformed response', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/capabilities': (request) => jsonOk(const {}),
      })),
    );
    final client = CapabilitiesClient(nuraeye);

    final result = await client.getCapabilities();

    expect(result, isA<CameraFailure<CameraCapabilities>>());
  });
}
