import '../../camera_result.dart';
import '../../mirror_flip_types.dart';
import 'nuraeye_client.dart';

/// `SetMirrorFlip`/`GetMirrorFlip` (`FR-NE-039`, `FR-MOB-074`) — LAN transport. See
/// `wan/wan_mirror_flip_client.dart`'s `WanMirrorFlipClient` for the WAN counterpart (same
/// `MirrorFlipMode` wire vocabulary, `mirror_flip_types.dart`).
class MirrorFlipClient {
  MirrorFlipClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<MirrorFlipMode>> getMirrorFlip({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetMirrorFlip', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
          final modeStr = value['mode'];
          if (modeStr is! String) {
            return CameraFailure<MirrorFlipMode>('GetMirrorFlip response missing mode: $value');
          }
          final mode = MirrorFlipModeWire.fromWire(modeStr);
          if (mode == null) {
            return CameraFailure<MirrorFlipMode>('Unrecognized mirror/flip mode: $modeStr');
          }
          return CameraSuccess<MirrorFlipMode>(mode);
        }(),
      CameraFailure(:final reason) => CameraFailure<MirrorFlipMode>(reason),
      CameraTimeout() => const CameraTimeout<MirrorFlipMode>(),
    };
  }

  Future<CameraResult<void>> setMirrorFlip(
    MirrorFlipMode mode, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetMirrorFlip',
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
