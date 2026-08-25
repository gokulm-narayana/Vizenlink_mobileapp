import '../../camera_result.dart';
import '../../local_storage_types.dart';
import 'nuraeye_client.dart';

/// `GetLocalStorage`/`SetLocalStorage` (`FR-CF-044`, `FR-NE-087`, `FR-MOB-083`) — LAN transport.
/// See `wan/wan_local_storage_client.dart`'s `WanLocalStorageClient` for the WAN counterpart
/// (same `LocalStorageStatus` wire vocabulary).
class LocalStorageClient {
  LocalStorageClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<LocalStorageStatus>> getStatus({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetLocalStorage', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => _parse(value),
      CameraFailure(:final reason) => CameraFailure<LocalStorageStatus>(reason),
      CameraTimeout() => const CameraTimeout<LocalStorageStatus>(),
    };
  }

  /// The camera rejects `enabled: true` with no SD card present (`500`/`Capability absent or
  /// no card present`) — callers should pre-check `LocalStorageStatus.cardPresent` before
  /// calling this with `enabled: true` rather than relying on the rejection alone, per
  /// `SETTINGS_API_GUIDE.md`'s "Local Storage" entry.
  Future<CameraResult<void>> setEnabled(
    bool enabled, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetLocalStorage',
      params: {'enabled': enabled},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  CameraResult<LocalStorageStatus> _parse(Map<String, dynamic> value) {
    final enabled = value['enabled'];
    final cardPresent = value['card_present'];
    final capacityBytes = value['capacity_bytes'];
    final freeBytes = value['free_bytes'];
    if (enabled is! bool ||
        cardPresent is! bool ||
        capacityBytes is! int ||
        freeBytes is! int) {
      return CameraFailure('GetLocalStorage response missing fields: $value');
    }
    return CameraSuccess(
      LocalStorageStatus(
        enabled: enabled,
        cardPresent: cardPresent,
        capacityBytes: capacityBytes,
        freeBytes: freeBytes,
      ),
    );
  }
}
