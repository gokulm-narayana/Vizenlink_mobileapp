import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../camera_connection.dart';
import '../../camera_result.dart';
import '../insecure_camera_http_client.dart';
import 'onvif_device_client.dart';
import 'soap_fault.dart';
import '../wsse_digest.dart';

/// `FR-MOB-099`/`FR-NE-100`: this feature is deliberately scoped to the **high-resolution
/// profile only** (Stream 0, "VideoEncoderCfg_1", per direct user request) — distinct from the
/// pre-existing WAN-only `SetStreamQuality`/`GetStreamQuality` (`FR-NE-065`), which are
/// hardcoded to Stream 1's low-res mobile substream ("VideoEncoderCfg_2").
const kHighResVideoEncoderToken = 'VideoEncoderCfg_1';
const _kMedia2Namespace = 'http://www.onvif.org/ver20/media/wsdl';

/// One resolution choice — `width`/`height` in pixels.
typedef Resolution = ({int width, int height});

/// A plain `int` min/max pair — the `FloatRange`-equivalent for the integer-valued bounds this
/// feature deals with (bitrate/quality/GOV length/frame rate are all whole numbers on this
/// camera, per `onvif_types.h`'s `OnvifVideoEncoderConfigStruct`/`OnvifIntRangeStruct`).
class IntRange {
  const IntRange(this.min, this.max);
  final int min;
  final int max;

  @override
  bool operator ==(Object other) =>
      other is IntRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}

/// One video encoder configuration's currently-applied, user-editable settings. Includes
/// [width]/[height] — **whether resolution is actually editable in the UI depends on how many
/// choices [VideoEncoderSettingsOptions.forEncoding] reports for [encoding], not on an
/// assumption baked in here**.
///
/// **`encoding` (`"H264"`/`"H265"`) and `cbr` (rate-control mode)** — added 2026-08-05, direct
/// user report that the settings screen showed only encoder profile with no codec choice or
/// CBR/VBR control, even though the firmware genuinely supports both per `VideoEncoderCfg_1`
/// (`onvif_user_config.c` defines an H264 *and* an H265 option set for it, and
/// `OnvifVideoEncoderConfigStruct` already carries a `cbr` field with real ONVIF wire support —
/// this client just never surfaced either). Switched from ONVIF Media v1 to **Media2**
/// (`VideoEncoder2Configuration`) to get there: Media v1's response generator
/// (`onvif_media_video_encoder_cfg.c`) only emits `<tt:Encoding>`/the GOV-length+profile block
/// when `encoding == "H264"` (an H265 config's `<tt:Encoding>` is silently omitted from the v1
/// response) and never emits the `ConstantBitRate` attribute for v1 at all — real structural
/// gaps in v1 for this camera, not just a missing client-side field, and per direct confirmation
/// this camera's ONVIF `GetServices`/`GetCapabilities` only actually advertises Media2 to real
/// clients (Media v1 is kept firmware-side for legacy/internal support only). Media2's
/// `VideoEncoder2Configuration` schema has no such gap: `GovLength`/`Profile` are config-level
/// attributes valid for any encoding, and `RateControl2`'s `ConstantBitRate` attribute is always
/// emitted.
class VideoEncoderSettings {
  const VideoEncoderSettings({
    this.token = kHighResVideoEncoderToken,
    required this.bitrate,
    required this.frameRate,
    required this.govLength,
    required this.quality,
    required this.encoderProfile,
    required this.width,
    required this.height,
    required this.encoding,
    required this.cbr,
  });

  final String token;

  /// Kbps.
  final int bitrate;
  final int frameRate;

  /// GOP length (frames between keyframes).
  final int govLength;

  /// `1`-`10` per `onvif_types.h`'s `OnvifIntRangeStruct quality_range` doc comment example.
  final int quality;

  /// e.g. `"High"`, `"Main"`, `"Baseline"` — one of the current [encoding]'s
  /// `EncodingOptions.encoderProfiles`.
  final String encoderProfile;

  final int width;
  final int height;

  /// `"H264"` or `"H265"` — one of `VideoEncoderSettingsOptions.availableEncodings`.
  final String encoding;

  /// `true` = constant bitrate (CBR), `false` = variable bitrate (VBR). Only meaningful/editable
  /// when the current [encoding]'s `EncodingOptions.supportsCbr` is `true`.
  final bool cbr;

  VideoEncoderSettings copyWith({
    int? bitrate,
    int? frameRate,
    int? govLength,
    int? quality,
    String? encoderProfile,
    int? width,
    int? height,
    String? encoding,
    bool? cbr,
  }) => VideoEncoderSettings(
    token: token,
    bitrate: bitrate ?? this.bitrate,
    frameRate: frameRate ?? this.frameRate,
    govLength: govLength ?? this.govLength,
    quality: quality ?? this.quality,
    encoderProfile: encoderProfile ?? this.encoderProfile,
    width: width ?? this.width,
    height: height ?? this.height,
    encoding: encoding ?? this.encoding,
    cbr: cbr ?? this.cbr,
  );

  /// Value equality — lets `SettingCard<VideoEncoderSettings>`'s pending-vs-applied dirty check
  /// compare by content instead of identity, same convention `SpeakerVolume`/`NightVisionStatus`
  /// already establish.
  @override
  bool operator ==(Object other) =>
      other is VideoEncoderSettings &&
      other.token == token &&
      other.bitrate == bitrate &&
      other.frameRate == frameRate &&
      other.govLength == govLength &&
      other.quality == quality &&
      other.encoderProfile == encoderProfile &&
      other.width == width &&
      other.height == height &&
      other.encoding == encoding &&
      other.cbr == cbr;

  @override
  int get hashCode => Object.hash(
    token,
    bitrate,
    frameRate,
    govLength,
    quality,
    encoderProfile,
    width,
    height,
    encoding,
    cbr,
  );
}

/// Valid bounds/choices for one [VideoEncoderSettings.encoding] — bitrate/quality/GOV/frame-rate
/// ranges, profiles, resolutions, and CBR support are all specific to a codec on this firmware
/// (H264 and H265 report different profile lists and CBR support), so these are never flattened
/// into a single shared set — see [VideoEncoderSettingsOptions.forEncoding].
class EncodingOptions {
  const EncodingOptions({
    required this.encoding,
    required this.bitrateRange,
    required this.qualityRange,
    required this.govLengthRange,
    required this.frameRateRange,
    required this.encoderProfiles,
    required this.resolutions,
    required this.supportsCbr,
  });

  final String encoding;
  final IntRange bitrateRange;
  final IntRange qualityRange;
  final IntRange govLengthRange;

  /// LAN (`GetVideoEncoderConfigurationOptions`) only ever reports a min/max *range*, not a
  /// discrete list, even though the underlying config data is a fixed list of allowed values —
  /// the ONVIF response generator itself collapses it. The WAN mirror (`FR-NE-100`) reports a
  /// discrete array server-side but this client reduces it to the same min/max shape, so both
  /// transports produce one consistent type — this firmware's frame-rate options are always a
  /// contiguous run of integers in practice, so nothing is lost in the reduction.
  final IntRange frameRateRange;

  final List<String> encoderProfiles;

  /// Every resolution the camera currently reports as valid for this encoding — **not** assumed
  /// to be exactly one entry. Today this firmware always reports exactly one
  /// (`ONVIF_MAX_VENC_OPTIONS_RESOLUTION_COUNT == 1`), so `resolutions.length <= 1` is the real
  /// UI signal for "show read-only," not a hardcoded rule.
  final List<Resolution> resolutions;

  /// Whether constant bitrate (CBR) is a valid choice for this encoding — when `false`, only
  /// VBR is valid and the CBR/VBR control should be disabled (or hidden), not offered as a
  /// no-op toggle.
  final bool supportsCbr;
}

/// The camera's mask capability envelope, from `GetVideoEncoderConfigurationOptions` — one
/// [EncodingOptions] entry per codec the camera reports as available for `VideoEncoderCfg_1`
/// (today: H264 and H265, `onvif_user_config.c`). The settings screen queries
/// [availableEncodings] to build the codec picker, then [forEncoding] to get the bounds for
/// whichever codec is currently selected — never a single flattened set, since bounds/profiles/
/// CBR support genuinely differ per codec on this firmware.
class VideoEncoderSettingsOptions {
  const VideoEncoderSettingsOptions({required this.encodings});

  final List<EncodingOptions> encodings;

  List<String> get availableEncodings => [
    for (final e in encodings) e.encoding,
  ];

  EncodingOptions? forEncoding(String encoding) {
    for (final e in encodings) {
      if (e.encoding == encoding) return e;
    }
    return null;
  }
}

/// LAN client for `VideoEncoderCfg_1` (Stream 0, high-res) via ONVIF **Media2**
/// (`GetVideoEncoderConfigurations`/`SetVideoEncoderConfiguration`/
/// `GetVideoEncoderConfigurationOptions`) — see [VideoEncoderSettings]'s class doc for why Media2
/// rather than Media v1. Endpoint resolved via `OnvifDeviceClient.getServices()` (real ONVIF
/// service discovery), process-lifetime-cached per host, same convention `MaskClient`/`OsdClient`
/// already established for their own Media2 usage.
class OnvifVideoEncoderClient {
  OnvifVideoEncoderClient(this.connection, {http.Client? httpClient})
    : _http = httpClient ?? createCameraHttpClient(),
      _device = OnvifDeviceClient(connection, httpClient: httpClient);

  final CameraConnection connection;
  final http.Client _http;
  final OnvifDeviceClient _device;

  static final Map<String, Uri> _endpointCacheByHost = {};

  /// Process-lifetime cache, keyed by camera host — same convention as `MaskClient`'s
  /// `_optionsCacheByHost` (added 2026-08-10). The full response already covers every encoding
  /// in one fetch (`VideoEncoderSettingsOptions.encodings`), so caching it whole is safe even
  /// though the UI only shows one encoding's bounds at a time.
  static final Map<String, VideoEncoderSettingsOptions> _optionsCacheByHost =
      {};

  Future<CameraResult<Uri>> _resolveMedia2Endpoint(Duration timeout) async {
    final cached = _endpointCacheByHost[connection.host];
    if (cached != null) return CameraSuccess(cached);

    final servicesResult = await _device.getServices(timeout: timeout);
    switch (servicesResult) {
      case CameraSuccess<List<OnvifServiceEntry>>(:final value):
        final entry = value
            .where((e) => e.namespace == _kMedia2Namespace)
            .firstOrNull;
        if (entry == null) {
          return const CameraFailure(
            'Media2 service not offered by this camera',
          );
        }
        _endpointCacheByHost[connection.host] = entry.xAddr;
        return CameraSuccess(entry.xAddr);
      case CameraFailure(:final reason):
        return CameraFailure(reason);
      case CameraTimeout():
        return const CameraTimeout();
    }
  }

  Future<CameraResult<VideoEncoderSettings>> getVideoEncoderSettings({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<tr2:GetVideoEncoderConfigurations xmlns:tr2="$_kMedia2Namespace">'
      '<tr2:ConfigurationToken>$kHighResVideoEncoderToken</tr2:ConfigurationToken>'
      '</tr2:GetVideoEncoderConfigurations>',
      timeout,
    );
    return bodyResult.map((body) {
      final doc = XmlDocument.parse(body);
      final configEl = doc.findAllElements('Configurations', namespace: '*');
      if (configEl.isEmpty) {
        throw const FormatException(
          'GetVideoEncoderConfigurations response has no Configurations',
        );
      }
      final el = configEl.first;
      String? text(String tag) {
        final e = el.findAllElements(tag, namespace: '*');
        return e.isEmpty ? null : e.first.innerText.trim();
      }

      final rateControlEl = el.findAllElements('RateControl', namespace: '*');
      final cbr =
          rateControlEl.isNotEmpty &&
          rateControlEl.first.getAttribute('ConstantBitRate') == 'true';

      return VideoEncoderSettings(
        bitrate: int.tryParse(text('BitrateLimit') ?? '') ?? 0,
        frameRate: int.tryParse(text('FrameRateLimit') ?? '') ?? 0,
        govLength: int.tryParse(el.getAttribute('GovLength') ?? '') ?? 0,
        quality: int.tryParse(text('Quality') ?? '') ?? 0,
        encoderProfile: el.getAttribute('Profile') ?? '',
        width: int.tryParse(text('Width') ?? '') ?? 0,
        height: int.tryParse(text('Height') ?? '') ?? 0,
        encoding: text('Encoding') ?? 'H264',
        cbr: cbr,
      );
    });
  }

  /// Always sends the full accepted configuration (matching the real ONVIF wire requirement —
  /// `SetVideoEncoderConfiguration` has no partial-update mode over SOAP, unlike the WAN mirror)
  /// — [settings] is expected to already carry every editable field's current value.
  Future<CameraResult<void>> setVideoEncoderSettings(
    VideoEncoderSettings settings, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final bodyResult = await _post(
      '<tr2:SetVideoEncoderConfiguration xmlns:tr2="$_kMedia2Namespace" '
      'xmlns:tt="http://www.onvif.org/ver10/schema">'
      '<tr2:Configuration token="${settings.token}" '
      'GovLength="${settings.govLength}" Profile="${settings.encoderProfile}">'
      '<tt:Encoding>${settings.encoding}</tt:Encoding>'
      '<tt:Resolution>'
      '<tt:Width>${settings.width}</tt:Width>'
      '<tt:Height>${settings.height}</tt:Height>'
      '</tt:Resolution>'
      '<tt:Quality>${settings.quality}</tt:Quality>'
      '<tt:RateControl ConstantBitRate="${settings.cbr}">'
      '<tt:FrameRateLimit>${settings.frameRate}</tt:FrameRateLimit>'
      '<tt:BitrateLimit>${settings.bitrate}</tt:BitrateLimit>'
      '</tt:RateControl>'
      '</tr2:Configuration>'
      '</tr2:SetVideoEncoderConfiguration>',
      timeout,
    );
    return bodyResult.map((_) {});
  }

  /// Cached (process-lifetime, per host — see `_optionsCacheByHost`) after the first successful
  /// fetch — pass `forceRefresh: true` to bypass the cache (a manual, explicit user action; no
  /// normal load/reload should ever do this).
  Future<CameraResult<VideoEncoderSettingsOptions>>
  getVideoEncoderSettingsOptions({
    Duration timeout = const Duration(seconds: 10),
    bool forceRefresh = false,
  }) async {
    final cached = _optionsCacheByHost[connection.host];
    if (cached != null && !forceRefresh) return CameraSuccess(cached);

    final bodyResult = await _post(
      '<tr2:GetVideoEncoderConfigurationOptions xmlns:tr2="$_kMedia2Namespace">'
      '<tr2:ConfigurationToken>$kHighResVideoEncoderToken</tr2:ConfigurationToken>'
      '</tr2:GetVideoEncoderConfigurationOptions>',
      timeout,
    );
    final result = bodyResult.map((body) {
      final doc = XmlDocument.parse(body);
      final encodings = <EncodingOptions>[];

      for (final opt in doc.findAllElements('Options', namespace: '*')) {
        final encodingEl = opt.findAllElements('Encoding', namespace: '*');
        if (encodingEl.isEmpty) continue;
        final encoding = encodingEl.first.innerText.trim();

        IntRange? rangeIn(String tag) {
          final e = opt.findAllElements(tag, namespace: '*');
          if (e.isEmpty) return null;
          final minText = e.first.findAllElements('Min', namespace: '*');
          final maxText = e.first.findAllElements('Max', namespace: '*');
          if (minText.isEmpty || maxText.isEmpty) return null;
          final min = int.tryParse(minText.first.innerText.trim());
          final max = int.tryParse(maxText.first.innerText.trim());
          if (min == null || max == null) return null;
          return IntRange(min, max);
        }

        final bitrateRange = rangeIn('BitrateRange');
        final qualityRange = rangeIn('QualityRange');
        if (bitrateRange == null || qualityRange == null) continue;

        // GovLengthRange/FrameRatesSupported/ProfilesSupported are attributes on <tr2:Options>,
        // not child elements, per Media2's VideoEncoder2ConfigurationOptions schema — matching
        // onvif_media2.c's prvGenerateGetVideoEncoderConfigurationOptionsResponse.
        final govParts = (opt.getAttribute('GovLengthRange') ?? '').split(' ');
        final govLengthRange = govParts.length == 2
            ? IntRange(
                int.tryParse(govParts[0]) ?? 1,
                int.tryParse(govParts[1]) ?? 60,
              )
            : const IntRange(1, 60);

        final frameRateInts = (opt.getAttribute('FrameRatesSupported') ?? '')
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .toList();
        final frameRateRange = frameRateInts.isEmpty
            ? const IntRange(1, 30)
            : IntRange(
                frameRateInts.reduce((a, b) => a < b ? a : b),
                frameRateInts.reduce((a, b) => a > b ? a : b),
              );

        final encoderProfiles = (opt.getAttribute('ProfilesSupported') ?? '')
            .split(' ')
            .where((s) => s.isNotEmpty)
            .toList();

        final resolutions = <Resolution>[];
        for (final resEl in opt.findAllElements(
          'ResolutionsAvailable',
          namespace: '*',
        )) {
          final widthEl = resEl.findAllElements('Width', namespace: '*');
          final heightEl = resEl.findAllElements('Height', namespace: '*');
          final width = widthEl.isEmpty
              ? null
              : int.tryParse(widthEl.first.innerText.trim());
          final height = heightEl.isEmpty
              ? null
              : int.tryParse(heightEl.first.innerText.trim());
          if (width != null && height != null) {
            resolutions.add((width: width, height: height));
          }
        }

        encodings.add(
          EncodingOptions(
            encoding: encoding,
            bitrateRange: bitrateRange,
            qualityRange: qualityRange,
            govLengthRange: govLengthRange,
            frameRateRange: frameRateRange,
            encoderProfiles: encoderProfiles,
            resolutions: resolutions,
            supportsCbr: opt.getAttribute('ConstantBitRateSupported') == 'true',
          ),
        );
      }

      if (encodings.isEmpty) {
        throw const FormatException(
          'GetVideoEncoderConfigurationOptions response has no Options',
        );
      }
      return VideoEncoderSettingsOptions(encodings: encodings);
    });
    if (result case CameraSuccess<VideoEncoderSettingsOptions>(:final value)) {
      _optionsCacheByHost[connection.host] = value;
    }
    return result;
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
            endpoint,
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

  /// Test-only: clears the process-lifetime endpoint cache so test cases sharing a
  /// `CameraConnection.host` don't leak cached state between otherwise-independent tests. Same
  /// convention as `MaskClient.debugClearCaches`/`OsdClient`'s own caches.
  static void debugClearCaches() {
    _endpointCacheByHost.clear();
    _optionsCacheByHost.clear();
  }

  void close() {
    _http.close();
    _device.close();
  }
}

extension _ResultMap<T> on CameraResult<T> {
  CameraResult<R> map<R>(R Function(T value) f) {
    switch (this) {
      case CameraSuccess<T>(:final value):
        try {
          return CameraSuccess<R>(f(value));
        } on FormatException catch (e) {
          return CameraFailure<R>(e.message);
        }
      case CameraFailure(:final reason):
        return CameraFailure<R>(reason);
      case CameraTimeout():
        return CameraTimeout<R>();
    }
  }
}
