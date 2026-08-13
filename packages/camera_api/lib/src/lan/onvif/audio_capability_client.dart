import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../camera_connection.dart';
import '../../camera_result.dart';
import '../insecure_camera_http_client.dart';
import '../wsse_digest.dart';
import 'soap_fault.dart';

/// Whether the camera reports audio hardware at all — presence only, not full configuration.
/// Mirrors the ONVIF `GetAudioSources`/`GetAudioOutputs` presence check `FR-MOB-082` already
/// specifies for the Speaker Volume/Mic Gain controls ("hide the corresponding control entirely
/// rather than showing a disabled control") — the same convention applies to the two-way talk
/// control, since talking through the camera needs its speaker, and hearing a response needs
/// its mic.
class AudioCapability {
  const AudioCapability({
    required this.hasSpeaker,
    required this.hasMicrophone,
  });

  /// `GetAudioOutputs` returned at least one `AudioOutput` — needed for the camera to play the
  /// phone's mic audio (the talk control's minimum requirement).
  final bool hasSpeaker;

  /// `GetAudioSources` returned at least one `AudioSource` — needed for the return-audio leg
  /// (hearing the camera's side). See `Mobile-Android-5`'s DESIGN.md §2 for why this leg is
  /// separately flagged as hardware-unverified even when the source itself is present.
  final bool hasMicrophone;
}

/// LAN-only ONVIF Media client (`/onvif/media_service`, SOAP, WS-UsernameToken digest auth) —
/// today, only the audio-hardware-presence check used to gate the two-way talk control.
class AudioCapabilityClient {
  AudioCapabilityClient(this.connection, {http.Client? httpClient})
    : _http = httpClient ?? createCameraHttpClient();

  final CameraConnection connection;
  final http.Client _http;

  Future<CameraResult<AudioCapability>> getAudioCapability({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final sourcesResult = await _post(
      '<trt:GetAudioSources xmlns:trt="http://www.onvif.org/ver10/media/wsdl"/>',
      timeout,
    );
    final outputsResult = await _post(
      '<trt:GetAudioOutputs xmlns:trt="http://www.onvif.org/ver10/media/wsdl"/>',
      timeout,
    );

    if (sourcesResult is CameraFailure<String>) {
      return CameraFailure(sourcesResult.reason);
    }
    if (sourcesResult is CameraTimeout<String>) return const CameraTimeout();
    if (outputsResult is CameraFailure<String>) {
      return CameraFailure(outputsResult.reason);
    }
    if (outputsResult is CameraTimeout<String>) return const CameraTimeout();

    final sourcesBody = (sourcesResult as CameraSuccess<String>).value;
    final outputsBody = (outputsResult as CameraSuccess<String>).value;

    final hasMicrophone = XmlDocument.parse(
      sourcesBody,
    ).findAllElements('AudioSources', namespace: '*').isNotEmpty;
    final hasSpeaker = XmlDocument.parse(
      outputsBody,
    ).findAllElements('AudioOutputs', namespace: '*').isNotEmpty;

    return CameraSuccess(
      AudioCapability(hasSpeaker: hasSpeaker, hasMicrophone: hasMicrophone),
    );
  }

  Future<CameraResult<String>> _post(String bodyXml, Duration timeout) async {
    final digest = WsseDigest.generate(connection.password);
    final envelope =
        '<?xml version="1.0" encoding="UTF-8"?>'
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
            connection.onvifMediaEndpoint,
            headers: const {
              'Content-Type': 'application/soap+xml; charset=utf-8',
            },
            body: envelope,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return CameraFailure('HTTP ${response.statusCode}: ${response.body}');
      }
      final faultReason = soapFaultReason(response.body);
      if (faultReason != null) {
        return CameraFailure(faultReason);
      }
      return CameraSuccess(response.body);
    } on Exception catch (e) {
      return CameraFailure(e.toString());
    }
  }

  void close() => _http.close();
}
