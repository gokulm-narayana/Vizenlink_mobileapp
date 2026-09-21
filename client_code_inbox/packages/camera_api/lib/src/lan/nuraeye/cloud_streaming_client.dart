import '../../camera_result.dart';
import '../../wan/wan_live_view_client.dart';
import 'nuraeye_client.dart';

/// LAN counterparts to two of [WanLiveViewClient]'s three AWS/MQTT commands —
/// `GetCloudStreamingStatus`/`StopCloudStreaming` (`FR-NE-068`/`FR-NE-060`), added 2026-08-06.
/// No LAN `StartCloudStreaming`: starting cloud streaming only ever makes sense for a client
/// that needs the WAN path in the first place, so there's no LAN use case to mirror.
///
/// Primary motivation: `LiveViewController._switchToLan()`'s WAN health-poll — once it confirms
/// the camera is reachable on LAN, stopping the KVS push via this client avoids an unnecessary
/// AWS/Lambda round trip for a camera it can already reach directly (direct user request,
/// 2026-08-06 — see `mobile-app-android-3-video-image-pipeline/DESIGN.md` §7.2).
class CloudStreamingLanClient {
  CloudStreamingLanClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  /// Parses the same `stream_status` vocabulary as [WanLiveViewClient.getCloudStreamingStatus]
  /// (`active`/`idle`/`degraded`/`not_compiled`) — one shared [StreamStatus] enum, two
  /// transports. Unlike the WAN version, a failed/timed-out *LAN* call here means "camera isn't
  /// reachable on this network," not "camera is offline" — that specific offline-vs-degraded
  /// distinction is WAN-only (it relies on the MQTT round-trip itself timing out).
  Future<CameraResult<StreamStatus>> getCloudStreamingStatus({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetCloudStreamingStatus', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
        final status = switch (value['stream_status'] as String?) {
          'active' => StreamStatus.active,
          'idle' => StreamStatus.idle,
          'degraded' => StreamStatus.degraded,
          'not_compiled' => StreamStatus.notCompiled,
          _ => null,
        };
        if (status == null) {
          return CameraFailure<StreamStatus>(
            'Unrecognized stream_status: ${value['stream_status']}',
          );
        }
        return CameraSuccess<StreamStatus>(status);
      }(),
      CameraFailure(:final reason) => CameraFailure<StreamStatus>(reason),
      CameraTimeout() => const CameraTimeout<StreamStatus>(),
    };
  }

  Future<CameraResult<void>> stopCloudStreaming({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('StopCloudStreaming', timeout: timeout);
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }
}
