import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// Shaped from onvif_replaycontrol.c's prvGenerateGetServiceCapabilitiesResponse() --
// ReversePlayback/RTP_RTSP_TCP are attributes on trp:Capabilities, SessionTimeoutRange is a
// plain-integer-seconds child element (not a tt:FloatRange or ISO-8601 duration).
const _kServiceCapabilitiesResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<trp:GetServiceCapabilitiesResponse>
<trp:Capabilities ReversePlayback="false" RTP_RTSP_TCP="true">
<trp:SessionTimeoutRange>60</trp:SessionTimeoutRange>
</trp:Capabilities>
</trp:GetServiceCapabilitiesResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

// Shaped from prvGenerateGetReplayUriResponse().
const _kGetReplayUriResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<trp:GetReplayUriResponse>
<trp:Uri>rtsp://192.168.1.50:558/playback/1735689600</trp:Uri>
</trp:GetReplayUriResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

// Shaped from onvif_fault_generateResponse() for OnvifError_NoSuchConfiguration -- the specific
// fault onvif_replaycontrol.c's GetReplayUri returns when RecordingToken doesn't resolve to an
// existing clip (MP4_Helper_ResolveRecordingFilename() fails).
const _kNoSuchConfigFaultResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<SOAP-ENV:Fault>
<SOAP-ENV:Reason><SOAP-ENV:Text>No such configuration</SOAP-ENV:Text></SOAP-ENV:Reason>
</SOAP-ENV:Fault>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

void main() {
  test('getServiceCapabilities parses attributes and SessionTimeoutRange as plain seconds', () async {
    final client = OnvifReplayControlClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/onvif/replay');
        expect(request.body, contains('GetServiceCapabilities'));
        return http.Response(_kServiceCapabilitiesResponse, 200);
      }),
    );

    final result = await client.getServiceCapabilities();

    expect(result, isA<CameraSuccess<ReplayServiceCapabilities>>());
    final caps = (result as CameraSuccess<ReplayServiceCapabilities>).value;
    expect(caps.reversePlayback, false);
    expect(caps.rtpRtspTcp, true);
    expect(caps.sessionTimeoutSeconds, 60);
  });

  test('getReplayUri parses the returned RTSP URI and sends RecordingToken', () async {
    final client = OnvifReplayControlClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetReplayUri'));
        expect(request.body, contains('<trp:RecordingToken>1735689600</trp:RecordingToken>'));
        return http.Response(_kGetReplayUriResponse, 200);
      }),
    );

    final result = await client.getReplayUri('1735689600');

    expect(result, isA<CameraSuccess<String>>());
    expect((result as CameraSuccess<String>).value, 'rtsp://192.168.1.50:558/playback/1735689600');
  });

  test('getReplayUri surfaces a SOAP fault for an unknown RecordingToken as CameraFailure', () async {
    final client = OnvifReplayControlClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(_kNoSuchConfigFaultResponse, 200)),
    );

    final result = await client.getReplayUri('999999');

    expect(result, isA<CameraFailure<String>>());
    expect((result as CameraFailure<String>).reason, 'No such configuration');
  });

  test('getReplayUri on a well-formed but empty response body returns an empty URI, not a crash', () async {
    // A response missing the expected trp:Uri child entirely -- e.g. a future firmware bug, or
    // a proxy stripping the body. XmlDocument.parse() itself only throws on genuinely malformed
    // XML (not tested here, matching OnvifImagingClient's own convention of not guarding against
    // that case) -- this covers the "well-formed XML, missing expected element" edge instead.
    const emptyResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<trp:GetReplayUriResponse>
</trp:GetReplayUriResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';
    final client = OnvifReplayControlClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(emptyResponse, 200)),
    );

    final result = await client.getReplayUri('1735689600');

    expect(result, isA<CameraSuccess<String>>());
    expect((result as CameraSuccess<String>).value, isEmpty);
  });
}
