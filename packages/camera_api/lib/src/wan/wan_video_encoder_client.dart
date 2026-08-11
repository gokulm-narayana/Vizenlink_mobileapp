import 'package:camera_api/camera_api.dart';


/// `FR-NE-100`/`FR-MOB-099`: WAN counterpart to `OnvifVideoEncoderClient` — no WAN transport
/// exists for ONVIF SOAP at all, so this calls the dedicated `NuraeyeAwsIotCommand_*
/// VideoEncoderSettings` actions instead. Structurally matches `OnvifVideoEncoderClient`'s three
/// methods (same params, same `CameraResult<T>` returns) so a call site can pick either without
/// a formal shared interface — same convention `WanDeviceIdentityClient` already established.
///
/// **`getVideoEncoderSettingsOptions` must only ever be called as WAN Set-failure recovery** —
/// direct user requirement, 2026-08-05: options are read over LAN only at onboarding and on this
/// screen's normal load/reload; the only allowed WAN Options read is the one
/// `VideoEncoderSettingsScreen._apply` performs immediately after a WAN `SetVideoEncoderSettings`
/// call itself fails, to refresh the cached bounds. This client itself doesn't enforce that (it's
/// a plain wire-format client, same as every other client in this package) — the call site is
/// what must not violate it.
class WanVideoEncoderClient {
  /// [iotCommandClient] is overridable for tests — defaults to a real [IotCommandClient] for
  /// [thingName].
  WanVideoEncoderClient(String thingName, {IotCommandClient? iotCommandClient})
    : _iot = iotCommandClient ?? IotCommandClient(thingName);

  final IotCommandClient _iot;

  Future<CameraResult<VideoEncoderSettings>> getVideoEncoderSettings({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final output = await _iot.sendCommandWithResponse(IotCommandClient.getVideoEncoderSettings);
      if (output == null) return const CameraTimeout();
      return _parseSettings(output);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  /// Sends every field in [settings] (bitrate/frame_rate/gov_length/quality/encoder_profile,
  /// width/height) — the WAN action itself supports a partial update, but callers always have
  /// every field available already (loaded fully, then locally edited), so there's no reason to
  /// diff and send only the changed subset. Includes `width`/`height` — see
  /// `VideoEncoderSettings`'s own doc for why resolution isn't hardcoded as unsupported here:
  /// whether it's actually editable in the UI depends on how many choices the camera reports via
  /// `Options`, not on an assumption baked into this client.
  Future<CameraResult<VideoEncoderSettings>> setVideoEncoderSettings(
    VideoEncoderSettings settings, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final output = await _iot.sendCommandWithResponse(
        IotCommandClient.setVideoEncoderSettings,
        params: {
          'bitrate': settings.bitrate,
          'frame_rate': settings.frameRate,
          'gov_length': settings.govLength,
          'quality': settings.quality,
          'encoder_profile': settings.encoderProfile,
          'width': settings.width,
          'height': settings.height,
          'encoding': settings.encoding,
          'cbr': settings.cbr,
        },
      );
      if (output == null) return const CameraTimeout();
      // Echoes back the actual applied (post-clamp) values, same as the LAN path.
      return _parseSettings(output);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  /// Parses the `encodings` array — `command 40`'s WAN mirror of the LAN Media2 client's
  /// `GetVideoEncoderConfigurationOptions` parsing (see [OnvifVideoEncoderClient]'s class doc
  /// for why per-encoding, not a single flattened set): H264 and H265 report different
  /// bitrate/quality/GOV/frame-rate ranges, profile lists, and CBR support on this firmware.
  Future<CameraResult<VideoEncoderSettingsOptions>> getVideoEncoderSettingsOptions({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final output = await _iot.sendCommandWithResponse(
        IotCommandClient.getVideoEncoderSettingsOptions,
      );
      if (output == null) return const CameraTimeout();

      final rawEncodings = output['encodings'];
      if (rawEncodings is! List || rawEncodings.isEmpty) {
        return CameraFailure('GetVideoEncoderSettingsOptions response missing encodings: $output');
      }

      final encodings = <EncodingOptions>[];
      for (final raw in rawEncodings) {
        if (raw is! Map) continue;
        final encoding = raw['encoding'];
        final bitrate = raw['bitrate'];
        final quality = raw['quality'];
        final govLength = raw['gov_length'];
        final frameRates = raw['frame_rates'];
        final profiles = raw['encoder_profiles'];
        final resolutions = raw['resolutions'];
        final supportsCbr = raw['supports_cbr'];
        if (encoding is! String ||
            bitrate is! Map ||
            quality is! Map ||
            govLength is! Map ||
            frameRates is! List ||
            frameRates.isEmpty ||
            profiles is! List ||
            resolutions is! List ||
            supportsCbr is! bool) {
          continue;
        }

        final frameRateInts = frameRates.whereType<num>().map((n) => n.toInt()).toList();
        if (frameRateInts.isEmpty) continue;

        final resolutionList = <Resolution>[
          for (final r in resolutions)
            if (r is Map && r['width'] is num && r['height'] is num)
              (width: (r['width'] as num).toInt(), height: (r['height'] as num).toInt()),
        ];

        encodings.add(
          EncodingOptions(
            encoding: encoding,
            bitrateRange: IntRange((bitrate['min'] as num).toInt(), (bitrate['max'] as num).toInt()),
            qualityRange: IntRange((quality['min'] as num).toInt(), (quality['max'] as num).toInt()),
            govLengthRange: IntRange(
              (govLength['min'] as num).toInt(),
              (govLength['max'] as num).toInt(),
            ),
            frameRateRange: IntRange(
              frameRateInts.reduce((a, b) => a < b ? a : b),
              frameRateInts.reduce((a, b) => a > b ? a : b),
            ),
            encoderProfiles: profiles.whereType<String>().toList(),
            resolutions: resolutionList,
            supportsCbr: supportsCbr,
          ),
        );
      }

      if (encodings.isEmpty) {
        return CameraFailure('GetVideoEncoderSettingsOptions response has no usable encodings: $output');
      }
      return CameraSuccess(VideoEncoderSettingsOptions(encodings: encodings));
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  CameraResult<VideoEncoderSettings> _parseSettings(Map<String, dynamic> output) {
    final bitrate = output['bitrate'];
    final frameRate = output['frame_rate'];
    final govLength = output['gov_length'];
    final quality = output['quality'];
    final encoderProfile = output['encoder_profile'];
    final width = output['width'];
    final height = output['height'];
    final encoding = output['encoding'];
    final cbr = output['cbr'];
    if (bitrate is! num ||
        frameRate is! num ||
        govLength is! num ||
        quality is! num ||
        encoderProfile is! String ||
        width is! num ||
        height is! num ||
        encoding is! String ||
        cbr is! bool) {
      return CameraFailure('VideoEncoderSettings response missing fields: $output');
    }
    return CameraSuccess(
      VideoEncoderSettings(
        bitrate: bitrate.toInt(),
        frameRate: frameRate.toInt(),
        govLength: govLength.toInt(),
        quality: quality.toInt(),
        encoderProfile: encoderProfile,
        width: width.toInt(),
        height: height.toInt(),
        encoding: encoding,
        cbr: cbr,
      ),
    );
  }
}
