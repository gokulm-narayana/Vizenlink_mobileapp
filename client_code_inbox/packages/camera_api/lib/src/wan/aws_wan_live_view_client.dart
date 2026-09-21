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
  /// [iotCommandClient]/[kvsPlaybackClient] are overridable for tests — default to real
  /// instances, matching every other `Wan*Client` in this package (e.g.
  /// `WanNightVisionClient`). **Added 2026-08-14** — this class previously had no way to inject
  /// a fake `IotCommandClient` at all, so nothing could unit-test it directly; every existing
  /// test exercised it only through `_FakeWanClient`-style hand-written fakes of the
  /// `WanLiveViewClient` *interface*, which never actually ran this class's own logic (including
  /// the missing-`try`/`catch` bug on `getCloudStreamingStatus` this fixed).
  AwsWanLiveViewClient(
    String thingName, {
    IotCommandClient? iotCommandClient,
    KvsPlaybackClient? kvsPlaybackClient,
  }) : _iot = iotCommandClient ?? IotCommandClient(thingName),
       _kvs = kvsPlaybackClient ?? KvsPlaybackClient(),
       _thingName = thingName;

  final String _thingName;
  final IotCommandClient _iot;
  final KvsPlaybackClient _kvs;

  @override
  Future<CameraResult<int>> startCloudStreaming(StreamQuality quality) async {
    try {
      final output = await _iot.sendStartCloudStreaming(quality.wireValue);
      final token = output?['token'];
      if (token is! int) {
        return CameraFailure('StartCloudStreaming reply missing token: $output');
      }
      return CameraSuccess(token);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  @override
  Future<CameraResult<void>> stopCloudStreaming(int token) async {
    try {
      await _iot.sendStopCloudStreaming(token: token);
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
  ///
  /// **Wrapped in `try`/`catch` 2026-08-14** — this was the one method on this class missing it
  /// (its three siblings all had it from day one); `IotCommandClient.sendCommandWithResponse()`
  /// throws on a genuine relay/network failure (documented on that method), and with nothing to
  /// catch it here that exception propagated straight out of this `Future` past every caller's
  /// `CameraResult` switch, crashing on a plain transient network failure (observed on a real
  /// device as an uncaught `SocketException`). See `../../../bugs/` mobile-app team report,
  /// 2026-08-14.
  ///
  /// [token] is also the heartbeat (`FR-CF-154`) — every call here refreshes the camera-side
  /// lease for this viewer, so the caller must keep calling this at least every 30s while it
  /// wants the stream to stay up.
  @override
  Future<CameraResult<StreamStatus>> getCloudStreamingStatus(int token) async {
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        final output = await _iot.sendCommandWithResponse(
          IotCommandClient.getCloudStreamingStatus,
          params: {'token': token},
        );
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
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  @override
  Future<CameraResult<Uri>> resolvePlaybackUri(StreamQuality quality) async {
    try {
      final url = await _kvs.getPlaybackUrl('$_thingName-${quality.wireValue}');
      return CameraSuccess(Uri.parse(url));
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }
}
