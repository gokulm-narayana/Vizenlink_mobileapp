import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// `GetBboxOverlayEnabled`/`SetBboxOverlayEnabled` (`FR-CF-151`/`FR-NE-123`) — LAN transport.
/// Whether the camera draws the AI object-detection bounding-box overlay (OSD burn-in) on the
/// video stream — independent of whether detection/alerts themselves are running (`PersonDetected`/
/// `Loitering` keep firing and carrying `bbox` in their payload regardless of this toggle; this
/// setting only controls whether a box is visibly drawn on the video everyone watches/records).
/// See `wan/wan_bbox_overlay_client.dart`'s `WanBboxOverlayClient` for the WAN counterpart, same
/// shape.
///
/// Gate the toggle on `CameraCapabilities.bboxOverlayCapable` — `false` on a build with
/// `AI_DETECTIONS` not compiled in, where there is no detection pipeline to draw an overlay for
/// at all.
class BboxOverlayClient {
  BboxOverlayClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<bool>> isBboxOverlayEnabled({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetBboxOverlayEnabled', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
          final enabled = value['enabled'];
          if (enabled is! bool) {
            return CameraFailure<bool>('GetBboxOverlayEnabled response missing "enabled": $value');
          }
          return CameraSuccess<bool>(enabled);
        }(),
      CameraFailure(:final reason) => CameraFailure<bool>(reason),
      CameraTimeout() => const CameraTimeout<bool>(),
    };
  }

  Future<CameraResult<void>> setBboxOverlayEnabled(
    bool enabled, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetBboxOverlayEnabled',
      params: {'enabled': enabled},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }
}
