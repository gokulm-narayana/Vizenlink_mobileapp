import 'package:test/test.dart';
import 'package:xml/xml.dart';

/// Independent check (mirrors `nuraeye_digest_test.dart`'s philosophy — verify the wire-format
/// assumption against a known sample, not just re-exercise the implementation) that a
/// `ProbeMatches` response in the exact shape `onvif_discovery.c`'s
/// `prvGenerateProbeMatchesResponse()` produces parses the way `WsDiscoveryClient` assumes:
/// namespace-agnostic `XAddrs` lookup, first `http://`/`https://` token wins.
void main() {
  test('XAddrs extraction matches the real firmware ProbeMatches shape', () {
    const sample = '<?xml version="1.0" encoding="UTF-8"?>'
        '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" '
        'xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing" '
        'xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" '
        'xmlns:tdn="http://www.onvif.org/ver10/network/wsdl">'
        '<s:Header>'
        '<a:MessageID>uuid:abc</a:MessageID>'
        '<a:RelatesTo>uuid:def</a:RelatesTo>'
        '<a:To s:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</a:To>'
        '<a:Action s:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches</a:Action>'
        '<d:AppSequence InstanceId="0" MessageNumber="1"/>'
        '</s:Header>'
        '<s:Body><d:ProbeMatches><d:ProbeMatch>'
        '<a:EndpointReference><a:Address>urn:uuid:cam-1</a:Address></a:EndpointReference>'
        '<d:Types>tdn:NetworkVideoTransmitter</d:Types>'
        '<d:Scopes>onvif://www.onvif.org/type/video_encoder</d:Scopes>'
        '<d:XAddrs>http://192.168.1.42:80/onvif/device_service</d:XAddrs>'
        '<d:MetadataVersion>1</d:MetadataVersion>'
        '</d:ProbeMatch></d:ProbeMatches></s:Body></s:Envelope>';

    final doc = XmlDocument.parse(sample);
    final xAddrsEl = doc.findAllElements('XAddrs', namespace: '*');
    expect(xAddrsEl, isNotEmpty);

    final firstAddr = xAddrsEl.first.innerText
        .trim()
        .split(RegExp(r'\s+'))
        .firstWhere((a) => a.startsWith('http://') || a.startsWith('https://'));
    final uri = Uri.parse(firstAddr);

    expect(uri.host, '192.168.1.42');
    expect(uri.port, 80);
    expect(uri.scheme, 'http');
  });
}
