import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// Shaped from onvif_recording.c's prvGenerateGetRecordingsResponse()/
// prvGenerateRecordingItemSnippet() — SOAP envelope namespaces per onvif_soap.c's
// onvif_soap_startResponse() (note: no trc:/tse:/trp: prefix is declared anywhere on the
// envelope root by the firmware itself, so this sample intentionally omits it too, matching
// real firmware output byte-for-byte).
const _kSampleGetRecordingsResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:tt="http://www.onvif.org/ver10/schema">
<SOAP-ENV:Body>
<trc:GetRecordingsResponse>
<trc:RecordingItem>
<trc:RecordingToken>1735689600</trc:RecordingToken>
<trc:Value>
<tt:RecordingConfiguration>
<tt:Source>
<tt:SourceId>VideoSource_1</tt:SourceId>
<tt:Name>Front Door</tt:Name>
<tt:Location>Porch</tt:Location>
</tt:Source>
<tt:Content>Loitering</tt:Content>
<tt:MaximumRetentionTime>PT86400S</tt:MaximumRetentionTime>
</tt:RecordingConfiguration>
<trc:TrackList>
<trc:Track>
<trc:TrackToken>VideoTrack_1</trc:TrackToken>
<tt:TrackConfiguration>
<tt:TrackType>Video</tt:TrackType>
<tt:Description>H.264 video track</tt:Description>
</tt:TrackConfiguration>
</trc:Track>
</trc:TrackList>
</trc:Value>
</trc:RecordingItem>
</trc:GetRecordingsResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

// Shaped from prvGenerateGetServiceCapabilitiesResponse() -- attribute-only self-closed tag
// (nexml_createTag with a null text value).
const _kSampleServiceCapabilitiesResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<trc:GetServiceCapabilitiesResponse>
<trc:Capabilities DynamicRecordings="false" DynamicTracks="false" Options="false" MaxRecordings="500" MaxRecordingJobs="1"/>
</trc:GetServiceCapabilitiesResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

// Shaped from prvGenerateGetRecordingOptionsResponse() -- Job/Track child elements each carrying
// attributes, always-zero spare values on this device.
const _kSampleRecordingOptionsResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<trc:GetRecordingOptionsResponse>
<trc:Options>
<trc:Job Spare="0"/>
<trc:Track SpareTotal="0" SpareVideo="0" SpareAudio="0" SpareMetadata="0"/>
</trc:Options>
</trc:GetRecordingOptionsResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

const _kSoapFaultResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:env="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<SOAP-ENV:Fault>
<SOAP-ENV:Reason><SOAP-ENV:Text>Action not supported</SOAP-ENV:Text></SOAP-ENV:Reason>
</SOAP-ENV:Fault>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

void main() {
  test('getRecordings parses RecordingItem/Source/Track from a real-shaped response', () async {
    final client = OnvifRecordingClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/onvif/recording');
        expect(request.body, contains('GetRecordings'));
        return http.Response(_kSampleGetRecordingsResponse, 200);
      }),
    );

    final result = await client.getRecordings();

    expect(result, isA<CameraSuccess<List<RecordingInfo>>>());
    final recordings = (result as CameraSuccess<List<RecordingInfo>>).value;
    expect(recordings, hasLength(1));
    final clip = recordings.first;
    expect(clip.recordingToken, '1735689600');
    expect(clip.sourceId, 'VideoSource_1');
    expect(clip.sourceName, 'Front Door');
    expect(clip.sourceLocation, 'Porch');
    expect(clip.content, 'Loitering');
    expect(clip.maximumRetentionTimeSeconds, 86400);
    expect(clip.tracks, hasLength(1));
    expect(clip.tracks.first.trackToken, 'VideoTrack_1');
    expect(clip.tracks.first.trackType, 'Video');
  });

  test('getServiceCapabilities parses attribute-only self-closed Capabilities tag', () async {
    final client = OnvifRecordingClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetServiceCapabilities'));
        return http.Response(_kSampleServiceCapabilitiesResponse, 200);
      }),
    );

    final result = await client.getServiceCapabilities();

    expect(result, isA<CameraSuccess<RecordingServiceCapabilities>>());
    final caps = (result as CameraSuccess<RecordingServiceCapabilities>).value;
    expect(caps.dynamicRecordings, false);
    expect(caps.optionsSupported, false);
    expect(caps.maxRecordings, 500.0);
    expect(caps.maxRecordingJobs, 1);
  });

  test('getRecordingOptions parses always-zero spare capacity', () async {
    final client = OnvifRecordingClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetRecordingOptions'));
        return http.Response(_kSampleRecordingOptionsResponse, 200);
      }),
    );

    final result = await client.getRecordingOptions();

    expect(result, isA<CameraSuccess<RecordingOptions>>());
    final options = (result as CameraSuccess<RecordingOptions>).value;
    expect(options.jobSpare, 0);
    expect(options.trackSpareVideo, 0);
  });

  test('getRecordings surfaces a SOAP fault as CameraFailure', () async {
    final client = OnvifRecordingClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(_kSoapFaultResponse, 200)),
    );

    final result = await client.getRecordings();

    expect(result, isA<CameraFailure<List<RecordingInfo>>>());
    expect((result as CameraFailure<List<RecordingInfo>>).reason, 'Action not supported');
  });

  test('getRecordings on an empty clip list returns an empty list, not a failure', () async {
    const emptyResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<trc:GetRecordingsResponse>
</trc:GetRecordingsResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';
    final client = OnvifRecordingClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(emptyResponse, 200)),
    );

    final result = await client.getRecordings();

    expect(result, isA<CameraSuccess<List<RecordingInfo>>>());
    expect((result as CameraSuccess<List<RecordingInfo>>).value, isEmpty);
  });
}
