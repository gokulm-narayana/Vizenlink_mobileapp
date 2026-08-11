import '../camera_result.dart';
import 'iot_command_client.dart';
import 'kvs_playback_client.dart';
import 'wan_live_view_client.dart';

/// Concrete [WanLiveViewClient] — `mobile-app-android-3-video-image-pipeline/DESIGN.md` §7.
///
/// **Moved into `camera_api` 2026-08-11** — previously lived in the app layer specifically
/// because it depended (transitively, via `IotCommandClient`/`KvsPlaybackClient`) on
/// `AuthController`; both of those now source the Cognito ID token from `WanAuth.idTokenProvider`
/// instead (set once at app startup), so nothing here reaches into app code anymore. Still
/// distinct from `WebRtcLiveViewSession`, which stays in the app layer for an unrelated reason —
/// it needs `flutter_webrtc`'s native `RTCPeerConnection`, a real Flutter-plugin dependency this
/// package can never take on.
///
/// **Not yet hardware/cloud-verified** — see `IotCommandClient`/`KvsPlaybackClient`'s own docs.
class AwsWanLiveViewClient implements WanLiveViewClient {
  AwsWanLiveViewClient(String thingName)
    : _iot = IotCommandClient(thingName),
      _kvs = KvsPlaybackClient(),
      _thingName = thingName;

  final String _thingName;
  final IotCommandClient _iot;
  final KvsPlaybackClient _kvs;

  @override
  Future<CameraResult<void>> startCloudStreaming() async {
    try {
      await _iot.sendStartCloudStreaming();
      return const CameraSuccess(null);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  @override
  Future<CameraResult<void>> stopCloudStreaming() async {
    try {
      await _iot.sendStopCloudStreaming();
      return const CameraSuccess(null);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  /// Retries on an `idle` result a couple of times before giving up — the substream can
  /// legitimately still be starting up in the few seconds right after `StartCloudStreaming`, and
  /// a single immediate query would read that transient window as a hard "idle" failure rather
  /// than genuine unavailability. `degraded`/`notCompiled` are stable negative signals (not a
  /// startup-timing artifact) and are returned immediately, not retried.
  @override
  Future<CameraResult<StreamStatus>> getCloudStreamingStatus() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final output = await _iot.sendCommandWithResponse(IotCommandClient.getCloudStreamingStatus);
      if (output == null) return const CameraTimeout();

      final status = switch (output['stream_status'] as String?) {
        'active' => StreamStatus.active,
        'idle' => StreamStatus.idle,
        'degraded' => StreamStatus.degraded,
        'not_compiled' => StreamStatus.notCompiled,
        _ => null,
      };
      if (status == null) {
        return CameraFailure('Unrecognized stream_status: ${output['stream_status']}');
      }
      if (status != StreamStatus.idle || attempt == 2) {
        return CameraSuccess(status);
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return const CameraTimeout();
  }

  @override
  Future<CameraResult<Uri>> resolvePlaybackUri() async {
    try {
      final url = await _kvs.getPlaybackUrl(_thingName);
      return CameraSuccess(Uri.parse(url));
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }
}
