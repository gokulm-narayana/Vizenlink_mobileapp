import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// `GetEventPreferences`/`SetEventPreferences` (`FR-CF-143`, `FR-NE-111`) — LAN transport. Keyed
/// by the same wire event strings the alert JSON itself already uses
/// (`"VideoModeChanged"`/`"PrivacyModeChanged"`/`"PersonDetected"` today) and by
/// `CapabilitiesClient`'s `supportedEventTypes` — never a hardcoded list. See
/// `wan/wan_event_preferences_client.dart`'s `WanEventPreferencesClient` for the WAN
/// counterpart, same shape.
///
/// **Not to be confused with** any per-detection-rule alert-action toggle
/// (`mobile_notifications`/`buzzer_activation` — a different, pre-existing concept) — this
/// client controls whether an alert *type* is generated at all, device-wide, and per direct
/// user decision the camera suppresses it on **every** delivery path it has, including ONVIF
/// PullPoint (third-party NVR/VMS clients), not just this app's own feed.
class EventPreferencesClient {
  EventPreferencesClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  /// The current enabled/disabled state for every alert type the camera currently reports
  /// (only keys present in `CapabilitiesClient.getCapabilities().supportedEventTypes` are
  /// meaningful — the camera's response is keyed identically).
  Future<CameraResult<Map<String, bool>>> getEventPreferences({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetEventPreferences', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => CameraSuccess<Map<String, bool>>(
        value.map((key, dynamic v) => MapEntry(key, v == true)),
      ),
      CameraFailure(:final reason) => CameraFailure<Map<String, bool>>(reason),
      CameraTimeout() => const CameraTimeout<Map<String, bool>>(),
    };
  }

  /// Partial update — only the keys present in [changes] are changed on the camera; every other
  /// alert type's current state is left untouched. Every key in [changes] must be one of the
  /// camera's currently-supported alert type strings, or the camera rejects the whole request
  /// with a `CameraFailure` (`HTTP 400`) rather than applying a partial subset.
  Future<CameraResult<void>> setEventPreferences(
    Map<String, bool> changes, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetEventPreferences',
      params: changes,
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }
}
