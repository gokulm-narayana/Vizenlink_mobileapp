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

const _getOsdsResponse = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">
  <s:Body>
    <tr2:GetOSDsResponse>
      <tr2:OSDs token="OSDCfg_1">
        <tt:VideoSourceConfigurationToken>VideoSourceCfg_1</tt:VideoSourceConfigurationToken>
        <tt:Type>Text</tt:Type>
        <tt:Position><tt:Type>Custom</tt:Type><tt:Pos x="-1.0" y="1.0"/></tt:Position>
        <tt:TextString IsPersistentText="true">
          <tt:FontSize>12</tt:FontSize>
          <tt:Type>Plain</tt:Type>
          <tt:PlainText>Front Door</tt:PlainText>
        </tt:TextString>
      </tr2:OSDs>
    </tr2:GetOSDsResponse>
  </s:Body>
</s:Envelope>
''';

const _getOsdOptionsResponse = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">
  <s:Body>
    <tr2:GetOSDOptionsResponse>
      <tr2:OSDOptions>
        <tt:Type>Text</tt:Type>
        <tt:PositionOption>Custom</tt:PositionOption>
        <tt:TextOption>
          <tt:Type>Plain</tt:Type>
          <tt:FontSizeRange><tt:Min>8</tt:Min><tt:Max>24</tt:Max></tt:FontSizeRange>
          <tt:FontColor>
            <tt:Color>
              <tt:ColorList X="0.00" Y="0.00" Z="0.00" Colorspace="RGB"/>
              <tt:ColorList X="1.00" Y="1.00" Z="1.00" Colorspace="RGB"/>
            </tt:Color>
            <tt:Transparent><tt:Min>0</tt:Min><tt:Max>0</tt:Max></tt:Transparent>
          </tt:FontColor>
        </tt:TextOption>
      </tr2:OSDOptions>
    </tr2:GetOSDOptionsResponse>
  </s:Body>
</s:Envelope>
''';

/// Mirrors `mask_client_test.dart`'s `_mockClient` — every `OsdClient` request now resolves the
/// Media2 endpoint via `GetServices` first (2026-08-11 migration), so every test needs to answer
/// that lookup before its own action-specific response.
http.Client _mockClient(String actionResponse) {
  return MockClient((request) async {
    if (request.url.path == '/onvif/device_service') {
      return http.Response(_getServicesResponse, 200);
    }
    return http.Response(actionResponse, 200);
  });
}

void main() {
  // Shared CameraConnection.host across this file — without this, the process-lifetime
  // endpoint/options cache OsdClient now keeps (same convention MaskClient established) would
  // leak state between otherwise-independent test cases.
  setUp(OsdClient.debugClearCaches);

  test('getOsds parses each entry\'s current position', () async {
    final client = OsdClient(_connection, httpClient: _mockClient(_getOsdsResponse));

    final result = await client.getOsds();

    expect(result, isA<CameraSuccess<List<OsdEntry>>>());
    final entries = (result as CameraSuccess<List<OsdEntry>>).value;
    expect(entries, hasLength(1));
    expect(entries.first.posX, -1.0);
    expect(entries.first.posY, 1.0);
    expect(entries.first.plainText, 'Front Door');
  });

  test('getOsdOptions reports the font size range and every supported color', () async {
    final client = OsdClient(_connection, httpClient: _mockClient(_getOsdOptionsResponse));

    final result = await client.getOsdOptions();

    expect(result, isA<CameraSuccess<OsdOptions>>());
    final options = (result as CameraSuccess<OsdOptions>).value;
    expect(options.fontSizeMin, 8);
    expect(options.fontSizeMax, 24);
    expect(options.fontColors, hasLength(2));
  });

  test('createTextOsd sends the custom position and color when provided', () async {
    http.Request? captured;
    final client = OsdClient(
      _connection,
      httpClient: MockClient((request) async {
        if (request.url.path == '/onvif/device_service') {
          return http.Response(_getServicesResponse, 200);
        }
        captured = request;
        return http.Response(
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" '
          'xmlns:tr2="http://www.onvif.org/ver20/media/wsdl">'
          '<s:Body><tr2:CreateOSDResponse><tr2:OSDToken>OSDCfg_1</tr2:OSDToken>'
          '</tr2:CreateOSDResponse></s:Body></s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.createTextOsd(
      'Front Door',
      posX: 0.3,
      posY: -0.2,
      fontColor: const OsdColor(x: 1, y: 1, z: 1, colorspace: 'RGB'),
    );

    expect(result, isA<CameraSuccess<String>>());
    expect(captured!.body, contains('x="0.3" y="-0.2"'));
    expect(captured!.body, contains('<tt:FontColor><tt:Color X="1.0" Y="1.0" Z="1.0" Colorspace="RGB"/></tt:FontColor>'));
  });
}
