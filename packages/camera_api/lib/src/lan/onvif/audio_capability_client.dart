import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../camera_connection.dart';
import '../../camera_result.dart';
import '../insecure_camera_http_client.dart';
import '../wsse_digest.dart';
import 'soap_fault.dart';
import 'onvif_device_client.dart';

const _kMedia2Namespace = 'http://www.onvif.org/ver20/media/wsdl';

/// This build's fixed `AudioSourceConfiguration`/`AudioOutputConfiguration` tokens
/// (`onvif_user_config.c`'s `AUDIO_SOURCE_CFG_TOKEN`/`AUDIO_OUTPUT_CFG_TOKEN`). Media2's
/// `GetAudioSourceConfigurations`/`GetAudioOutputConfigurations` take an optional
/// `ConfigurationToken`/`ProfileToken` filter and — per `onvif_media2.c`'s dispatch — return an
/// empty response when neither is given, so this must be passed explicitly, mirroring
/// `SpeakerVolumeClient`/`OsdClient`/`MaskClient`'s own fixed-token convention.
const _kAudioSourceConfigToken = 'AudioSourceCfg_1';
const _kAudioOutputConfigToken = 'AudioOutputCfg_1';

/// Whether the camera reports audio hardware at all — presence only, not full configuration.
/// Mirrors the ONVIF presence check `FR-MOB-082` already specifies for the Speaker Volume/Mic
/// Gain controls ("hide the corresponding control entirely rather than showing a disabled
/// control") — the same convention applies to the two-way talk control, since talking through
/// the camera needs its speaker, and hearing a response needs its mic.
class AudioCapability {
  const AudioCapability({required this.hasSpeaker, required this.hasMicrophone});

  /// `GetAudioOutputConfigurations` returned a non-empty `Configurations` list — needed for the
  /// camera to play the phone's mic audio (the talk control's minimum requirement).
  final bool hasSpeaker;

  /// `GetAudioSourceConfigurations` returned a non-empty `Configurations` list — needed for the
  /// return-audio leg (hearing the camera's side). See `Mobile-Android-5`'s DESIGN.md §2 for why
  /// this leg is separately flagged as hardware-unverified even when the source itself is
  /// present.
  final bool hasMicrophone;
}

/// LAN-only ONVIF **Media2** client (`/onvif/media2_service`, SOAP, WS-UsernameToken digest
/// auth) — today, only the audio-hardware-presence check used to gate the two-way talk control.
///
/// **Migrated off Media v1's `GetAudioSources`/`GetAudioOutputs` 2026-08-12** — this was the one
/// remaining ONVIF client in the package still using Media v1 where every sibling client
/// (`SpeakerVolumeClient`, `OsdClient`, `MaskClient`, `OnvifVideoEncoderClient`) already uses
/// Media2. Confirmed against the firmware source (`onvif/services/media2/onvif_media2.c`'s
/// `GetAudioSourceConfigurations`/`GetAudioOutputConfigurations` dispatch) that an absent
/// configuration on this build already returns an explicit empty response — "No microphone/
/// speaker on this build... — empty response, not a fault" — the exact same presence-check
/// semantics this class already relied on for Media v1, just reached via the configuration list
/// instead of the raw source/output enumeration Media2 doesn't expose. Not yet hardware-verified
/// against Media2 specifically (the original Media v1 version was hardware-verified for
/// `Mobile-Android-5`).
class AudioCapabilityClient {
  AudioCapabilityClient(this.connection, {http.Client? httpClient})
      : _http = httpClient ?? createCameraHttpClient(),
        _device = OnvifDeviceClient(connection, httpClient: httpClient);

  final CameraConnection connection;
  final http.Client _http;
  final OnvifDeviceClient _device;

  /// Process-lifetime cache of the resolved Media2 endpoint, keyed by camera host — same
  /// convention as `OsdClient`/`MaskClient`/`SpeakerVolumeClient`'s `_endpointCacheByHost`.
  static final Map<String, Uri> _endpointCacheByHost = {};

  /// Test-only: clears the process-lifetime cache so test cases sharing a
  /// `CameraConnection.host` don't leak cached state between otherwise-independent tests.
  static void debugClearCaches() {
    _endpointCacheByHost.clear();
  }

  Future<CameraResult<Uri>> _resolveMedia2Endpoint(Duration timeout) async {
    final cached = _endpointCacheByHost[connection.host];
    if (cached != null) return CameraSuccess(cached);

    final servicesResult = await _device.getServices(timeout: timeout);
    switch (servicesResult) {
      case CameraSuccess<List<OnvifServiceEntry>>(:final value):
        final entry = value.where((e) => e.namespace == _kMedia2Namespace).firstOrNull;
        if (entry == null) {
          return const CameraFailure('Media2 service not offered by this camera');
        }
        _endpointCacheByHost[connection.host] = entry.xAddr;
        return CameraSuccess(entry.xAddr);
      case CameraFailure(:final reason):
        return CameraFailure(reason);
      case CameraTimeout():
        return const CameraTimeout();
    }
  }

  Future<CameraResult<AudioCapability>> getAudioCapability({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final sourcesResult = await _post(
      '<tr2:GetAudioSourceConfigurations xmlns:tr2="$_kMedia2Namespace">'
      '<tr2:ConfigurationToken>$_kAudioSourceConfigToken</tr2:ConfigurationToken>'
      '</tr2:GetAudioSourceConfigurations>',
      timeout,
    );
    if (sourcesResult is CameraFailure<String>) return CameraFailure(sourcesResult.reason);
    if (sourcesResult is CameraTimeout<String>) return const CameraTimeout();

    final outputsResult = await _post(
      '<tr2:GetAudioOutputConfigurations xmlns:tr2="$_kMedia2Namespace">'
      '<tr2:ConfigurationToken>$_kAudioOutputConfigToken</tr2:ConfigurationToken>'
      '</tr2:GetAudioOutputConfigurations>',
      timeout,
    );
    if (outputsResult is CameraFailure<String>) return CameraFailure(outputsResult.reason);
    if (outputsResult is CameraTimeout<String>) return const CameraTimeout();

    final sourcesBody = (sourcesResult as CameraSuccess<String>).value;
    final outputsBody = (outputsResult as CameraSuccess<String>).value;

    final hasMicrophone = XmlDocument.parse(sourcesBody)
        .findAllElements('Configurations', namespace: '*')
        .isNotEmpty;
    final hasSpeaker = XmlDocument.parse(outputsBody)
        .findAllElements('Configurations', namespace: '*')
        .isNotEmpty;

    return CameraSuccess(AudioCapability(hasSpeaker: hasSpeaker, hasMicrophone: hasMicrophone));
  }

  Future<CameraResult<String>> _post(String bodyXml, Duration timeout) async {
    final endpointResult = await _resolveMedia2Endpoint(timeout);
    final Uri endpoint;
    switch (endpointResult) {
      case CameraSuccess<Uri>(:final value):
        endpoint = value;
      case CameraFailure(:final reason):
        return CameraFailure(reason);
      case CameraTimeout():
        return const CameraTimeout();
    }

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
            endpoint,
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
    } on TimeoutException {
      return const CameraTimeout();
    } on Exception catch (e) {
      return CameraFailure(e.toString());
    }
  }

  void close() {
    _http.close();
    _device.close();
  }
}
