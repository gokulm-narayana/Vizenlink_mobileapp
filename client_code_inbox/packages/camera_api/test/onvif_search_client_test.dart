import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

// Shaped from onvif_search.c's prvGenerateFindRecordingsResponse() /
// onvif_soap_generateOneChildTagResponse() -- a single tse:SearchToken child.
const _kFindRecordingsResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<tse:FindRecordingsResponse>
<tse:SearchToken>1</tse:SearchToken>
</tse:FindRecordingsResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

// Shaped from prvGenerateGetRecordingSearchResultsResponse().
const _kGetRecordingSearchResultsResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:tt="http://www.onvif.org/ver10/schema">
<SOAP-ENV:Body>
<tse:GetRecordingSearchResultsResponse>
<tse:ResultList>
<tt:RecordingInformation>
<tt:RecordingToken>1735689600</tt:RecordingToken>
<tt:EarliestRecording>2025-01-01T00:00:00Z</tt:EarliestRecording>
<tt:LatestRecording>2025-01-01T00:01:00Z</tt:LatestRecording>
<tt:Content>Continuous recording</tt:Content>
<tt:RecordingStatus>Stopped</tt:RecordingStatus>
<tt:Track>
<tt:TrackToken>VideoTrack_1</tt:TrackToken>
<tt:TrackType>Video</tt:TrackType>
<tt:DataFrom>2025-01-01T00:00:00Z</tt:DataFrom>
<tt:DataTo>2025-01-01T00:01:00Z</tt:DataTo>
</tt:Track>
</tt:RecordingInformation>
</tse:ResultList>
<tse:SearchState>Completed</tse:SearchState>
</tse:GetRecordingSearchResultsResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

// Shaped from prvGenerateGetEventSearchResultsResponse() -- tse:Result carries attributes
// (SearchState/RecordingToken/TrackToken/Time), tt:Message wraps tt:Source (the raw EventMgr
// event ID as text, per that function's own comment about no recording correlation yet).
const _kGetEventSearchResultsResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:tt="http://www.onvif.org/ver10/schema">
<SOAP-ENV:Body>
<tse:GetEventSearchResultsResponse>
<tse:ResultList>
<tse:Result SearchState="Completed" RecordingToken="" TrackToken="VideoTrack_1" Time="2025-01-01T00:00:05Z">
<tt:Message UtcTime="2025-01-01T00:00:05Z">
<tt:Source>42</tt:Source>
</tt:Message>
</tse:Result>
</tse:ResultList>
<tse:SearchState>Completed</tse:SearchState>
</tse:GetEventSearchResultsResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

// Shaped from prvGenerateGetRecordingSummaryResponse().
const _kGetRecordingSummaryResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:tt="http://www.onvif.org/ver10/schema">
<SOAP-ENV:Body>
<tse:GetRecordingSummaryResponse>
<tse:Summary>
<tt:DataFrom>2025-01-01T00:00:00Z</tt:DataFrom>
<tt:DataUntil>2025-01-02T00:00:00Z</tt:DataUntil>
<tt:NumberRecordings>3</tt:NumberRecordings>
</tse:Summary>
</tse:GetRecordingSummaryResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

const _kSoapFaultResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<SOAP-ENV:Fault>
<SOAP-ENV:Reason><SOAP-ENV:Text>Invalid SearchToken</SOAP-ENV:Text></SOAP-ENV:Reason>
</SOAP-ENV:Fault>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';

void main() {
  test('findRecordings parses SearchToken and sends StartPoint/EndPoint', () async {
    final client = OnvifSearchClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/onvif/search');
        expect(request.body, contains('FindRecordings'));
        expect(request.body, contains('<tse:StartPoint>2025-01-01T00:00:00Z</tse:StartPoint>'));
        expect(request.body, contains('<tse:EndPoint>2025-01-02T00:00:00Z</tse:EndPoint>'));
        return http.Response(_kFindRecordingsResponse, 200);
      }),
    );

    final result = await client.findRecordings(
      startTime: DateTime.utc(2025, 1, 1),
      endTime: DateTime.utc(2025, 1, 2),
    );

    expect(result, isA<CameraSuccess<String>>());
    expect((result as CameraSuccess<String>).value, '1');
  });

  test('getRecordingSearchResults parses RecordingInformation/Track from a real-shaped response', () async {
    final client = OnvifSearchClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetRecordingSearchResults'));
        expect(request.body, contains('<tse:SearchToken>1</tse:SearchToken>'));
        return http.Response(_kGetRecordingSearchResultsResponse, 200);
      }),
    );

    final result = await client.getRecordingSearchResults('1');

    expect(result, isA<CameraSuccess<RecordingSearchResults>>());
    final results = (result as CameraSuccess<RecordingSearchResults>).value;
    expect(results.searchState, 'Completed');
    expect(results.items, hasLength(1));
    final item = results.items.first;
    expect(item.recordingToken, '1735689600');
    expect(item.recordingStatus, 'Stopped');
    expect(item.trackToken, 'VideoTrack_1');
    expect(item.earliestRecording, DateTime.utc(2025, 1, 1));
  });

  test('getEventSearchResults parses Result attributes and Message/Source', () async {
    final client = OnvifSearchClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(_kGetEventSearchResultsResponse, 200)),
    );

    final result = await client.getEventSearchResults('2');

    expect(result, isA<CameraSuccess<EventSearchResults>>());
    final results = (result as CameraSuccess<EventSearchResults>).value;
    expect(results.items, hasLength(1));
    expect(results.items.first.source, '42');
    expect(results.items.first.trackToken, 'VideoTrack_1');
    expect(results.items.first.time, DateTime.utc(2025, 1, 1, 0, 0, 5));
  });

  test('getRecordingSummary parses DataFrom/DataUntil/NumberRecordings', () async {
    final client = OnvifSearchClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(_kGetRecordingSummaryResponse, 200)),
    );

    final result = await client.getRecordingSummary();

    expect(result, isA<CameraSuccess<RecordingSummary>>());
    final summary = (result as CameraSuccess<RecordingSummary>).value;
    expect(summary.numberRecordings, 3);
    expect(summary.dataFrom, DateTime.utc(2025, 1, 1));
    expect(summary.dataUntil, DateTime.utc(2025, 1, 2));
  });

  test('getRecordingSearchResults surfaces a SOAP fault (e.g. unknown SearchToken) as CameraFailure', () async {
    final client = OnvifSearchClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(_kSoapFaultResponse, 200)),
    );

    final result = await client.getRecordingSearchResults('999');

    expect(result, isA<CameraFailure<RecordingSearchResults>>());
    expect((result as CameraFailure<RecordingSearchResults>).reason, 'Invalid SearchToken');
  });

  test('getRecordingSearchResults on an empty ResultList returns an empty list, not a failure', () async {
    const emptyResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope">
<SOAP-ENV:Body>
<tse:GetRecordingSearchResultsResponse>
<tse:ResultList>
</tse:ResultList>
<tse:SearchState>Completed</tse:SearchState>
</tse:GetRecordingSearchResultsResponse>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>''';
    final client = OnvifSearchClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async => http.Response(emptyResponse, 200)),
    );

    final result = await client.getRecordingSearchResults('1');

    expect(result, isA<CameraSuccess<RecordingSearchResults>>());
    expect((result as CameraSuccess<RecordingSearchResults>).value.items, isEmpty);
  });
}
