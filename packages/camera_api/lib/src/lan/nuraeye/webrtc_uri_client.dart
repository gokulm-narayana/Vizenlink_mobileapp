import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// Discovery result for FR-NE-090's `GetWebRtcUri` — the camera's LAN-only WebRTC signaling
/// endpoint for one video profile.
class WebRtcTarget {
  const WebRtcTarget({required this.port, required this.signalingUrl});

  /// The actually-bound signaling port (per `CMD_WEBRTC_GET_PORT` — never assumed from static
  /// config, since the firmware can auto-increment past a configured port on a bind conflict).
  final int port;

  /// Full `POST` target, `http://<camera-ip>:<port>/webrtc` — **plain HTTP, not HTTPS**: the
  /// signaling socket is unauthenticated and unencrypted by firmware design (confirmed via
  /// direct code reading of `module_webrtc.c`), a distinct posture from `/nuraeye`/`/onvif`.
  final Uri signalingUrl;
}

/// LAN-only client for `GetWebRtcUri` (`FR-NE-090`). This is the mobile app's **only** LAN
/// live-view discovery mechanism — RTSP is reserved for VMS/NVR consumption
/// (`CLAUDE.md`'s Stream consumer mapping) and is deliberately not exposed anywhere in this
/// package. There is no WAN counterpart: the signaling socket itself has no WAN reachability.
class WebRtcUriClient {
  WebRtcUriClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  /// [profileToken] — `Profile_1`/`Profile_2`/`Profile_3` (this firmware's fixed, compile-time
  /// profile set; there is no dynamic profile creation to look up). [timeout] defaults short
  /// (`NuraeyeClient.call`'s own 10s default) — callers doing a fast LAN-reachability decision
  /// (`LiveViewController`) pass a much shorter one; see that class's `lanProbeTimeout` doc.
  Future<CameraResult<WebRtcTarget>> getWebRtcUri(
    String profileToken, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'GetWebRtcUri',
      params: {'profile_token': profileToken},
      timeout: timeout,
    );

    // Plain dart:core print, not debugPrint — this package stays pure-Dart (no `package:flutter`
    // import, see class doc), but Flutter's Android embedding still redirects a running app's
    // stdout to logcat regardless of which package the print() call originates from. Added
    // 2026-08-01: this is the LAN reachability probe LiveViewController's LAN→WAN decision hinges
    // on, and had zero on-device visibility — a failure here (timeout, TLS/cert issue, wrong
    // credentials) previously surfaced only as an unexplained jump straight to the WAN outcome.
    switch (result) {
      case CameraSuccess(:final value):
        print('[LiveView] GetWebRtcUri($profileToken) -> success: $value');
      case CameraFailure(:final reason):
        print('[LiveView] GetWebRtcUri($profileToken) -> failure: $reason');
      case CameraTimeout():
        print('[LiveView] GetWebRtcUri($profileToken) -> timed out after $timeout');
    }

    return switch (result) {
      CameraSuccess(:final value) => () {
          final port = value['port'];
          final urlText = value['url'];
          if (port is! int || urlText is! String) {
            return CameraFailure<WebRtcTarget>(
              'GetWebRtcUri response missing port/url fields: $value',
            );
          }
          final url = Uri.tryParse(urlText);
          if (url == null) {
            return CameraFailure<WebRtcTarget>('Unparseable signaling url: $urlText');
          }
          return CameraSuccess<WebRtcTarget>(WebRtcTarget(port: port, signalingUrl: url));
        }(),
      CameraFailure(:final reason) => CameraFailure<WebRtcTarget>(reason),
      CameraTimeout() => const CameraTimeout<WebRtcTarget>(),
    };
  }

  /// Independent LAN reachability check, used by [LiveViewController] to tell "camera isn't on
  /// this network" apart from "camera IS on this network, but `GetWebRtcUri`/WebRTC signaling
  /// itself is failing" once the latter has exhausted its own retries — see that class's
  /// `lanReachabilityCheckTimeout` doc for why. Deliberately `AreYouNuraeyeDevice`, not another
  /// `GetWebRtcUri` retry: it's the cheapest authenticated round trip this API already has (a
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
