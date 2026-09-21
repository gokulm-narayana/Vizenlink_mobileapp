import '../../anti_flicker_types.dart';
import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// `SetAntiFlickerMode`/`GetAntiFlickerMode` (`FR-NE-109`, `FR-MOB-102`) — LAN transport. See
/// `wan/wan_anti_flicker_client.dart`'s `WanAntiFlickerClient` for the WAN counterpart (same
/// `AntiFlickerMode` wire vocabulary, `anti_flicker_types.dart`). Mirrors
/// `mirror_flip_client.dart`'s exact shape — same no-ONVIF-equivalent situation.
class AntiFlickerClient {
  AntiFlickerClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<AntiFlickerMode>> getAntiFlickerMode({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetAntiFlickerMode', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
          final modeStr = value['mode'];
          if (modeStr is! String) {
            return CameraFailure<AntiFlickerMode>('GetAntiFlickerMode response missing mode: $value');
          }
          final mode = AntiFlickerModeWire.fromWire(modeStr);
          if (mode == null) {
            return CameraFailure<AntiFlickerMode>('Unrecognized anti-flicker mode: $modeStr');
          }
          return CameraSuccess<AntiFlickerMode>(mode);
        }(),
      CameraFailure(:final reason) => CameraFailure<AntiFlickerMode>(reason),
      CameraTimeout() => const CameraTimeout<AntiFlickerMode>(),
    };
  }

  Future<CameraResult<void>> setAntiFlickerMode(
    AntiFlickerMode mode, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetAntiFlickerMode',
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
