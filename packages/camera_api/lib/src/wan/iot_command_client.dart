import 'dart:convert';

import 'package:http/http.dart' as http;

import 'wan_auth.dart';

/// AWS IoT command channel — `mobile-app-android-3-video-image-pipeline/DESIGN.md` §7 item 1.
///
/// **2026-07-31 rewrite**: this used to call AWS IoT directly (SigV4-signed HTTPS publish +
/// MQTT-over-WSS) using this app's own Cognito Identity Pool-federated credentials. Real-device
/// testing found AWS rejects those credentials for `iot-data:Publish`/MQTT-over-WSS with
/// `ForbiddenException`, regardless of IAM policy — isolated by testing the identical role+policy
/// with root/plain-IAM credentials (succeeded) vs. the Cognito-federated session (failed); see
/// `kb/raw/2026-07-31-fix-iot-command-lambda-relay.md`. Same failure class already documented for
/// KVS in `kb/wiki/kvs-viewer-read-permissions-cognito-role.md`. Now goes through
/// `cloud_backend/kvs_playback_lambda` (extended, not a second Lambda) instead — same Cognito ID
/// token this app already uses everywhere else, no AWS credentials needed client-side at all for
/// this path anymore.
///
/// **Moved into `camera_api` 2026-08-11** — [idTokenProvider] and the relay URL used to default
/// to this app's own `AuthController`/`AwsConfig`; now they default to [WanAuth]'s static hooks
/// instead, so this package never imports anything app-specific. Set `WanAuth.idTokenProvider`/
/// `WanAuth.kvsPlaybackLambdaUrl` once at app startup — see [WanAuth]'s own doc.
class IotCommandClient {
  /// [idTokenProvider] and [httpClient] are overridable for tests — default to
  /// [WanAuth.idTokenProvider] / `http.Client()`.
  IotCommandClient(
    this.thingName, {
    String? Function()? idTokenProvider,
    http.Client? httpClient,
  }) : _idTokenProvider = idTokenProvider ?? WanAuth.idTokenProvider ?? (() => null),
       _http = httpClient ?? http.Client();

  final String thingName;
  final String? Function() _idTokenProvider;
  final http.Client _http;

  // Renamed 2026-08-06 from startLiveStream/stopLiveStream/getStreamStatus — numeric command
  // values unchanged, symbol names only (unified with the new LAN CloudStreaming actions).
  static const startCloudStreaming = 0;
  static const stopCloudStreaming = 1;
  static const getVideoMode = 2;
  static const setVideoMode = 3;
  static const getCloudStreamingStatus = 4;
  static const getWDRMode = 7;
  static const setWDRMode = 8;
  static const setNightVisionType = 9;
  static const getNightVisionType = 10;

  /// `FR-NE-039`: `WanMirrorFlipClient`'s commands — hardware-verified in firmware since
  /// 2026-07-27 but never wired into the app until 2026-08-06.
  static const setMirrorFlip = 11;
  static const getMirrorFlip = 12;
  static const getImageSettings = 13;
  static const setImageSettings = 14;
  static const getImageSettingsOptions = 15;

  /// `FR-NE-076`: read-only factory-default imaging values (`FR-MOB-075`'s "Reset to Default"
  /// source) — distinct from [getImageSettings], which returns the *currently-applied* values.
  static const getImageDefaults = 16;

  /// `FR-NE-078` (NF12): audio recording on/off — implemented and hardware-verified in firmware
  /// since 2026-07-28 (`AUD-MQTT-01/02/03`, `TEST.md` §5.44), but never wired into the app —
  /// `WanAudioVolumeClient` incorrectly documented this as "LAN-only, no WAN mirror" until this
  /// gap was found 2026-08-11.
  static const setAudioRecording = 17;
  static const getAudioRecording = 18;

  /// `FR-NE-085`/`FR-NE-086` (NF14): speaker volume / microphone gain — implemented and
  /// hardware-verified in firmware since 2026-07-28 but never wired into the app until now
  /// (`AudioSettingsScreen` was LAN-only). Plain 0-100 percentages, no ONVIF/camera-capability
  /// backing, so no `Get*Options` counterpart is needed — see
  /// `.claude/rules/camera-firmware.md` § "NuraEye WAN service mirrors every ONVIF Options call".
  static const setSpeakerVolume = 23;
  static const getSpeakerVolume = 24;
  static const setMicGain = 25;
  static const getMicGain = 26;

  /// `FR-NE-093`/`FR-CF-138`: Full/Zone/None privacy mode — implemented in firmware, never wired
  /// into the app until now (`_PrivacyModeCard` was LAN-only).
  static const setPrivacyMode = 30;
  static const getPrivacyMode = 31;

  /// `FR-NE-106`: Get-side WAN mirror of `setCameraName`(32)/`setCameraLocation`(33)/
  /// `setTimeZone`(34) — added 2026-08-10 to close the one remaining Force-WAN gap that needed
  /// a firmware change (`CameraInfoScreen`'s Name/Location/Time Zone cards previously always
  /// read via LAN ONVIF regardless of `isWan`, since no WAN Get existed at all). One combined
  /// command, not three — see its firmware-side doc in `nuraeye_types.h`.
  static const getDeviceIdentity = 49;

  /// `FR-NE-107`: WAN mirror of `AudioVolumeClient`'s `playTestSound`/`stopTestSound`/
  /// `isTestSoundPlaying` — added 2026-08-11, direct user instruction reversing the earlier
  /// LAN-only scoping decision.
  static const playTestSound = 50;
  static const stopTestSound = 51;
  static const getTestSoundStatus = 52;

  /// `FR-NE-099`: WAN mirrors for camera name/location/timezone (ONVIF `SetScopes`/
  /// `SetSystemDateAndTime`, previously LAN-only) and the camera's own local device-account
  /// password (ONVIF `SetUser`) — see `nuraeye_types.h`'s `NuraeyeAwsIotCommandEnum`.
  static const setCameraName = 32;
  static const setCameraLocation = 33;
  static const setTimeZone = 34;
  static const setUserPassword = 35;

  /// `FR-NE-100`: high-resolution-profile (Stream 0) video encoder settings — distinct from the
  /// pre-existing WAN-only `SetStreamQuality`/`GetStreamQuality` (command values 5/6, firmware
  /// `nuraeye.c` only, no Dart client), which target Stream 1's low-res mobile substream.
  static const getVideoEncoderSettings = 36;
  static const setVideoEncoderSettings = 37;
  static const getVideoEncoderSettingsOptions = 38;

  /// Options-parity audit (`kb/raw/2026-08-05-code-options-parity-rule-audit.md`),
  /// `.claude/rules/mobile-app-screen-conventions.md` § "LAN/WAN transport selection for settings screens" item 6.
  static const getStreamQualityOptions = 39;
  static const getImagingSettingsOptions = 40;
  static const getMaskConfigs = 41;
  static const setMaskConfig = 42;
  static const deleteMaskConfig = 43;
  static const getMaskOptions = 44;
  static const getOsdConfigs = 45;
  static const setOsdConfig = 46;
  static const getOsdOptions = 47;
  static const deleteOsdConfig = 48;

  /// `FR-NE-108`: end-to-end-encrypted, non-persisted WAN reference-snapshot preview — distinct
  /// from the persisted cloud-snapshot mechanism (`FR-NE-061`). See `WanPreviewSnapshotClient`.
  static const getPreviewSnapshot = 53;

  /// `FR-NE-109`: anti-flicker/power-line-frequency mode — no ONVIF-standard element (checked
  /// against the live schema), NuraEye-only on both transports, same shape as
  /// `getMirrorFlip`/`setMirrorFlip` above.
  static const getAntiFlickerMode = 54;
  static const setAntiFlickerMode = 55;

  /// `FR-NE-110`: `SystemReboot`/`SetSystemFactoryDefault` are real, standard ONVIF Device
  /// service actions with a full LAN path (`OnvifDeviceClient.reboot`/`factoryReset`) — these
  /// exist purely because ONVIF SOAP has no WAN transport in this stack, same reasoning as
  /// `setCameraName`/`getDeviceIdentity` above. See `WanDeviceIdentityClient.reboot`/
  /// `factoryReset`.
  static const reboot = 56;
  static const factoryReset = 57;

  /// `FR-CF-143`/`FR-NE-111`: per-event-type enable/disable — WAN mirror of the LAN
  /// `GetEventPreferences`/`SetEventPreferences` REST resource. No WAN "supported types"
  /// command — that list is a LAN-only `GetCapabilities` field, per the established
  /// Options/capability-reads-are-LAN-only convention. See `WanEventPreferencesClient`.
  static const getEventPreferences = 58;
  static const setEventPreferences = 59;

  /// `FR-CF-144`/`FR-NE-112`: per-detection-event response-action selection — WAN mirror of the
  /// LAN `GetEventResponseActions`/`SetEventResponseActions` REST resource. No WAN "supported
  /// deterrence options" command — that map is a LAN-only `GetCapabilities` field
  /// (`supportedEventDeterrenceOptions`), same convention. See `WanEventResponseActionsClient`.
  static const getEventResponseActions = 60;
  static const setEventResponseActions = 61;

  /// `FR-NE-082`/`083`: manual deterrence trigger — WAN mirror of the LAN `/nuraeye/deterrence`
  /// REST resource. No `duration_seconds` param (`FEAT-236`, 2026-08-14) — the camera applies
  /// its own persisted, per-action duration instead, see [getDeterrenceDurations]/
  /// [setDeterrenceDurations] below. No WAN "capabilities" command — `siren_capable`/
  /// `spotlight_capable`/`warning_capable` are a LAN-only `GetCapabilities` field, same
  /// Options/capability-reads-are-LAN-only convention as event preferences above. See
  /// `WanDeterrenceClient`.
  static const activateDeterrence = 20;
  static const deactivateDeterrence = 21;
  static const getDeterrenceStatus = 22;

  /// `FR-NE-113`: persisted, per-action auto-stop duration — WAN mirror of the LAN
  /// `GetDeterrenceDurations`/`SetDeterrenceDurations` REST resource (`FEAT-236`, 2026-08-14).
  /// Shared by both this manual trigger and the camera's own automatic detection response
  /// (`FR-CF-144`) — one configured duration per action, not per-trigger-path.
  static const getDeterrenceDurations = 62;
  static const setDeterrenceDurations = 63;

  /// Camera-reported min/max range for each duration/count key (`FEAT-236`, 2026-08-15) — WAN
  /// mirror of the LAN `GET /nuraeye/deterrence/durations/options` REST resource.
  static const getDeterrenceDurationOptions = 64;

  /// [isRetry] is internal — set by the one-shot retry below, never pass it explicitly.
  ///
  /// **One-shot retry on a Lambda-side timeout (HTTP 504), added 2026-08-08**: confirmed via
  /// direct testing (`GetMirrorFlip` read-back immediately after a reported app-side timeout)
  /// that the camera routinely applies a `Set*` command correctly even when this relay reports
  /// 504 — the command/response round trip is real, it's the *reply* that occasionally misses
  /// `_publish_and_wait()`'s ~12s wait window inside the Lambda (each invocation opens a brand
  /// new MQTT-over-WSS session, so this is transient session/subscribe jitter, not a stuck
  /// camera). ~5% observed failure rate across repeated `Set`/`Get` pairs in manual testing, not
  /// reproducible on demand — a fresh Lambda invocation is a real second chance, not a repeat of
  /// the same failure, so one retry is worth it before surfacing an error to the user. Every
  /// `Wan*Client` gets this for free since they all route through this method. A genuine camera-
  /// side failure (502, `status != "ok"`) is a different, non-retried case — only 504 (no reply
  /// at all) is worth retrying.
  Future<Map<String, dynamic>> _post(Map<String, dynamic> body, {bool isRetry = false}) async {
    final idToken = _idTokenProvider();
    if (idToken == null) {
      throw StateError('IotCommandClient called while unauthenticated');
    }
    // Empty string (not yet set) parses to a relative empty Uri — matches the pre-move
    // `AwsConfig.kvsPlaybackLambdaUrl` default exactly (`String.fromEnvironment` with no
    // `--dart-define` supplied), so this introduces no new failure mode.
    final response = await _http.post(
      Uri.parse(WanAuth.kvsPlaybackLambdaUrl ?? ''),
      headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 504 && !isRetry) {
      return _post(body, isRetry: true);
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(
        decoded['error'] as String? ?? 'IoT command relay failed (${response.statusCode})',
      );
    }
    return decoded;
  }

  /// `StartCloudStreaming`/`StopCloudStreaming` — fire-and-forget, no `request_id` (older command
  /// shape, predates `FR-NE-053`'s request/response pattern — matches the reference exactly).
  Future<void> _publish(int command) => _post({
    'action': 'publishCommand',
    'thingName': thingName,
    'command': command,
  });

  Future<void> sendStartCloudStreaming() => _publish(startCloudStreaming);

  Future<void> sendStopCloudStreaming() => _publish(stopCloudStreaming);

  /// Generic relay for any `NuraeyeAwsIotCommand` that replies on the response topic
  /// (`nuraeye.c`'s `prvPublishMqttResponse()`) — added for `FR-MOB-068` (Night Vision Type over
  /// WAN, `getNightVisionType`/`setNightVisionType` above) but not specific to it. Used for
  /// `GetCloudStreamingStatus` (`FR-NE-068`) too — a dedicated `getCloudStreamingStatus` Lambda
  /// action used to exist for that specifically, **removed 2026-08-06** per direct user question
  /// ("why does the Lambda hardcode getStreamStatus — shouldn't it be independent of the camera
  /// firmware?"): the Lambda has no business knowing what any particular command number means,
  /// only the app and firmware need to agree on that (`nuraeye_types.h`'s
  /// `NuraeyeAwsIotCommandEnum`), so this generic path is now the only request/response relay.
  /// The Lambda does the full publish + MQTT-over-WSS subscribe/wait server-side (it has the same
  /// problem this client used to have, minus the Cognito-federation rejection, since it runs
  /// under a plain execution role) and returns the `output` object directly, or `null` on a
  /// server-side timeout (camera didn't respond).
  /// [timeoutSeconds], if given, overrides the Lambda relay's default ~12s wait for the
  /// camera's reply — for a command known to legitimately take longer (e.g.
  /// [getPreviewSnapshot]'s on-device capture + RSA-2048 encrypt), not a general escape hatch.
  /// Server-side clamped to 25s regardless of what's passed.
  Future<Map<String, dynamic>?> sendCommandWithResponse(
    int command, {
    Map<String, dynamic>? params,
    double? timeoutSeconds,
  }) async {
    final result = await _post({
      'action': 'commandWithResponse',
      'thingName': thingName,
      'command': command,
      'params': ?params,
      'timeoutSeconds': ?timeoutSeconds,
    });
    return result['output'] as Map<String, dynamic>?;
  }
}
