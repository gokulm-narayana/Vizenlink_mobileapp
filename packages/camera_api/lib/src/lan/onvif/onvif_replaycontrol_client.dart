import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../camera_connection.dart';
import '../../camera_result.dart';
import '../insecure_camera_http_client.dart';
import '../wsse_digest.dart';
import 'soap_fault.dart';

/// `GetServiceCapabilities` response (`trp:Capabilities`) — `ReversePlayback`/`RTP_RTSP_TCP`
/// are XML attributes on the `<trp:Capabilities>` element itself, while
/// `SessionTimeoutRange` is a child element (`onvif_replaycontrol.c`'s
/// `prvGenerateGetServiceCapabilitiesResponse()` uses `nexml_openTag` with attributes, then
/// writes the child, then closes — unlike Recording/Search's capabilities, which are fully
/// self-closed attribute-only tags).
class ReplayServiceCapabilities {
  const ReplayServiceCapabilities({
    required this.reversePlayback,
    required this.rtpRtspTcp,
    required this.sessionTimeoutSeconds,
  });

  final bool reversePlayback;

  /// Always `true` on this device — `module_rtsps.c`'s playback listener is TCP-interleaved
  /// only, matching live view (`onvif_replaycontrol.c`'s own comment).
  final bool rtpRtspTcp;

  /// The real ONVIF `trp:SessionTimeoutRange` is a `tt:FloatRange` (min/max pair) per the
  /// replay.wsdl — this firmware reports a single fixed value as plain integer seconds text
  /// (`snprintf(..., "%d", ...)`, not an ISO-8601 duration and not a min/max pair), so this
  /// client exposes it as one `int` rather than a min/max range. Flagged as a real,
  /// firmware-confirmed deviation from the strict WSDL shape, not a client-side guess.
  final int? sessionTimeoutSeconds;
}

/// LAN-only ONVIF Replay Control client (`/onvif/replay`, SOAP, WS-UsernameToken digest auth)
/// — Profile G's playback-URI half (`FR-OV-082`). **Client-only for now**, same scope note as
/// `OnvifRecordingClient`/`OnvifSearchClient` — not wired into any screen, parallel to the
/// existing REST-based `ClipPlaybackScreen`.
///
/// [getReplayUri] returns the RTSP(S) URI as plain data only — this client does **not** open an
/// RTSP connection or play back any video; a future consumer (not built in this pass) would hand
/// the returned URI to something like `video_player`. There is no seek/time-offset parameter:
/// the real ONVIF `GetReplayUri` request supports an optional playback-speed/time hint via the
/// `Range` header at the RTSP layer, not inside the SOAP body — and `onvif_replaycontrol.c`'s
/// `GetReplayUri` handler only ever reads `RecordingToken` from the request XML (confirmed by
/// reading the handler directly, not inferred), so there is nothing for a `seekTo` parameter to
/// carry on this call. Seeking, if ever added, would be a `Range: clock=...` header on the RTSP
/// `PLAY` request against the returned URI — out of scope for this client, which stops at
/// returning the URI.
class OnvifReplayControlClient {
  OnvifReplayControlClient(this.connection, {http.Client? httpClient})
      : _http = httpClient ?? createCameraHttpClient();

  final CameraConnection connection;
  final http.Client _http;

  Future<CameraResult<ReplayServiceCapabilities>> getServiceCapabilities({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<trp:GetServiceCapabilities xmlns:trp="http://www.onvif.org/ver10/replay/wsdl"/>',
      timeout,
    );
    return bodyResult.map((body) {
      final doc = XmlDocument.parse(body);
      final el = doc.findAllElements('Capabilities', namespace: '*');
      bool attrBool(String name) =>
          el.isNotEmpty && el.first.getAttribute(name) == 'true';
      final timeoutText =
          el.isEmpty ? null : _text(el.first, 'SessionTimeoutRange');
      return ReplayServiceCapabilities(
        reversePlayback: attrBool('ReversePlayback'),
        rtpRtspTcp: attrBool('RTP_RTSP_TCP'),
        sessionTimeoutSeconds: timeoutText == null ? null : int.tryParse(timeoutText),
      );
    });
  }

  /// Resolves [recordingToken] (the same UTC epoch-start decimal identity
  /// `OnvifRecordingClient`/`OnvifSearchClient` use) to a playable `rtsp://`/`rtsps://` URI on
  /// this device's dedicated playback listener (`PLAYBACK_RTSPS_PORT`, separate from the
  /// live-view RTSP/tunnel path — see `onvif_replaycontrol.c`'s file comment). Fails with
  /// `CameraFailure` (not a generic error) when the token doesn't resolve to an existing clip —
  /// the firmware maps that specific case to `ter:NoConfig` (`OnvifError_NoSuchConfiguration`),
  /// which surfaces through [soapFaultReason] like any other SOAP fault.
  Future<CameraResult<String>> getReplayUri(
    String recordingToken, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<trp:GetReplayUri xmlns:trp="http://www.onvif.org/ver10/replay/wsdl">'
      '<trp:RecordingToken>$recordingToken</trp:RecordingToken>'
      '</trp:GetReplayUri>',
      timeout,
    );
    return bodyResult.map((body) {
      final doc = XmlDocument.parse(body);
      return _docText(doc, 'Uri') ?? '';
    });
  }

  String? _text(XmlElement parent, String tag) {
    final el = parent.findAllElements(tag, namespace: '*');
    return el.isEmpty ? null : el.first.innerText.trim();
  }

  String? _docText(XmlDocument doc, String tag) {
    final el = doc.findAllElements(tag, namespace: '*');
    return el.isEmpty ? null : el.first.innerText.trim();
  }

  Future<CameraResult<String>> _post(String bodyXml, Duration timeout) async {
    final digest = WsseDigest.generate(connection.password);
    final envelope = '<?xml version="1.0" encoding="UTF-8"?>'
        '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
        '<s:Header>'
        '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
        '<wsse:UsernameToken>'
        '<wsse:Username>${connection.username}</wsse:Username>'
        '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">'
        '${digest.digestBase64}</wsse:Password>'
        '<wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">'
        '${digest.nonceBase64}</wsse:Nonce>'
        '<wsu:Created xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">'
        '${digest.createdIso}</wsu:Created>'
        '</wsse:UsernameToken>'
        '</wsse:Security>'
        '</s:Header>'
        '<s:Body>$bodyXml</s:Body>'
        '</s:Envelope>';

    try {
      final response = await _http
          .post(
            connection.onvifReplayEndpoint,
            headers: const {'Content-Type': 'application/soap+xml; charset=utf-8'},
            body: envelope,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return CameraFailure('HTTP ${response.statusCode}: ${response.body}');
      }

      final faultReason = soapFaultReason(response.body);
      if (faultReason != null) return CameraFailure(faultReason);

      return CameraSuccess(response.body);
    } on Exception catch (e) {
      return CameraFailure(e.toString());
    }
  }

  void close() => _http.close();
}

extension _ResultMap<T> on CameraResult<T> {
  CameraResult<R> map<R>(R Function(T value) f) {
    return switch (this) {
      CameraSuccess(:final value) => CameraSuccess<R>(f(value)),
      CameraFailure(:final reason) => CameraFailure<R>(reason),
      CameraTimeout() => CameraTimeout<R>(),
    };
  }
}
