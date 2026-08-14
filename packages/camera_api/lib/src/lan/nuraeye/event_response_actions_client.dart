import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// `GetEventResponseActions`/`SetEventResponseActions` (`FR-CF-144`, `FR-NE-112`) — LAN
/// transport. Per-detection-event-type selection of automatic response actions
/// (`siren`/`spotlight`/`warning`/`mobile_alert`), keyed by the same wire event strings
/// `EventPreferencesClient` uses, but only for the detection-type subset
/// `CapabilitiesClient`'s `supportedEventDeterrenceOptions` reports — never a hardcoded list.
/// See `wan/wan_event_response_actions_client.dart`'s `WanEventResponseActionsClient` for the
/// WAN counterpart, same shape.
///
/// **Not to be confused with:**
/// - `EventPreferencesClient` (`FR-NE-111`) — that controls whether an event *type* is generated
///   at all, device-wide; this controls what happens *in addition* when an already-enabled
///   detection event fires.
/// - The per-detection-rule `mobile_notifications`/`buzzer_activation` toggles
///   (`NuraeyeClient.call('...alert-rules...')`) — a different, pre-existing, narrower concept
///   this generalizes for the event types it covers.
///
/// `mobile_alert` carries no device-side effect — selecting/unselecting it never gates whether
/// the camera delivers the event (that's `EventPreferencesClient`'s job alone). It's read by
/// this app to decide locally whether to show a push notification for an incoming alert.
/// `siren`/`spotlight`/`warning` are real, physical device actions the camera auto-triggers when
/// the event fires.
class EventResponseActionsClient {
  EventResponseActionsClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  /// The current selected response actions per detection event type (only keys present in
  /// `CapabilitiesClient.getCapabilities().supportedEventDeterrenceOptions` are meaningful).
  Future<CameraResult<Map<String, List<String>>>> getEventResponseActions({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetEventResponseActions', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => CameraSuccess<Map<String, List<String>>>(
        value.map(
          (key, dynamic v) => MapEntry(
            key,
            v is List ? v.whereType<String>().toList() : const <String>[],
          ),
        ),
      ),
      CameraFailure(:final reason) => CameraFailure<Map<String, List<String>>>(reason),
      CameraTimeout() => const CameraTimeout<Map<String, List<String>>>(),
    };
  }

  /// Partial update — only the event types present in [changes] are changed on the camera; each
  /// key's array fully **replaces** that event type's selected action set (not additive). Every
  /// event type key must be detection-eligible and every action must be one of the actions
  /// `supportedEventDeterrenceOptions` reports eligible for that type, or the camera rejects the
  /// whole request with a `CameraFailure` (`HTTP 400`) rather than applying a partial subset.
  Future<CameraResult<void>> setEventResponseActions(
    Map<String, List<String>> changes, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetEventResponseActions',
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
