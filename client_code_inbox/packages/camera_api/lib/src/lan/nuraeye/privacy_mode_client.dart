import '../../camera_result.dart';
import '../../privacy_mode_types.dart';
import 'nuraeye_client.dart';

/// `SetPrivacyMode`/`GetPrivacyMode` (`FR-CF-138`, `FR-NE-093`, `FR-MOB-091`) — LAN transport.
/// `Full` stops all video/audio capture; `Zone` uses whatever privacy-mask zones are already
/// configured (`FR-CF-015`, ONVIF `SetVideoSourceConfiguration`'s mask fields — no editor exists
/// in this app yet, `FEAT-009`'s mask-region editor is separate, deferred work); `None` is normal
/// operation. See `wan/wan_privacy_mode_client.dart`'s `WanPrivacyModeClient` for the WAN
/// counterpart (same `PrivacyMode` wire vocabulary, `privacy_mode_types.dart`).
class PrivacyModeClient {
  PrivacyModeClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<PrivacyMode>> getPrivacyMode({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetPrivacyMode', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
        final modeStr = value['mode'];
        if (modeStr is! String) {
          return CameraFailure<PrivacyMode>('GetPrivacyMode response missing mode: $value');
        }
        final mode = PrivacyModeWire.fromWire(modeStr);
        if (mode == null) {
          return CameraFailure<PrivacyMode>('Unrecognized privacy mode: $modeStr');
        }
        return CameraSuccess<PrivacyMode>(mode);
      }(),
      CameraFailure(:final reason) => CameraFailure<PrivacyMode>(reason),
      CameraTimeout() => const CameraTimeout<PrivacyMode>(),
    };
  }

  Future<CameraResult<void>> setPrivacyMode(
    PrivacyMode mode, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetPrivacyMode',
      params: {'mode': mode.wireValue},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }
}
