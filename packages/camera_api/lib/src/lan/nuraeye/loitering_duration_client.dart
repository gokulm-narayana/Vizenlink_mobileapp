import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// `GetLoiteringDuration`/`SetLoiteringDuration` (`FR-CF-150`/`FR-NE-121`) — LAN transport. The
/// dwell threshold (whole seconds) a tracked object must stay present before the camera fires a
/// `Loitering` event, independent of whether `PersonDetected` itself is enabled or disabled. See
/// `wan/wan_loitering_duration_client.dart`'s `WanLoiteringDurationClient` for the WAN
/// counterpart, same shape.
///
/// Build UI bounds from `CameraCapabilities.loiteringDurationMinSeconds`/`MaxSeconds`
/// (`CapabilitiesClient.getCapabilities()`) — fixed compile-time bounds, never a hardcoded
/// range, same convention as `RecordingsClient`'s clip-duration setting.
class LoiteringDurationClient {
  LoiteringDurationClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<int>> getLoiteringDuration({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetLoiteringDuration', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => value['loitering_duration_seconds'] is int
          ? CameraSuccess<int>(value['loitering_duration_seconds'] as int)
          : CameraFailure<int>(
              'GetLoiteringDuration response missing loitering_duration_seconds: $value'),
      CameraFailure(:final reason) => CameraFailure<int>(reason),
      CameraTimeout() => const CameraTimeout<int>(),
    };
  }

  /// The camera rejects a value outside `CameraCapabilities.loiteringDurationMinSeconds`/
  /// `MaxSeconds` with a `400` — check those bounds before calling rather than relying on the
  /// rejection alone.
  Future<CameraResult<void>> setLoiteringDuration(
    int seconds, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetLoiteringDuration',
      params: {'loitering_duration_seconds': seconds},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }
}
