import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _kSampleSettingsResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">
<s:Body>
<timg:GetImagingSettingsResponse xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">
<timg:ImagingSettings>
<tt:Brightness>55.0</tt:Brightness>
<tt:ColorSaturation>50.0</tt:ColorSaturation>
<tt:Contrast>50.0</tt:Contrast>
<tt:Exposure><tt:Mode>AUTO</tt:Mode></tt:Exposure>
<tt:IrCutFilter>AUTO</tt:IrCutFilter>
<tt:Sharpness>50.0</tt:Sharpness>
<tt:WideDynamicRange><tt:Mode>ON</tt:Mode><tt:Level>10.0</tt:Level></tt:WideDynamicRange>
<tt:WhiteBalance><tt:Mode>AUTO</tt:Mode></tt:WhiteBalance>
</timg:ImagingSettings>
</timg:GetImagingSettingsResponse>
</s:Body>
</s:Envelope>''';

void main() {
  test('getImagingSettings parses Brightness/WDR/IrCutFilter from a real-shaped response', () async {
    final client = OnvifImagingClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/onvif/imaging_service');
        expect(request.body, contains('GetImagingSettings'));
        return http.Response(_kSampleSettingsResponse, 200);
      }),
    );

    final result = await client.getImagingSettings();

    expect(result, isA<CameraSuccess<ImagingSettings>>());
    final settings = (result as CameraSuccess<ImagingSettings>).value;
    expect(settings.brightness, 55.0);
    expect(settings.irCutFilterMode, 'AUTO');
    expect(settings.wdrMode, 'ON');
    expect(settings.wdrLevel, 10.0);
  });

  test('setImagingSettings posts only the requested fields', () async {
    final client = OnvifImagingClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('SetImagingSettings'));
        expect(request.body, contains('<tt:IrCutFilter>OFF</tt:IrCutFilter>'));
        expect(request.body, isNot(contains('Brightness')));
        return http.Response(
          '<?xml version="1.0"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body><timg:SetImagingSettingsResponse '
          'xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl"/></s:Body></s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.setImagingSettings(const ImagingSettings(irCutFilterMode: 'OFF'));

    expect(result, isA<CameraSuccess<void>>());
  });
}
