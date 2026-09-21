import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// Discovery result for `POST /nuraeye/talk-uri` — the camera's two-way-talk connection info.
///
/// There is exactly one talk resource (audio-only, always-on), so unlike
/// `LiveStreamTarget` there is no `profile_token` and no transport choice: the dedicated talk
/// module (`module_rtsps_talk.c`) is TLS-only, so [transport] is always `"rtsps"` and
/// [mediaUri] is always an `rtsps://<camera-ip>:<port>/talk` URL. RTSP-level Digest auth
/// applies (RFC 2617, `realm="ONVIF"`, no `qop`), the same as every other RTSPS listener on
/// this camera — see `RtspTalkSession`.
class TalkTarget {
  const TalkTarget({required this.port, required this.mediaUri});

  /// The actually-bound TCP port for the talk RTSPS listener (560 on current firmware).
  final int port;

  /// `rtsps://<camera-ip>:<port>/talk`.
  final Uri mediaUri;

  @override
  String toString() => 'TalkTarget(port: $port, mediaUri: $mediaUri)';
}

/// LAN-only client for `GetTalkUri` (`POST /nuraeye/talk-uri`). The mobile app's **only**
/// two-way-talk discovery mechanism.
///
/// This replaced the older WebRTC talk path (`{"talk": true}` on `POST /webrtc`) and the
/// never-completed live-view-layered RTSP talk path — both removed 2026-09-11. Talk now runs
/// over its own dedicated RTSPS connection to the port this endpoint reports, completely
/// independent of live view. There is no WAN counterpart (`FR-NE-081` is `Planned`); gate the
/// talk control on LAN connectivity, same as any LAN-only control.
class TalkUriClient {
  TalkUriClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  /// Resolves the talk RTSPS target. `400` from the camera ("Two-way talk unavailable on this
  /// build" — firmware built without `AUDIO_ENABLED`) surfaces as [CameraFailure], not a throw.
  Future<CameraResult<TalkTarget>> getTalkUri({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetTalkUri', timeout: timeout);

    switch (result) {
      case CameraSuccess(:final value):
        print('[Talk] GetTalkUri -> success: $value');
      case CameraFailure(:final reason):
        print('[Talk] GetTalkUri -> failure: $reason');
      case CameraTimeout():
        print('[Talk] GetTalkUri -> timed out after $timeout');
    }

    return switch (result) {
      CameraSuccess(:final value) => () {
          final transportText = value['transport'];
          final port = value['port'];
          final urlText = value['url'];
          if (transportText is! String || port is! int || urlText is! String) {
            return CameraFailure<TalkTarget>(
              'GetTalkUri response missing transport/port/url fields: $value',
            );
          }
          if (transportText != 'rtsps') {
            return CameraFailure<TalkTarget>(
              'GetTalkUri response has unexpected transport: $transportText (expected rtsps)',
            );
          }
          final url = Uri.tryParse(urlText);
          if (url == null) {
            return CameraFailure<TalkTarget>('Unparseable talk url: $urlText');
          }
          return CameraSuccess<TalkTarget>(TalkTarget(port: port, mediaUri: url));
        }(),
      CameraFailure(:final reason) => CameraFailure<TalkTarget>(reason),
      CameraTimeout() => const CameraTimeout<TalkTarget>(),
    };
  }

  void close() => _nuraeye.close();
}
