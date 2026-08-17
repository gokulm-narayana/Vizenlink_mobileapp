import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// Camera capability discovery (`FR-NE-092`) — a single, growing NuraEye action rather than one
/// new action per capability (deliberate 2026-07-31 design choice; the existing per-feature
/// capability actions, `GetDeterrenceCapabilities`/`GetLocalStorageStatus`, keep their own
/// already-shipped contracts unchanged — this is the pattern for *new* capability flags only).
///
/// Mirrors the firmware's two-tier build structure (`FR-CF-137`): [wanCommandCapable] reflects
/// AWS IoT/MQTT itself (`CONFIG_AWS_ENABLED`); [wanLiveViewCapable] additionally requires
/// `REMOTE_LIVE_STREAMING` — a build can have AWS commands without KVS, so the former can be
/// `true` while the latter is `false`. Both also require this specific device to actually have
/// real AWS IoT credentials provisioned, not just build-time support.
class CameraCapabilities {
  const CameraCapabilities({
    required this.wanCommandCapable,
    required this.wanLiveViewCapable,
    required this.supportedEventTypes,
    required this.supportedEventDeterrenceOptions,
    required this.sirenCapable,
    required this.spotlightCapable,
    required this.warningCapable,
  });

  /// Whether this device can receive AWS IoT/MQTT commands at all (deterrence, settings sync,
  /// WAN control) — independent of KVS. Not yet consumed anywhere in the app (no WAN command
  /// feature currently gates on it), but exposed for future use as WAN command features adopt
  /// capability checks the way `LiveViewController` already does for [wanLiveViewCapable].
  final bool wanCommandCapable;

  final bool wanLiveViewCapable;

  /// `FR-CF-143`/`FR-NE-111`: the alert event strings this specific camera build actually
  /// generates (e.g. `"VideoModeChanged"`, `"PrivacyModeChanged"`, `"PersonDetected"`) — the
  /// same identifiers used as the alert JSON's own `"event"` field and as
  /// `EventPreferencesClient`'s enable/disable keys. `EventSettingsScreen` builds its toggle
  /// list from this list only, never a hardcoded one, so a future firmware build that adds a
  /// real alert type needs no app update to show it. Empty on firmware too old to report it
  /// (missing/wrong-typed field is not an error — treated as "no alert types known").
  final List<String> supportedEventTypes;

  /// `FR-CF-144`/`FR-NE-112`: for each detection-type event this build supports auto-response
  /// actions on (only `"PersonDetected"` today), the response actions eligible for it — a
  /// subset of `siren`/`spotlight`/`warning`/`mobile_alert`, already intersected with this SKU's
  /// hardware capability. State-change event types (`VideoModeChanged`/`PrivacyModeChanged`)
  /// never appear as keys here, even though they appear in [supportedEventTypes] — deterrence
  /// response actions are deliberately scoped to detection events only. `EventSettingsScreen`
  /// builds its response-action multi-select from this map only, never a hardcoded action list.
  /// Empty on firmware too old to report it.
  final Map<String, List<String>> supportedEventDeterrenceOptions;

  /// `FR-CF-124`/`FR-CF-127`/`FR-CF-132` hardware presence — same fields
  /// `GetDeterrenceCapabilities` (`FR-NE-082`) already reports on its own dedicated endpoint,
  /// mirrored onto this one too (`FEAT-236`) so `EventSettingsScreen`'s Deterrence duration
  /// section and Live View's manual trigger controls can gate on the same already-fetched
  /// response other capability-driven UI already uses, instead of a second round trip. Default
  /// `false` on firmware too old to report them.
  final bool sirenCapable;
  final bool spotlightCapable;
  final bool warningCapable;
}

/// Dispatches over both LAN and WAN on the firmware side (`FR-NE-092`, matching the
/// `GetDeterrenceCapabilities`/`GetLocalStorageStatus` convention), but this client only wraps
/// the LAN path — queried once at onboarding (`add_camera_credentials_screen.dart`, camera is
/// physically at hand) and cached, per the current app's only real use case. No WAN client
/// exists yet; add one (mirroring `IotCommandClient`'s Lambda-relay shape) if/when a feature
/// actually needs to re-check capabilities without being on LAN.
class CapabilitiesClient {
  CapabilitiesClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<CameraCapabilities>> getCapabilities({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetCapabilities', timeout: timeout);

    return switch (result) {
      CameraSuccess(:final value) => () {
          final wanCommandCapable = value['wan_command_capable'];
          final wanLiveViewCapable = value['wan_live_view_capable'];
          if (wanCommandCapable is! bool || wanLiveViewCapable is! bool) {
            return CameraFailure<CameraCapabilities>(
              'GetCapabilities response missing wan_command_capable/wan_live_view_capable: $value',
            );
          }
          final rawEventTypes = value['supported_event_types'];
          final supportedEventTypes = rawEventTypes is List
              ? rawEventTypes.whereType<String>().toList()
              : const <String>[];
          final rawDeterrenceOptions = value['supported_event_deterrence_options'];
          final supportedEventDeterrenceOptions = rawDeterrenceOptions is Map
              ? rawDeterrenceOptions.map(
                  (key, actions) => MapEntry(
                    key.toString(),
                    actions is List ? actions.whereType<String>().toList() : const <String>[],
                  ),
                )
              : const <String, List<String>>{};
          return CameraSuccess<CameraCapabilities>(
            CameraCapabilities(
              wanCommandCapable: wanCommandCapable,
              wanLiveViewCapable: wanLiveViewCapable,
              supportedEventTypes: supportedEventTypes,
              supportedEventDeterrenceOptions: supportedEventDeterrenceOptions,
              sirenCapable: value['siren_capable'] == true,
              spotlightCapable: value['spotlight_capable'] == true,
              warningCapable: value['warning_capable'] == true,
            ),
          );
        }(),
      CameraFailure(:final reason) => CameraFailure<CameraCapabilities>(reason),
      CameraTimeout() => const CameraTimeout<CameraCapabilities>(),
    };
  }
}
