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

const _getServicesResponseNoMedia2 = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tds="http://www.onvif.org/ver10/device/wsdl">
  <s:Body>
    <tds:GetServicesResponse>
      <tds:Service>
        <tds:Namespace>http://www.onvif.org/ver10/device/wsdl</tds:Namespace>
        <tds:XAddr>https://192.168.1.50:443/onvif/device_service</tds:XAddr>
      </tds:Service>
    </tds:GetServicesResponse>
  </s:Body>
</s:Envelope>
''';

const _getServiceCapabilitiesResponse = '''
<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl">
  <s:Body>
    <tr2:GetServiceCapabilitiesResponse>
      <tr2:Capabilities SnapshotUri="true" OSD="true" Mask="true" SourceMask="true" WebRTC="0"/>
    </tr2:GetServiceCapabilitiesResponse>
  </s:Body>
</s:Envelope>
''';

void main() {
  test(
    'getServiceCapabilities discovers the Media2 endpoint via GetServices, not a hardcoded path',
    () async {
      final client = Media2CapabilitiesClient(
        _connection,
        httpClient: MockClient((request) async {
          if (request.url.path == '/onvif/device_service') {
            expect(request.body, contains('GetServices'));
            return http.Response(_getServicesResponse, 200);
          }
          if (request.url.path == '/onvif/media2_service') {
            expect(request.body, contains('GetServiceCapabilities'));
            return http.Response(_getServiceCapabilitiesResponse, 200);
          }
          return http.Response('unexpected path: ${request.url.path}', 404);
        }),
      );

      final result = await client.getServiceCapabilities();

      expect(result, isA<CameraSuccess<Media2Capabilities>>());
      final caps = (result as CameraSuccess<Media2Capabilities>).value;
      expect(caps.osdSupported, true);
      expect(caps.maskSupported, true);
    },
  );

  test(
    'reports unsupported (not a failure) when GetServices does not list a Media2 entry at all',
    () async {
      var media2Requested = false;
      final client = Media2CapabilitiesClient(
        _connection,
        httpClient: MockClient((request) async {
          if (request.url.path == '/onvif/device_service') {
            return http.Response(_getServicesResponseNoMedia2, 200);
          }
          media2Requested = true;
          return http.Response('should not be called', 404);
        }),
      );

      final result = await client.getServiceCapabilities();

      expect(result, isA<CameraSuccess<Media2Capabilities>>());
      final caps = (result as CameraSuccess<Media2Capabilities>).value;
      expect(caps.osdSupported, false);
      expect(caps.maskSupported, false);
      expect(media2Requested, false);
    },
  );
}
