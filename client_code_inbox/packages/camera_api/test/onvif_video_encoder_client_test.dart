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
  test(
    'getVideoEncoderSettings resolves the Media2 endpoint via GetServices and parses '
    'bitrate/frame_rate/gov_length/quality/profile/encoding/cbr, targeting the high-res token',
    () async {
      final client = OnvifVideoEncoderClient(
        _connection,
        httpClient: _mockClient({
          'GetVideoEncoderConfigurations': (request) {
            expect(
              request.body,
              contains('<tr2:ConfigurationToken>VideoEncoderCfg_1</tr2:ConfigurationToken>'),
            );
            return '<?xml version="1.0" encoding="UTF-8"?>'
                '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
                '<s:Body>'
                '<tr2:GetVideoEncoderConfigurationsResponse xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" '
                'xmlns:tt="http://www.onvif.org/ver10/schema">'
                '<tr2:Configurations token="VideoEncoderCfg_1" GovLength="30" Profile="High">'
                '<tt:Name>VideoEncoderCfg_1</tt:Name>'
                '<tt:UseCount>1</tt:UseCount>'
                '<tt:Encoding>H264</tt:Encoding>'
                '<tt:Resolution><tt:Width>1920</tt:Width><tt:Height>1080</tt:Height></tt:Resolution>'
                '<tt:Quality>5</tt:Quality>'
                '<tt:RateControl ConstantBitRate="true">'
                '<tt:FrameRateLimit>30</tt:FrameRateLimit>'
                '<tt:BitrateLimit>2048</tt:BitrateLimit>'
                '</tt:RateControl>'
                '</tr2:Configurations>'
                '</tr2:GetVideoEncoderConfigurationsResponse>'
                '</s:Body>'
                '</s:Envelope>';
          },
        }),
      );

      final result = await client.getVideoEncoderSettings();

      expect(result, isA<CameraSuccess<VideoEncoderSettings>>());
      final value = (result as CameraSuccess<VideoEncoderSettings>).value;
      expect(value.bitrate, 2048);
      expect(value.frameRate, 30);
      expect(value.govLength, 30);
      expect(value.quality, 5);
      expect(value.encoderProfile, 'High');
      expect(value.width, 1920);
      expect(value.height, 1080);
      expect(value.encoding, 'H264');
      expect(value.cbr, true);
    },
  );

  test('setVideoEncoderSettings sends the full configuration including encoding/cbr', () async {
    final client = OnvifVideoEncoderClient(
      _connection,
      httpClient: _mockClient({
        'SetVideoEncoderConfiguration': (request) {
          expect(request.body, contains('token="VideoEncoderCfg_1"'));
          expect(request.body, contains('GovLength="25"'));
          expect(request.body, contains('Profile="Main"'));
          expect(request.body, contains('<tt:Encoding>H265</tt:Encoding>'));
          expect(request.body, contains('<tt:Width>1920</tt:Width>'));
          expect(request.body, contains('<tt:Height>1080</tt:Height>'));
          expect(request.body, contains('<tt:BitrateLimit>1536</tt:BitrateLimit>'));
          expect(request.body, contains('<tt:FrameRateLimit>25</tt:FrameRateLimit>'));
          expect(request.body, contains('<tt:Quality>7</tt:Quality>'));
          expect(request.body, contains('ConstantBitRate="false"'));
          return '<?xml version="1.0" encoding="UTF-8"?>'
              '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
              '<s:Body><tr2:SetVideoEncoderConfigurationResponse xmlns:tr2="http://www.onvif.org/ver20/media/wsdl"/></s:Body>'
              '</s:Envelope>';
        },
      }),
    );

    final result = await client.setVideoEncoderSettings(
      const VideoEncoderSettings(
        bitrate: 1536,
        frameRate: 25,
        govLength: 25,
        quality: 7,
        encoderProfile: 'Main',
        width: 1920,
        height: 1080,
        encoding: 'H265',
        cbr: false,
      ),
    );

    expect(result, isA<CameraSuccess<void>>());
  });

  test(
    'getVideoEncoderSettingsOptions parses a per-encoding array — H264 and H265 report '
    'different ranges/profiles/CBR support',
    () async {
      final client = OnvifVideoEncoderClient(
        _connection,
        httpClient: _mockClient({
          'GetVideoEncoderConfigurationOptions': (_) =>
              '<?xml version="1.0" encoding="UTF-8"?>'
              '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
              '<s:Body>'
              '<tr2:GetVideoEncoderConfigurationOptionsResponse xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" '
              'xmlns:tt="http://www.onvif.org/ver10/schema">'
              '<tr2:Options GovLengthRange="1 60" FrameRatesSupported="5 10 15 20 25 30" '
              'ProfilesSupported="Baseline Main High" ConstantBitRateSupported="true">'
              '<tt:Encoding>H264</tt:Encoding>'
              '<tt:QualityRange><tt:Min>1</tt:Min><tt:Max>10</tt:Max></tt:QualityRange>'
              '<tt:BitrateRange><tt:Min>32</tt:Min><tt:Max>8192</tt:Max></tt:BitrateRange>'
              '<tt:ResolutionsAvailable><tt:Width>1920</tt:Width><tt:Height>1080</tt:Height></tt:ResolutionsAvailable>'
              '</tr2:Options>'
              '<tr2:Options GovLengthRange="1 60" FrameRatesSupported="5 10 15 20 25 30" '
              'ProfilesSupported="Main Main10" ConstantBitRateSupported="false">'
              '<tt:Encoding>H265</tt:Encoding>'
              '<tt:QualityRange><tt:Min>1</tt:Min><tt:Max>10</tt:Max></tt:QualityRange>'
              '<tt:BitrateRange><tt:Min>32</tt:Min><tt:Max>4096</tt:Max></tt:BitrateRange>'
              '<tt:ResolutionsAvailable><tt:Width>1920</tt:Width><tt:Height>1080</tt:Height></tt:ResolutionsAvailable>'
              '</tr2:Options>'
              '</tr2:GetVideoEncoderConfigurationOptionsResponse>'
              '</s:Body>'
              '</s:Envelope>',
        }),
      );

      final result = await client.getVideoEncoderSettingsOptions();

      expect(result, isA<CameraSuccess<VideoEncoderSettingsOptions>>());
      final value = (result as CameraSuccess<VideoEncoderSettingsOptions>).value;
      expect(value.availableEncodings, ['H264', 'H265']);

      final h264 = value.forEncoding('H264')!;
      expect(h264.bitrateRange, const IntRange(32, 8192));
      expect(h264.qualityRange, const IntRange(1, 10));
      expect(h264.govLengthRange, const IntRange(1, 60));
      expect(h264.frameRateRange, const IntRange(5, 30));
      expect(h264.encoderProfiles, ['Baseline', 'Main', 'High']);
      expect(h264.resolutions, [(width: 1920, height: 1080)]);
      expect(h264.supportsCbr, true);

      final h265 = value.forEncoding('H265')!;
      expect(h265.bitrateRange, const IntRange(32, 4096));
      expect(h265.encoderProfiles, ['Main', 'Main10']);
      expect(h265.supportsCbr, false);
    },
  );
}
