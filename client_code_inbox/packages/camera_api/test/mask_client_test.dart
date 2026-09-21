import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _connection = CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw');

const _getServicesResponse = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <s:Body>
    <tds:GetServicesResponse>
      <tds:Service>
        <tds:Namespace>http://www.onvif.org/ver10/device/wsdl</tds:Namespace>
        <tds:XAddr>https://192.168.1.50:443/onvif/device_service</tds:XAddr>
      </tds:Service>
      <tds:Service>
        <tds:Namespace>http://www.onvif.org/ver20/media/wsdl</tds:Namespace>
        <tds:XAddr>https://192.168.1.50:443/onvif/media2_service</tds:XAddr>
      </tds:Service>
    </tds:GetServicesResponse>
  </s:Body>
</s:Envelope>
''';

const _getMasksResponse = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">
  <s:Body>
    <tr2:GetMasksResponse>
      <tr2:Masks token="Mask_1">
        <tr2:ConfigurationToken>VideoSourceCfg_1</tr2:ConfigurationToken>
        <tr2:Polygon>
          <tt:Point x="-0.5" y="0.5"/>
          <tt:Point x="0.0" y="0.5"/>
          <tt:Point x="0.0" y="0.0"/>
          <tt:Point x="-0.5" y="0.0"/>
        </tr2:Polygon>
        <tr2:Type>Color</tr2:Type>
        <tr2:Color X="0.00" Y="0.00" Z="0.00" Colorspace="RGB"/>
        <tr2:Enabled>true</tr2:Enabled>
      </tr2:Masks>
    </tr2:GetMasksResponse>
  </s:Body>
</s:Envelope>
''';

const _getMaskOptionsResponse = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">
  <s:Body>
    <tr2:GetMaskOptionsResponse>
      <tr2:Options RectangleOnly="true" SingleColorOnly="true">
        <tr2:MaxMasks>4</tr2:MaxMasks>
        <tr2:MaxPoints>4</tr2:MaxPoints>
        <tr2:Types>Color</tr2:Types>
        <tr2:Color>
          <tt:ColorList X="0.00" Y="0.00" Z="0.00" Colorspace="RGB"/>
        </tr2:Color>
      </tr2:Options>
    </tr2:GetMaskOptionsResponse>
  </s:Body>
</s:Envelope>
''';

const _createMaskResponse = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl">
  <s:Body>
    <tr2:CreateMaskResponse>
      <tr2:Token>Mask_2</tr2:Token>
    </tr2:CreateMaskResponse>
  </s:Body>
</s:Envelope>
''';

http.Client _mockClient(Map<String, String Function(http.Request)> byMarker) {
  return MockClient((request) async {
    for (final entry in byMarker.entries) {
      if (request.body.contains(entry.key)) {
        return http.Response(entry.value(request), 200);
      }
    }
    if (request.url.path == '/onvif/device_service') {
      return http.Response(_getServicesResponse, 200);
    }
    return http.Response('unexpected request: ${request.body}', 404);
  });
}

void main() {
  test('getMasks resolves the Media2 endpoint via GetServices and parses the mask list', () async {
    final client = MaskClient(
      _connection,
      httpClient: _mockClient({'GetMasks': (_) => _getMasksResponse}),
    );

    final result = await client.getMasks();

    expect(result, isA<CameraSuccess<List<MaskEntry>>>());
    final masks = (result as CameraSuccess<List<MaskEntry>>).value;
    expect(masks, hasLength(1));
    expect(masks.first.token, 'Mask_1');
    expect(masks.first.enabled, true);
    expect(masks.first.polygon, hasLength(4));
    expect(masks.first.polygon.first.x, -0.5);
  });

  test('getMaskOptions reports exactly one type and one color on this firmware', () async {
    final client = MaskClient(
      _connection,
      httpClient: _mockClient({'GetMaskOptions': (_) => _getMaskOptionsResponse}),
    );

    final result = await client.getMaskOptions();

    expect(result, isA<CameraSuccess<MaskOptions>>());
    final options = (result as CameraSuccess<MaskOptions>).value;
    expect(options.types, ['Color']);
    expect(options.colorList, hasLength(1));
    expect(options.maxMasks, 4);
    expect(options.rectangleOnly, true);
    expect(options.singleColorOnly, true);
  });

  test('createMask sends a 4-point polygon and returns the new token', () async {
    http.Request? captured;
    final client = MaskClient(
      _connection,
      httpClient: _mockClient({
        'CreateMask': (request) {
          captured = request;
          return _createMaskResponse;
        },
      }),
    );

    final result = await client.createMask(
      polygon: const [
        OnvifPoint(-0.5, 0.5),
        OnvifPoint(0.0, 0.5),
        OnvifPoint(0.0, 0.0),
        OnvifPoint(-0.5, 0.0),
      ],
      enabled: true,
      type: 'Color',
      color: const MaskColor(x: 0, y: 0, z: 0, colorspace: 'RGB'),
    );

    expect(result, isA<CameraSuccess<String>>());
    expect((result as CameraSuccess<String>).value, 'Mask_2');
    expect(captured!.body, contains('<tr2:CreateMask'));
    expect(captured!.body, contains('x="-0.5" y="0.5"'));
    expect(captured!.body, contains('<tr2:Color X="0.0" Y="0.0" Z="0.0" Colorspace="RGB"/>'));
  });

  test('GetServices is only requested once across multiple mask calls (cached endpoint)', () async {
    var getServicesCount = 0;
    final client = MaskClient(
      _connection,
      httpClient: MockClient((request) async {
        if (request.url.path == '/onvif/device_service') {
          getServicesCount++;
          return http.Response(_getServicesResponse, 200);
        }
        if (request.body.contains('GetMasks')) return http.Response(_getMasksResponse, 200);
        if (request.body.contains('GetMaskOptions')) {
          return http.Response(_getMaskOptionsResponse, 200);
        }
        if (request.body.contains('CreateMask')) return http.Response(_createMaskResponse, 200);
        return http.Response('unexpected request: ${request.body}', 404);
      }),
    );

    await client.getMasks();
    await client.getMaskOptions();
    await client.createMask(
      polygon: const [
        OnvifPoint(-0.5, 0.5),
        OnvifPoint(0.0, 0.5),
        OnvifPoint(0.0, 0.0),
        OnvifPoint(-0.5, 0.0),
      ],
      enabled: true,
      type: 'Color',
    );

    expect(getServicesCount, 1);
  });

  test('getMaskOptions is a stateless, always-live call (no caching in this package)', () async {
    // 2026-08-28: `camera_api` no longer caches `GetMaskOptions` responses itself — that moved
    // to the app layer (`mobile_app/lib/features/settings/camera_settings_cache.dart`'s
    // `NetworkAnswerCache`), so `camera_api` stays "just network client only." Every call must
    // hit the network.
    var getMaskOptionsCount = 0;
    final client = MaskClient(
      _connection,
      httpClient: _mockClient({
        'GetMaskOptions': (_) {
          getMaskOptionsCount++;
          return _getMaskOptionsResponse;
        },
      }),
    );

    await client.getMaskOptions();
    await client.getMaskOptions();
    expect(getMaskOptionsCount, 2);
  });

  test('resolveMedia2Endpoint seeded via the constructor skips GetServices entirely', () async {
    var getServicesCount = 0;
    final client = MaskClient(
      _connection,
      endpoint: Uri.parse('https://192.168.1.50:443/onvif/media2_service'),
      httpClient: MockClient((request) async {
        if (request.url.path == '/onvif/device_service') {
          getServicesCount++;
          return http.Response(_getServicesResponse, 200);
        }
        if (request.body.contains('GetMaskOptions')) {
          return http.Response(_getMaskOptionsResponse, 200);
        }
        return http.Response('unexpected request: ${request.body}', 404);
      }),
    );

    final result = await client.getMaskOptions();

    expect(result, isA<CameraSuccess<MaskOptions>>());
    expect(getServicesCount, 0);
    expect(client.resolvedEndpoint, Uri.parse('https://192.168.1.50:443/onvif/media2_service'));
  });

  test('deleteMask sends the token and treats an empty response as success', () async {
    http.Request? captured;
    final client = MaskClient(
      _connection,
      httpClient: _mockClient({
        'DeleteMask': (request) {
          captured = request;
          return '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Body/></s:Envelope>';
        },
      }),
    );

    final result = await client.deleteMask('Mask_1');

    expect(result, isA<CameraSuccess<void>>());
    expect(captured!.body, contains('<tr2:Token>Mask_1</tr2:Token>'));
  });
}
