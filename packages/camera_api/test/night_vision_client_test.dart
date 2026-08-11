import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

import 'rest_mock_helpers.dart';

void main() {
  setUp(NuraeyeClient.debugClearCaches);

  test('getNightVisionType parses type and merges color/smart capable from GetCapabilities', () async {
    // REST split these: `GET /nuraeye/video/night-vision-type` reports live `type`/`sub_state`
    // only; `color_capable`/`smart_capable` moved into the consolidated `GET /nuraeye/capabilities`
    // (`FR-NE-104`, 2026-08-08) — NuraeyeClient's `GetNightVisionType` shim fetches both and merges
    // them back into the legacy shape this client still expects.
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/video/night-vision-type': (request) => jsonOk({'type': 'Color'}),
        '/nuraeye/capabilities': (request) =>
            jsonOk({'night_vision_color_capable': true, 'night_vision_smart_capable': false}),
      })),
    );
    final client = NightVisionClient(nuraeye);

    final result = await client.getNightVisionType();

    expect(result, isA<CameraSuccess<NightVisionStatus>>());
    final status = (result as CameraSuccess<NightVisionStatus>).value;
    expect(status.type, NightVisionType.color);
    expect(status.colorCapable, true);
    expect(status.smartCapable, false);
  });

  test('getNightVisionType parses sub_state only when type is Smart', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/video/night-vision-type': (request) =>
            jsonOk({'type': 'Smart', 'sub_state': 'Color'}),
        '/nuraeye/capabilities': (request) =>
            jsonOk({'night_vision_color_capable': true, 'night_vision_smart_capable': true}),
      })),
    );
    final client = NightVisionClient(nuraeye);

    final result = await client.getNightVisionType();

    final status = (result as CameraSuccess<NightVisionStatus>).value;
    expect(status.type, NightVisionType.smart);
    expect(status.subState, NightVisionType.color);
  });

  test('getNightVisionType leaves sub_state null when type is not Smart', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/video/night-vision-type': (request) => jsonOk({'type': 'Grey'}),
        '/nuraeye/capabilities': (request) =>
            jsonOk({'night_vision_color_capable': true, 'night_vision_smart_capable': true}),
      })),
    );
    final client = NightVisionClient(nuraeye);

    final result = await client.getNightVisionType();

    final status = (result as CameraSuccess<NightVisionStatus>).value;
    expect(status.subState, isNull);
  });

  test('setNightVisionType sends the wire value for Grey', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/video/night-vision-type': (request) {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'type': 'Grey'});
          return jsonOk(const {});
        },
      })),
    );
    final client = NightVisionClient(nuraeye);

    final result = await client.setNightVisionType(NightVisionType.grey);

    expect(result, isA<CameraSuccess<void>>());
  });

  test('setNightVisionType surfaces CameraFailure for a rejected (HTTP 400) request', () async {
    final nuraeye = NuraeyeClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: mockNuraeyeRest(routeByPath({
        '/nuraeye/video/night-vision-type': (request) => jsonError(400, 'unsupported'),
      })),
    );
    final client = NightVisionClient(nuraeye);

    final result = await client.setNightVisionType(NightVisionType.color);

    expect(result, isA<CameraFailure<void>>());
  });
}
