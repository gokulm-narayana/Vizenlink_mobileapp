import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// `ActivateDeterrence`/`DeactivateDeterrence`/`GetDeterrenceStatus` (`FR-NE-082`/`083`) plus
/// `GetDeterrenceDurations`/`SetDeterrenceDurations` (`FR-NE-113`) — LAN transport. `action` is
/// one of `"siren"`/`"spotlight"`/`"warning"`, gated on `CapabilitiesClient.getCapabilities()`'s
/// `sirenCapable`/`spotlightCapable`/`warningCapable` flags — never a hardcoded list. See
/// `wan/wan_deterrence_client.dart`'s `WanDeterrenceClient` for the WAN counterpart, same shape.
///
/// **No duration parameter on [activateDeterrence]** (`FEAT-236`, 2026-08-14) — the camera
/// applies its own persisted, per-action duration from [getDeterrenceDurations] instead, shared
/// with the camera's own automatic detection-triggered response (`FR-CF-144`). Configure the
/// duration via [setDeterrenceDurations] before triggering, not per-call.
///
/// **`warning`'s value is a repeat count, not seconds** (revised `FEAT-236`, 2026-08-15, after
/// real-hardware testing) — `siren_seconds`/`spotlight_seconds` are whole seconds, but
/// `warning_repeat_count` is how many times the clip plays before stopping. A duration-based
/// warning loop was tried first and found unreliable on real hardware (cut the clip off partway
/// through and restarted it) — see `bsp_camera_ameba.c`'s `prvWarningPollTimerCallback()` for
/// the completion-driven replacement this drives.
///
/// **`getDeterrenceStatus()` reports each action's own independent state** (`FEAT-236`,
/// 2026-08-14, direct user report from real-hardware testing: triggering a second action while
/// the first was still on only ever highlighted the most-recently-tapped one in the UI) — siren,
/// spotlight, and warning are separate hardware outputs and can be active simultaneously; there
/// is no single "the" active action.
class DeterrenceClient {
  DeterrenceClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  /// Each deterrence action's own independent active/inactive state. siren, spotlight, and
  /// warning are separate hardware outputs and can be active simultaneously (`FEAT-236`,
  /// 2026-08-14 fix) — the previous `{active, action}` shape could only ever report one action
  /// as "the" active one, which made the UI's own highlight silently wrong whenever a second
  /// action was triggered while the first was still on. See `DeterrenceStatus` below.
  Future<CameraResult<DeterrenceStatus>> getDeterrenceStatus({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetDeterrenceStatus', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => CameraSuccess(DeterrenceStatus.fromJson(value)),
      CameraFailure(:final reason) => CameraFailure(reason),
      CameraTimeout() => const CameraTimeout(),
    };
  }

  Future<CameraResult<void>> activateDeterrence(
    String action, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'ActivateDeterrence',
      params: {'action': action},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  Future<CameraResult<void>> deactivateDeterrence(
    String action, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'DeactivateDeterrence',
      params: {'action': action},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  /// The current configured auto-stop duration (whole seconds) for each deterrence action. Only
  /// the keys this camera reports as capable (`CapabilitiesClient`) are meaningful.
  Future<CameraResult<Map<String, int>>> getDeterrenceDurations({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetDeterrenceDurations', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => CameraSuccess<Map<String, int>>(
        value.map((key, dynamic v) => MapEntry(key, (v as num).toInt())),
      ),
      CameraFailure(:final reason) => CameraFailure<Map<String, int>>(reason),
      CameraTimeout() => const CameraTimeout<Map<String, int>>(),
    };
  }

  /// Partial update — only the keys present in [changes] (e.g. `{"siren_seconds": 15}`) change;
  /// every other action's configured duration is left untouched. Every key must be one of
  /// `siren_seconds`/`spotlight_seconds`/`warning_repeat_count`, within the range
  /// [getDeterrenceDurationOptions] reports for it, and name an action this camera reports as
  /// capable, or the camera rejects the whole request with a `CameraFailure` (`HTTP 400`) rather
  /// than applying a partial subset.
  Future<CameraResult<void>> setDeterrenceDurations(
    Map<String, int> changes, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetDeterrenceDurations',
      params: changes,
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  /// Camera-reported valid range for each duration/count key — the UI must build its
  /// slider/stepper bounds from this, never a hardcoded range (`FEAT-236`, 2026-08-15, direct
  /// user correction after real-hardware testing: an earlier version hardcoded a 0-60s UI range
  /// with no camera-side confirmation, and a value of 0 degenerated to "never really activates").
  /// Only the keys this camera reports as capable (`CapabilitiesClient`) are meaningful.
  Future<CameraResult<DeterrenceDurationOptions>> getDeterrenceDurationOptions({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetDeterrenceDurationOptions', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => CameraSuccess(DeterrenceDurationOptions.fromJson(value)),
      CameraFailure(:final reason) => CameraFailure<DeterrenceDurationOptions>(reason),
      CameraTimeout() => const CameraTimeout<DeterrenceDurationOptions>(),
    };
  }
}

/// See [DeterrenceClient.getDeterrenceDurationOptions]. Falls back to `1`/`1` (a safe, non-zero
/// single-unit range) for any field missing from the response, rather than crashing on firmware
/// too old to report it — same defensive-default posture `CameraCapabilities` uses elsewhere.
class DeterrenceDurationOptions {
  const DeterrenceDurationOptions({
    required this.sirenSecondsMin,
    required this.sirenSecondsMax,
    required this.spotlightSecondsMin,
    required this.spotlightSecondsMax,
    required this.warningRepeatCountMin,
    required this.warningRepeatCountMax,
  });

  factory DeterrenceDurationOptions.fromJson(Map<String, dynamic> json) {
    int read(String key, int fallback) => (json[key] as num?)?.toInt() ?? fallback;
    return DeterrenceDurationOptions(
      sirenSecondsMin: read('siren_seconds_min', 1),
      sirenSecondsMax: read('siren_seconds_max', 60),
      spotlightSecondsMin: read('spotlight_seconds_min', 1),
      spotlightSecondsMax: read('spotlight_seconds_max', 60),
      warningRepeatCountMin: read('warning_repeat_count_min', 1),
      warningRepeatCountMax: read('warning_repeat_count_max', 10),
    );
  }

  final int sirenSecondsMin;
  final int sirenSecondsMax;
  final int spotlightSecondsMin;
  final int spotlightSecondsMax;
  final int warningRepeatCountMin;
  final int warningRepeatCountMax;
}

/// See [DeterrenceClient.getDeterrenceStatus]/`WanDeterrenceClient.getDeterrenceStatus`. Each
/// field is that action's own independent state — any combination can be `true` at once.
class DeterrenceStatus {
  const DeterrenceStatus({required this.siren, required this.spotlight, required this.warning});

  factory DeterrenceStatus.fromJson(Map<String, dynamic> json) => DeterrenceStatus(
    siren: json['siren'] == true,
    spotlight: json['spotlight'] == true,
    warning: json['warning'] == true,
  );

  final bool siren;
  final bool spotlight;
  final bool warning;

  /// Whether the named action (`"siren"`/`"spotlight"`/`"warning"`) is currently active.
  bool isActive(String action) => switch (action) {
    'siren' => siren,
    'spotlight' => spotlight,
    'warning' => warning,
    _ => false,
  };

  /// Every action currently active, by name — e.g. `{"siren", "spotlight"}`.
  Set<String> get activeActions => {
    if (siren) 'siren',
    if (spotlight) 'spotlight',
    if (warning) 'warning',
  };
}
