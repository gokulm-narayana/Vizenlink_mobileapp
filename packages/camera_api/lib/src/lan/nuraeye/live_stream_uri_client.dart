import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// The main/"high" ONVIF-facing stream (`Profile_1`, Stream 0) — full sensor resolution, also
/// the profile ONVIF NVR/VMS clients use. See `onvif_user_config.c`.
const String kMainStreamProfileToken = 'Profile_1';

/// The sub/"medium" ONVIF-facing stream (`Profile_2`, Stream 1). See `onvif_user_config.c`.
const String kSubStreamProfileToken = 'Profile_2';

/// The dedicated mobile-only stream's profile token (`Profile_3`, Stream 2, `FR-CF-152`/`153`)
/// — a NuraEye-only identifier, **not** a real ONVIF profile (no `GetProfiles`/`GetStreamUri`
/// entry exists for it; it's reachable only via [LiveStreamUriClient.getLiveStreamUri]). Fixed
/// 720p, RTSPS-only. This is the stream this app's own live view should default to — pass this,
/// never a bare `'Profile_3'` string literal, so the intent stays visible at every call site and
/// a future accidental default back to [kMainStreamProfileToken] is easy to spot in review. See
/// `bsp_camera_ameba.c`'s `MOBILE_ONLY_STREAM_WIDTH`/`HEIGHT`/`FRAME_RATE`/`RTSP_PORT`.
const String kMobileOnlyStreamProfileToken = 'Profile_3';

/// Which transport the camera chose for a [LiveStreamUriClient.getLiveStreamUri] result.
///
/// The camera decides this server-side (`bsp_camera_isWebRtcCapable()`, `FR-NE-127`) — it is
/// never a client-side choice. [webrtc] means `mediaUri` is a WebRTC signaling `POST` target
/// (`http://<ip>:<port>/webrtc`); [rtsp] means it is an RTSP(S) stream URL
/// (`rtsps://<ip>:<port><path>`).
enum LiveStreamTransport { webrtc, rtsp }

/// Discovery result for `FR-NE-127`'s `GetLiveStreamUri` — the camera's live-view connection
/// info for one video profile, in whichever transport this build actually has.
class LiveStreamTarget {
  const LiveStreamTarget({
    required this.transport,
    required this.port,
    required this.mediaUri,
  });

  /// [LiveStreamTransport.webrtc] or [LiveStreamTransport.rtsp] — decides which player
  /// (`WebRtcLiveViewSession` or `RtspLiveViewSession`) the caller should use.
  final LiveStreamTransport transport;

  /// The actually-bound port for this stream/transport combination.
  final int port;

  /// Full connection target:
  /// - [LiveStreamTransport.webrtc]: `http://<camera-ip>:<port>/webrtc` — **plain HTTP, not
  ///   HTTPS**, the signaling socket is unauthenticated/unencrypted by firmware design (see
  ///   `module_webrtc.c`).
  /// - [LiveStreamTransport.rtsp]: `rtsps://<camera-ip>:<port><path>` (or `rtsp://` on a
  ///   non-`USE_HTTPS` build) — RTSP-level Digest auth applies (see `RtspLiveViewSession`).
  final Uri mediaUri;
}

/// LAN-only client for `GetLiveStreamUri` (`FR-NE-127`). This is the mobile app's **only** LAN
/// live-view discovery mechanism — the camera picks the transport (webrtc/rtsp) server-side and
/// reports which one via `LiveStreamTarget.transport`. **RTSP is not VMS/NVR-only reserved
/// territory** — the mobile-only stream (`Profile_3`, `FR-CF-153`) and, when WebRTC is disabled
/// camera-side, `Profile_1`/`Profile_2` as well, are legitimately reached over RTSP(S) by this
/// app too. There is no WAN counterpart for either transport this endpoint can return — both are
/// LAN-only by design.
///
/// (The pre-2026-09-07 separate `GetWebRtcUri`/`GetRtspUri` endpoints, and the
/// old-firmware-compat fallback this client briefly kept for them, were removed 2026-09-11 — all
/// cameras are expected to be on firmware that serves this endpoint.)
class LiveStreamUriClient {
  LiveStreamUriClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  /// [profileToken] — `Profile_1`/`Profile_2`/`Profile_3` (this firmware's fixed, compile-time
  /// profile set; there is no dynamic profile creation to look up). [timeout] defaults short
  /// (`NuraeyeClient.call`'s own 10s default) — callers doing a fast LAN-reachability decision
  /// (`LiveViewController`) pass a much shorter one; see that class's `lanProbeTimeout` doc.
  Future<CameraResult<LiveStreamTarget>> getLiveStreamUri(
    String profileToken, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'GetLiveStreamUri',
      params: {'profile_token': profileToken},
      timeout: timeout,
    );

    // Plain dart:core print, not debugPrint — this package stays pure-Dart (no `package:flutter`
    // import, see class doc), but Flutter's Android embedding still redirects a running app's
    // stdout to logcat regardless of which package the print() call originates from. This is the
    // LAN reachability probe LiveViewController's LAN→WAN decision hinges on, so it needs
    // on-device visibility.
    switch (result) {
      case CameraSuccess(:final value):
        print('[LiveView] GetLiveStreamUri($profileToken) -> success: $value');
      case CameraFailure(:final reason):
        print('[LiveView] GetLiveStreamUri($profileToken) -> failure: $reason');
      case CameraTimeout():
        print('[LiveView] GetLiveStreamUri($profileToken) -> timed out after $timeout');
    }

    return switch (result) {
      CameraSuccess(:final value) => () {
          final transportText = value['transport'];
          final port = value['port'];
          final urlText = value['url'];
          if (transportText is! String || port is! int || urlText is! String) {
            return CameraFailure<LiveStreamTarget>(
              'GetLiveStreamUri response missing transport/port/url fields: $value',
            );
          }
          final transport = switch (transportText) {
            'webrtc' => LiveStreamTransport.webrtc,
            'rtsp' => LiveStreamTransport.rtsp,
            _ => null,
          };
          if (transport == null) {
            return CameraFailure<LiveStreamTarget>(
              'GetLiveStreamUri response has unknown transport: $transportText',
            );
          }
          final url = Uri.tryParse(urlText);
          if (url == null) {
            return CameraFailure<LiveStreamTarget>('Unparseable media url: $urlText');
          }
          return CameraSuccess<LiveStreamTarget>(
            LiveStreamTarget(transport: transport, port: port, mediaUri: url),
          );
        }(),
      CameraFailure(:final reason) => CameraFailure<LiveStreamTarget>(reason),
      CameraTimeout() => const CameraTimeout<LiveStreamTarget>(),
    };
  }

  /// Independent LAN reachability check, used by [LiveViewController] to tell "camera isn't on
  /// this network" apart from "camera IS on this network, but `GetLiveStreamUri` itself is
  /// failing" once the latter has exhausted its own retries — see that class's
  /// `lanReachabilityCheckTimeout` doc for why. Deliberately `AreYouNuraeyeDevice`, not another
  /// `GetLiveStreamUri` retry: it's the cheapest authenticated round trip this API already has (a
  /// fixed challenge/response, no real credential digest needed), so a failure here is a much
  /// stronger "not reachable" signal than another attempt at the same call that just failed.
  Future<bool> checkReachable({Duration timeout = const Duration(seconds: 3)}) async {
    final result = await _nuraeye.areYouNuraeyeDevice(timeout: timeout);
    switch (result) {
      case CameraSuccess(:final value):
        print('[LiveView] AreYouNuraeyeDevice (reachability check) -> success: genuine=$value');
        return value;
      case CameraFailure(:final reason):
        print('[LiveView] AreYouNuraeyeDevice (reachability check) -> failure: $reason');
        return false;
      case CameraTimeout():
        print('[LiveView] AreYouNuraeyeDevice (reachability check) -> timed out after $timeout');
        return false;
    }
  }

  void close() => _nuraeye.close();
}
