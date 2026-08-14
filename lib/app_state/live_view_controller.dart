import 'dart:async';
import 'dart:convert';

import 'package:camera_api/camera_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

/// Debug helper for [LiveViewController.startTalk]'s diagnostic logging —
/// pulls the `a=sendrecv`/`a=recvonly`/etc. direction attribute out of the
/// `m=audio` section of a raw SDP string, so the log can show whether the
/// offer/answer actually negotiated a sending audio leg without dumping the
/// entire SDP.
String _extractAudioDirection(String? sdp) {
  if (sdp == null) return '(no sdp)';
  final lines = sdp.split('\r\n');
  final audioIndex = lines.indexWhere((line) => line.startsWith('m=audio'));
  if (audioIndex == -1) return '(no m=audio section)';
  for (var i = audioIndex + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('m=')) break;
    if (line == 'a=sendrecv' ||
        line == 'a=sendonly' ||
        line == 'a=recvonly' ||
        line == 'a=inactive') {
      return line.substring(2);
    }
  }
  return '(no direction attribute found)';
}

enum LiveViewStatus { connecting, connected, reconnecting, failed, stopped }

/// Which transport actually delivered the current/last [LiveViewStatus]
/// `connected` session — [LiveViewStatus] alone doesn't say whether the
/// video came from the LAN WebRTC path or WAN KVS playback, and the UI
/// (`RTCVideoView` vs a plain HLS `VideoPlayerController`) needs to know
/// which. See `STREAMING_GUIDE.md` §1's transport-selection rule.
enum LiveViewTransport { lan, wan }

/// `TWO_WAY_TALK_GUIDE.md` §5's call-style state machine. [busy] is the
/// camera's `HTTP 409` response (another talk session already active) —
/// deliberately distinct from [error], since it means "try again later,"
/// not "something is broken."
enum TalkStatus { idle, connecting, talking, busy, error }

/// LAN WebRTC live-view session for one camera — implements
/// `packages/camera_api/STREAMING_GUIDE.md`'s §2 LAN path end to end:
/// `GetWebRtcUri` discovery, offer/answer signaling (no STUN/TURN — host
/// candidates only, per the guide), a grace window before an ICE
/// `disconnected` blip is treated as a real drop (the guide flags skipping
/// this as a real bug hit before), fresh-offer reconnect on a genuine drop,
/// and a best-effort `POST /webrtc/stop` on teardown even if the session
/// never fully connected (also flagged in the guide — skipping it can leave
/// the camera believing a viewer is still attached).
///
/// One instance per `CameraLiveScreen` visit, not cached/shared — the
/// camera supports exactly one peer connection per signaling port (guide
/// §2.3). Two-way talk ([startTalk]/[endTalk]) also lives here rather than
/// a separate class, precisely because `TWO_WAY_TALK_GUIDE.md` §2 requires
/// renegotiating *this* connection (a fresh offer with `talk: true` against
/// the existing audio transceiver) rather than opening a second one —
/// opening an independent connection for talk was a real bug during this
/// app's own development (the two connections evicted each other in a
/// loop).
class LiveViewController extends ChangeNotifier {
  LiveViewController(this.connection, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final CameraConnection connection;
  final http.Client _http;
  final renderer = RTCVideoRenderer();

  /// Grace window before an ICE `disconnected` state is treated as a real
  /// drop — see STREAMING_GUIDE.md §2.4.
  static const _iceDisconnectGrace = Duration(seconds: 5);

  static const _profileToken = 'Profile_1';

  LiveViewStatus status = LiveViewStatus.connecting;
  String? errorMessage;

  TalkStatus talkStatus = TalkStatus.idle;
  String? talkErrorMessage;

  /// Defaulted on — TWO_WAY_TALK_GUIDE.md §5.2: a quiet earpiece-routed
  /// default reproduces a real "too quiet" complaint this app hit before.
  bool speakerphoneOn = true;

  RTCPeerConnection? _pc;
  MediaStream? _localAudioStream;
  Uri? _signalingUrl;
  Timer? _disconnectGraceTimer;
  bool _rendererInitialized = false;
  bool _disposed = false;

  /// Real, measured inbound video bitrate for the current LAN session —
  /// derived from `RTCPeerConnection.getStats()`'s `inbound-rtp` report
  /// (`bytesReceived` delta over the polling interval), not a stub. Null
  /// until the first two samples land after connecting (one sample alone
  /// can't produce a rate), and reset on every reconnect since a fresh peer
  /// connection means a fresh stats baseline. No WAN equivalent —
  /// STREAMING_GUIDE.md §8 notes HLS gives no equivalent of WebRTC's
  /// `inbound-rtp` stats, so this stays null on WAN.
  double? measuredBitrateKbps;
  Timer? _statsTimer;
  int? _lastStatsBytesReceived;
  double? _lastStatsTimestampMs;

  static const _statsPollInterval = Duration(seconds: 2);

  /// How many more stats-poll ticks should also re-apply the speakerphone
  /// route (see [_applySpeakerphoneRoute]'s doc) — the immediate + 800ms
  /// re-applies in [_handleIceConnectionState] weren't always enough on
  /// real hardware (a route reset reported happening even later than that
  /// on some devices/Android versions); piggybacking a few more attempts
  /// onto the stats timer that's already running covers a later reset
  /// without adding a second timer. Sourced from [_statsPollInterval]'s own
  /// cadence — 5 ticks covers roughly the first 10s of a session.
  int _speakerReapplyTicksRemaining = 0;
  static const _speakerReapplyTicks = 5;

  /// Which transport last reached [LiveViewStatus.connected] — [lan] until
  /// a real WAN session takes over. The UI switches its video widget on
  /// this, not on [status] alone.
  LiveViewTransport transport = LiveViewTransport.lan;

  /// Non-null only while [transport] is [LiveViewTransport.wan] and a
  /// session is live — plays the resolved HLS URL (STREAMING_GUIDE.md §3
  /// step 4). Owned by this controller so it tears down alongside
  /// everything else; the UI just renders it.
  VideoPlayerController? wanVideoController;

  /// Tracks whether `StartCloudStreaming` was actually sent, independent of
  /// [status]/[transport] — STREAMING_GUIDE.md §3 "Ending the session" is
  /// explicit that Stop must be sent even if the session never reached
  /// "playing" (a real bug found in this app: skipping it left the camera
  /// publishing to KVS with no viewer).
  bool _wanStreamStarted = false;
  Timer? _wanHealthTimer;

  /// STREAMING_GUIDE.md §5 — poll cadence for `GetCloudStreamingStatus`
  /// while a WAN session is playing.
  static const _wanHealthCheckInterval = Duration(seconds: 10);

  /// Camera reports this via `GetCapabilities` at onboarding — cached on
  /// [CameraConnection]. An unknown (`null`) value fails open (treated as
  /// capable) per STREAMING_GUIDE.md §1, so an already-onboarded camera
  /// whose capability just hasn't been synced yet isn't wrongly blocked.
  bool get _wanEligible =>
      connection.wanLiveViewCapable != false && connection.thingName != null;

  /// Auto-retry after [_fail] — the camera may come back (e.g. powered back
  /// on) with nobody watching the screen to tap the manual Retry button.
  /// Fixed 10s cadence for the first few attempts (fast recovery for a brief
  /// blip), then backs off to 30s so a camera that's genuinely gone for a
  /// while doesn't get hammered indefinitely.
  Timer? _autoRetryTimer;
  int _retryAttempt = 0;
  static const _autoRetryFastDelay = Duration(seconds: 10);
  static const _autoRetrySlowDelay = Duration(seconds: 30);
  static const _autoRetryFastAttempts = 3;

  /// Orchestrates transport selection per STREAMING_GUIDE.md §1: try LAN
  /// first, only fall back to WAN after a genuine LAN failure (never by
  /// comparing IP addresses or guessing from network type), and skip WAN
  /// entirely for a camera known not to support it ([_wanEligible]).
  Future<void> connect() async {
    if (_disposed) return;
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
    status = LiveViewStatus.connecting;
    errorMessage = null;
    notifyListeners();

    if (await _connectLan()) return;
    if (_disposed) return;

    if (_wanEligible && await _connectWan()) return;
    if (_disposed) return;

    _fail(errorMessage ?? 'Could not connect to the camera');
  }

  /// LAN WebRTC path (STREAMING_GUIDE.md §2). Returns true and leaves
  /// [status] as [LiveViewStatus.connected] on success; on failure, sets
  /// [errorMessage] and returns false without touching [status] — the
  /// caller ([connect]) decides whether a WAN attempt follows or this is
  /// the final failure.
  Future<bool> _connectLan() async {
    if (!_rendererInitialized) {
      await renderer.initialize();
      _rendererInitialized = true;
    }
    if (_disposed) return false;

    // iOS-only (no-op elsewhere, see AppleNativeAudioManagement's own
    // platform check): configures AVAudioSession for receive-only remote
    // audio playback before the peer connection exists. Without this, the
    // native WebRTC audio engine renders against an unconfigured session —
    // reproduced as a real SIGSEGV inside WebRTC's own audio unit callback
    // (crash report 2026-08-14, iOS Simulator) once the remote audio track
    // went live.
    await AppleNativeAudioManagement.setAppleAudioConfiguration(
      AppleNativeAudioManagement.getAppleAudioConfigurationForMode(
        AppleAudioIOMode.remoteOnly,
      ),
    );
    if (_disposed) return false;

    final nuraeye = NuraeyeClient(connection);
    final result = await WebRtcUriClient(nuraeye).getWebRtcUri(_profileToken);
    nuraeye.close();
    if (_disposed) return false;

    final WebRtcTarget target;
    switch (result) {
      case CameraSuccess(:final value):
        target = value;
      case CameraFailure(:final reason):
        errorMessage = reason;
        return false;
      case CameraTimeout():
        errorMessage = 'Timed out reaching the camera';
        return false;
    }

    _signalingUrl = target.signalingUrl;

    try {
      // No STUN/TURN — this is a same-LAN connection with host candidates
      // only (guide §2.2).
      final pc = await createPeerConnection({'iceServers': <dynamic>[]});
      if (_disposed) {
        await pc.close();
        return false;
      }
      _pc = pc;

      pc.onTrack = (event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          renderer.srcObject = event.streams.first;
          notifyListeners();
        }
      };
      pc.onIceConnectionState = _handleIceConnectionState;

      // recvonly on both to start — plain live view never sends. [startTalk]
      // renegotiates the audio one to sendrecv (fetched fresh from the pc
      // at that point, not held onto from here) rather than adding a
      // second transceiver.
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      final response = await _http
          .post(
            target.signalingUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'type': 'offer',
              'sdp': offer.sdp,
              'talk': false,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (_disposed) return false;

      if (response.statusCode != 200) {
        errorMessage =
            'Camera rejected the connection (${response.statusCode})';
        await _teardownPeerConnection();
        return false;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final answerSdp = body['sdp'] as String?;
      final answerType = body['type'] as String?;
      if (answerSdp == null || answerType == null) {
        errorMessage = 'Malformed answer from camera';
        await _teardownPeerConnection();
        return false;
      }
      await pc.setRemoteDescription(
        RTCSessionDescription(answerSdp, answerType),
      );
      if (_disposed) return false;

      transport = LiveViewTransport.lan;
      status = LiveViewStatus.connected;
      _retryAttempt = 0;
      _startStatsPolling();
      notifyListeners();
      return true;
    } catch (e) {
      if (_disposed) return false;
      errorMessage = e.toString();
      await _teardownPeerConnection();
      return false;
    }
  }

  void _fail(String reason) {
    status = LiveViewStatus.failed;
    errorMessage = reason;
    notifyListeners();
    _scheduleAutoRetry();
  }

  void _scheduleAutoRetry() {
    _autoRetryTimer?.cancel();
    final delay = _retryAttempt < _autoRetryFastAttempts
        ? _autoRetryFastDelay
        : _autoRetrySlowDelay;
    _retryAttempt++;
    _autoRetryTimer = Timer(delay, () {
      _autoRetryTimer = null;
      if (!_disposed && status == LiveViewStatus.failed) {
        unawaited(connect());
      }
    });
  }

  void _handleIceConnectionState(RTCIceConnectionState state) {
    if (_disposed) return;
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        _disconnectGraceTimer?.cancel();
        _disconnectGraceTimer = null;
        if (status != LiveViewStatus.connected) {
          status = LiveViewStatus.connected;
          notifyListeners();
        }
        // Applying this at signaling time (right after setRemoteDescription)
        // isn't reliable — the native WebRTC audio device module does its
        // own routing setup once media actually starts flowing, which can
        // happen *after* signaling and silently reset the route back to the
        // earpiece. Re-applying here, once ICE is actually connected and
        // audio is genuinely flowing, plus once more after a short delay
        // (some devices apply the ADM's own routing decision a beat later
        // still) is what reliably sticks.
        unawaited(_applySpeakerphoneRoute());
        unawaited(
          Future.delayed(
            const Duration(milliseconds: 800),
            _applySpeakerphoneRoute,
          ),
        );
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        // A momentary `disconnected` is routine on a no-STUN/TURN LAN
        // connection (WebRTC's own periodic consent-freshness check) — give
        // it a few seconds to self-recover before treating it as a real
        // drop. See STREAMING_GUIDE.md §2.4.
        _disconnectGraceTimer ??= Timer(_iceDisconnectGrace, () {
          _disconnectGraceTimer = null;
          if (!_disposed) unawaited(_reconnect());
        });
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        _disconnectGraceTimer?.cancel();
        _disconnectGraceTimer = null;
        unawaited(_reconnect());
      case RTCIceConnectionState.RTCIceConnectionStateNew:
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
      case RTCIceConnectionState.RTCIceConnectionStateCount:
        break;
    }
  }

  /// WebRTC's default audio route is the phone's quiet earpiece speaker,
  /// not the loudspeaker — without forcing this, the camera's audio plays
  /// but is barely audible unless the phone is held to your ear. Same
  /// reasoning `TWO_WAY_TALK_GUIDE.md` §5.2 documents for talk specifically,
  /// applied here to plain live view too. See the call sites in
  /// [_handleIceConnectionState] for why this needs re-applying rather than
  /// a single call right after signaling.
  Future<void> _applySpeakerphoneRoute() async {
    if (_disposed) return;
    try {
      await Helper.setSpeakerphoneOn(speakerphoneOn);
    } catch (_) {
      // Best-effort — a platform-level audio routing failure shouldn't
      // block the connection itself.
    }
  }

  Future<void> _reconnect() async {
    if (_disposed) return;
    status = LiveViewStatus.reconnecting;
    notifyListeners();
    await _teardownPeerConnection();
    await _stopWanIfNeeded();
    if (!_disposed) await connect();
  }

  Future<void> _teardownPeerConnection() async {
    final pc = _pc;
    _pc = null;
    if (pc != null) {
      pc.onTrack = null;
      pc.onIceConnectionState = null;
      await pc.close();
    }
    _stopStatsPolling();
  }

  void _startStatsPolling() {
    _stopStatsPolling();
    _speakerReapplyTicksRemaining = _speakerReapplyTicks;
    _statsTimer = Timer.periodic(
      _statsPollInterval,
      (_) => unawaited(_pollBitrate()),
    );
  }

  void _stopStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _lastStatsBytesReceived = null;
    _lastStatsTimestampMs = null;
    if (measuredBitrateKbps != null) {
      measuredBitrateKbps = null;
      if (!_disposed) notifyListeners();
    }
  }

  /// One `getStats()` sample — computes a rate from the delta against the
  /// previous sample, so the first tick after (re)connecting only seeds the
  /// baseline and doesn't yet update [measuredBitrateKbps].
  Future<void> _pollBitrate() async {
    final pc = _pc;
    if (_disposed || pc == null) return;
    if (_speakerReapplyTicksRemaining > 0) {
      _speakerReapplyTicksRemaining--;
      unawaited(_applySpeakerphoneRoute());
    }
    try {
      final reports = await pc.getStats();
      for (final report in reports) {
        if (report.type != 'inbound-rtp') continue;
        final kind = report.values['kind'] ?? report.values['mediaType'];
        if (kind != 'video') continue;
        final bytesReceivedRaw = report.values['bytesReceived'];
        if (bytesReceivedRaw is! num) continue;
        final bytesReceived = bytesReceivedRaw.toInt();
        final timestampMs = report.timestamp;

        final prevBytes = _lastStatsBytesReceived;
        final prevTimestampMs = _lastStatsTimestampMs;
        _lastStatsBytesReceived = bytesReceived;
        _lastStatsTimestampMs = timestampMs;

        if (prevBytes != null && prevTimestampMs != null) {
          final deltaBytes = bytesReceived - prevBytes;
          final deltaSeconds = (timestampMs - prevTimestampMs) / 1000;
          if (deltaSeconds > 0 && deltaBytes >= 0) {
            measuredBitrateKbps = (deltaBytes * 8) / 1000 / deltaSeconds;
            if (!_disposed) notifyListeners();
          }
        }
        return;
      }
    } catch (_) {
      // Best-effort — stats aren't critical to the connection itself.
    }
  }

  /// Wraps `AwsWanLiveViewClient.getCloudStreamingStatus()` — unlike its
  /// three sibling methods on that same class, it doesn't catch
  /// `IotCommandClient`'s relay/transport exceptions internally (a real
  /// crash hit on-device: an unhandled `SocketException` when the phone had
  /// no network path to the relay at all). Every other WAN call site in
  /// this file already gets `CameraFailure` back for that case instead of a
  /// thrown exception; this normalizes the one that doesn't, without
  /// needing to change `camera_api` itself.
  Future<CameraResult<StreamStatus>> _getCloudStreamingStatus(
    AwsWanLiveViewClient client,
  ) async {
    try {
      return await client.getCloudStreamingStatus();
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  /// WAN path (STREAMING_GUIDE.md §3's four-step sequence). Returns true
  /// and leaves [status]/[transport] set on success; on failure, sets
  /// [errorMessage] and returns false, same contract as [_connectLan].
  /// Only called when [_wanEligible].
  Future<bool> _connectWan() async {
    final thingName = connection.thingName;
    if (thingName == null) return false;
    final client = AwsWanLiveViewClient(thingName);

    final startResult = await client.startCloudStreaming();
    if (_disposed) return false;
    if (startResult is! CameraSuccess) {
      errorMessage = 'Could not reach this camera remotely';
      return false;
    }
    // Independent of status/transport from here — STREAMING_GUIDE.md §3
    // "Ending the session" requires Stop to be sent even if the rest of
    // this sequence never completes.
    _wanStreamStarted = true;

    // Step 2 — `idle` is a normal transient state right after Start while
    // the substream spins up; retry before treating it as a real problem.
    // (`AwsWanLiveViewClient.getCloudStreamingStatus` already retries a
    // couple of times internally on transient `idle` — this outer loop
    // covers the longer spin-up window a fresh Start can still need.)
    var active = false;
    for (var attempt = 0; attempt < 5 && !_disposed; attempt++) {
      final statusResult = await _getCloudStreamingStatus(client);
      if (statusResult case CameraSuccess(:final value)) {
        if (value == StreamStatus.active) {
          active = true;
          break;
        }
        if (value == StreamStatus.notCompiled) {
          errorMessage = 'This camera does not support remote viewing';
          return false;
        }
      }
      if (attempt < 4) await Future.delayed(const Duration(seconds: 2));
    }
    if (_disposed) return false;
    if (!active) {
      errorMessage = 'Camera is not streaming to the cloud right now';
      return false;
    }

    // Step 3 — resolve a playable URL, retrying a few times since the
    // substream can still be spinning up for a few seconds after `active`.
    Uri? playbackUri;
    for (var attempt = 0; attempt < 3 && !_disposed; attempt++) {
      final uriResult = await client.resolvePlaybackUri();
      if (uriResult case CameraSuccess(:final value)) {
        playbackUri = value;
        break;
      }
      if (attempt < 2) await Future.delayed(const Duration(seconds: 2));
    }
    if (_disposed) return false;
    if (playbackUri == null) {
      errorMessage = 'Could not start remote playback';
      return false;
    }

    // Step 4 — play the resolved HLS URL.
    if (!await _playWanUrl(playbackUri)) {
      errorMessage = 'Could not play the remote stream';
      return false;
    }
    if (_disposed) return false;

    transport = LiveViewTransport.wan;
    status = LiveViewStatus.connected;
    _retryAttempt = 0;
    notifyListeners();
    _startWanHealthMonitor();
    return true;
  }

  /// Initializes and starts playback of [uri] on [wanVideoController],
  /// disposing whatever controller was there before. Returns whether
  /// playback actually started.
  Future<bool> _playWanUrl(Uri uri) async {
    final videoController = VideoPlayerController.networkUrl(uri);
    try {
      await videoController.initialize();
    } catch (_) {
      await videoController.dispose();
      return false;
    }
    if (_disposed) {
      await videoController.dispose();
      return false;
    }
    await videoController.setLooping(true);
    await videoController.play();
    final oldController = wanVideoController;
    wanVideoController = videoController;
    if (oldController != null) unawaited(oldController.dispose());
    return true;
  }

  void _startWanHealthMonitor() {
    _wanHealthTimer?.cancel();
    _wanHealthTimer = Timer.periodic(
      _wanHealthCheckInterval,
      (_) => unawaited(_checkWanHealth()),
    );
  }

  /// STREAMING_GUIDE.md §5 — two separate watchers, since WAN has no single
  /// live push signal the way LAN's ICE state is one: a cheap LAN
  /// reachability probe first each tick (switch back to LAN the moment the
  /// phone is back on the camera's network, before spending a paid
  /// AWS/Lambda call), then `GetCloudStreamingStatus` itself.
  Future<void> _checkWanHealth() async {
    if (_disposed ||
        transport != LiveViewTransport.wan ||
        status != LiveViewStatus.connected) {
      return;
    }

    final nuraeye = NuraeyeClient(connection);
    final bool reachableOnLan;
    try {
      reachableOnLan = await WebRtcUriClient(nuraeye).checkReachable();
    } finally {
      nuraeye.close();
    }
    if (_disposed || transport != LiveViewTransport.wan) return;
    if (reachableOnLan) {
      unawaited(_reconnect());
      return;
    }

    final thingName = connection.thingName;
    if (thingName == null) return;
    final result = await _getCloudStreamingStatus(
      AwsWanLiveViewClient(thingName),
    );
    if (_disposed || transport != LiveViewTransport.wan) return;
    switch (result) {
      case CameraSuccess(:final value) when value == StreamStatus.active:
        return; // Healthy — nothing to do this tick.
      case CameraSuccess(:final value) when value == StreamStatus.notCompiled:
        await _stopWanIfNeeded();
        _fail('This camera no longer supports remote viewing');
      case CameraSuccess():
        // idle/degraded — the camera-side producer likely restarted (a
        // mic on/off toggle is one real trigger, §6). Re-resolve a fresh
        // playback URL rather than assuming the already-issued one still
        // works — §5's known gap is trusting a stale URL indefinitely.
        unawaited(_recoverWanPlayback());
      case CameraFailure():
      case CameraTimeout():
        // Transient relay hiccup — leave the current session alone and
        // try again next tick rather than tearing down on one bad poll.
        break;
    }
  }

  /// Re-resolves and switches to a fresh playback URL without a full
  /// Start/Stop cycle — the guide's "same URL is fine" assumption doesn't
  /// hold across a camera-initiated producer restart, but a *fresh*
  /// `resolvePlaybackUri` does. Falls through to a full [_reconnect] (a
  /// fresh §3 sequence from Step 1) if even that fails, per §5's explicit
  /// recommendation rather than looping a stale URL indefinitely.
  Future<void> _recoverWanPlayback() async {
    if (_disposed || transport != LiveViewTransport.wan) return;
    final thingName = connection.thingName;
    if (thingName == null) return;
    final client = AwsWanLiveViewClient(thingName);

    Uri? playbackUri;
    for (var attempt = 0; attempt < 3 && !_disposed; attempt++) {
      final result = await client.resolvePlaybackUri();
      if (result case CameraSuccess(:final value)) {
        playbackUri = value;
        break;
      }
      if (attempt < 2) await Future.delayed(const Duration(seconds: 2));
    }
    if (_disposed || transport != LiveViewTransport.wan) return;

    if (playbackUri == null || !await _playWanUrl(playbackUri)) {
      unawaited(_reconnect());
      return;
    }
    notifyListeners();
  }

  /// Tears down the WAN session, if one was started — cancels health
  /// polling, disposes the player, and sends `StopCloudStreaming`.
  /// **Sends Stop even if [_wanStreamStarted] is the only surviving fact**
  /// (status/transport may have already moved on) — see STREAMING_GUIDE.md
  /// §3's "Ending the session", and [_wanStreamStarted]'s own doc comment.
  /// Prefers the LAN stop call when the camera is reachable right now, to
  /// avoid an unnecessary AWS/Lambda round trip.
  Future<void> _stopWanIfNeeded() async {
    if (!_wanStreamStarted) return;
    _wanStreamStarted = false;
    _wanHealthTimer?.cancel();
    _wanHealthTimer = null;
    final controller = wanVideoController;
    wanVideoController = null;
    if (controller != null) {
      try {
        await controller.pause();
      } catch (_) {
        // Best-effort — nothing more to do if the player's already broken.
      }
      unawaited(controller.dispose());
    }

    final nuraeye = NuraeyeClient(connection);
    try {
      final lanResult = await CloudStreamingLanClient(
        nuraeye,
      ).stopCloudStreaming(timeout: const Duration(seconds: 3));
      if (lanResult is CameraSuccess) return;
    } finally {
      nuraeye.close();
    }

    final thingName = connection.thingName;
    if (thingName == null) return;
    try {
      await AwsWanLiveViewClient(thingName).stopCloudStreaming();
    } catch (_) {
      // Best-effort — nothing more to do if the camera/relay is
      // unreachable at teardown time.
    }
  }

  /// Mutes/unmutes the received remote audio track — a real live-audio
  /// mute, distinct from the dummy-asset fallback's `VideoPlayerController`
  /// volume control.
  void setAudioEnabled(bool enabled) {
    for (final track in renderer.srcObject?.getAudioTracks() ?? const []) {
      track.enabled = enabled;
    }
  }

  MediaStreamTrack? get _remoteVideoTrack {
    final tracks = renderer.srcObject?.getVideoTracks();
    return (tracks == null || tracks.isEmpty) ? null : tracks.first;
  }

  /// Captures the current frame straight from the remote video track
  /// (`MediaStreamTrack.captureFrame()`, native-side) — not a
  /// `RenderRepaintBoundary` screenshot of the video widget, which is
  /// unreliable for a platform-view/texture-backed `RTCVideoView`. Returns
  /// null if there's no remote track yet (not connected).
  Future<Uint8List?> captureSnapshot() async {
    final track = _remoteVideoTrack;
    if (track == null) return null;
    try {
      final buffer = await track.captureFrame();
      return buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  final _recorder = MediaRecorder();
  bool _isRecording = false;

  /// Starts native recording of the remote video (+ rendered/`OUTPUT`
  /// audio) track straight to [path], returning whether it actually
  /// started (false if there's no remote track yet). **Known limitation,
  /// not yet hardware-verified**: if the connection drops and
  /// auto-reconnects (a fresh `RTCPeerConnection`, see [_reconnect]) while a
  /// recording is in flight, the recorder still references the old
  /// connection's track — [stopRecording] may then fail or produce a
  /// truncated file. No mid-recording-reconnect recovery is implemented.
  Future<bool> startRecording(String path) async {
    final track = _remoteVideoTrack;
    if (track == null) return false;
    try {
      await _recorder.start(
        path,
        videoTrack: track,
        audioChannel: RecorderAudioChannel.OUTPUT,
      );
      _isRecording = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    try {
      await _recorder.stop();
    } catch (_) {
      // Best-effort — nothing more to do if the underlying track/connection
      // is already gone.
    }
  }

  /// Starts a two-way-talk session by renegotiating the existing connection
  /// (`TWO_WAY_TALK_GUIDE.md` §2/§3) — grabs the phone mic, attaches it to
  /// the audio transceiver (switched from recvonly to sendrecv), and sends
  /// a fresh offer with `talk: true`. Requires [status] to already be
  /// [LiveViewStatus.connected]; no-op otherwise.
  Future<void> startTalk() async {
    if (_disposed ||
        status != LiveViewStatus.connected ||
        _pc == null ||
        _signalingUrl == null) {
      return;
    }

    talkStatus = TalkStatus.connecting;
    talkErrorMessage = null;
    notifyListeners();

    try {
      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      if (_disposed) {
        for (final track in localStream.getTracks()) {
          await track.stop();
        }
        return;
      }

      final pc = _pc;
      final signalingUrl = _signalingUrl;
      if (pc == null ||
          signalingUrl == null ||
          status != LiveViewStatus.connected) {
        for (final track in localStream.getTracks()) {
          await track.stop();
        }
        _failTalk('Connection changed — try again');
        return;
      }

      // Fetch the audio transceiver fresh from the peer connection right
      // now, rather than trusting any `RTCRtpTransceiver` object stored
      // earlier (from `connect()`'s `addTransceiver` call, potentially
      // minutes ago) — holding onto that Dart-side handle across time hit a
      // real crash on Android ("RtpTransceiver has been disposed" from
      // `setDirection`, native-side object churn `flutter_webrtc` doesn't
      // guarantee survives). A transceiver's `receiver.track.kind` is fixed
      // for its lifetime, so this reliably finds "the audio one" without
      // relying on list order.
      RTCRtpTransceiver? audioTransceiver;
      for (final transceiver in await pc.getTransceivers()) {
        if (transceiver.receiver.track?.kind == 'audio') {
          audioTransceiver = transceiver;
          break;
        }
      }
      if (audioTransceiver == null) {
        for (final track in localStream.getTracks()) {
          await track.stop();
        }
        _failTalk('No audio channel on this connection — try again');
        return;
      }
      _localAudioStream = localStream;

      final localAudioTrack = localStream.getAudioTracks().first;
      // ignore: avoid_print
      print(
        '[Talk] local mic track: id=${localAudioTrack.id} '
        'enabled=${localAudioTrack.enabled} muted=${localAudioTrack.muted}',
      );

      await audioTransceiver.sender.replaceTrack(localAudioTrack);
      await audioTransceiver.setDirection(TransceiverDirection.SendRecv);
      // ignore: avoid_print
      print(
        '[Talk] transceiver direction after setDirection: '
        '${await audioTransceiver.getDirection()}, '
        'sender track id=${audioTransceiver.sender.track?.id}',
      );

      // Now sending *and* receiving audio — reconfigure the iOS session
      // accordingly (see `connect()`'s own comment on why this matters at
      // all).
      await AppleNativeAudioManagement.setAppleAudioConfiguration(
        AppleNativeAudioManagement.getAppleAudioConfigurationForMode(
          AppleAudioIOMode.localAndRemote,
          preferSpeakerOutput: speakerphoneOn,
        ),
      );

      final offer = await pc.createOffer();
      // ignore: avoid_print
      print(
        '[Talk] offer audio direction line: '
        '${_extractAudioDirection(offer.sdp)}',
      );
      await pc.setLocalDescription(offer);

      final response = await _http
          .post(
            signalingUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'type': 'offer', 'sdp': offer.sdp, 'talk': true}),
          )
          .timeout(const Duration(seconds: 10));
      if (_disposed) return;
      // ignore: avoid_print
      print('[Talk] signaling response: ${response.statusCode}');

      // TWO_WAY_TALK_GUIDE.md §4 — a 409 means another talk session already
      // holds the camera's speaker; the *existing* live-view connection is
      // left untouched server-side, but our own local offer was never
      // answered, so roll it back to the last stable state rather than
      // leaving this peer connection's signaling state stuck.
      if (response.statusCode == 409) {
        await pc.setLocalDescription(RTCSessionDescription(null, 'rollback'));
        await _releaseLocalAudio();
        talkStatus = TalkStatus.busy;
        notifyListeners();
        return;
      }
      if (response.statusCode != 200) {
        await pc.setLocalDescription(RTCSessionDescription(null, 'rollback'));
        await _releaseLocalAudio();
        _failTalk('Camera rejected the request (${response.statusCode})');
        return;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final answerSdp = body['sdp'] as String?;
      final answerType = body['type'] as String?;
      if (answerSdp == null || answerType == null) {
        await pc.setLocalDescription(RTCSessionDescription(null, 'rollback'));
        await _releaseLocalAudio();
        _failTalk('Malformed answer from camera');
        return;
      }
      // ignore: avoid_print
      print(
        '[Talk] answer audio direction line: '
        '${_extractAudioDirection(answerSdp)}',
      );
      await pc.setRemoteDescription(
        RTCSessionDescription(answerSdp, answerType),
      );
      if (_disposed) return;

      // See _applySpeakerphoneRoute's doc comment — a single call right
      // after signaling isn't reliable, the native audio device module can
      // reset the route once media actually starts flowing.
      unawaited(_applySpeakerphoneRoute());
      unawaited(
        Future.delayed(
          const Duration(milliseconds: 800),
          _applySpeakerphoneRoute,
        ),
      );
      talkStatus = TalkStatus.talking;
      notifyListeners();
    } catch (e) {
      if (!_disposed) {
        await _releaseLocalAudio();
        _failTalk(e.toString());
      }
    }
  }

  void _failTalk(String reason) {
    talkStatus = TalkStatus.error;
    talkErrorMessage = reason;
    notifyListeners();
  }

  /// Route-to-loudspeaker toggle, live during an active talk session —
  /// TWO_WAY_TALK_GUIDE.md §5.2. Distinct from [setAudioEnabled], which
  /// mutes plain live-view playback, not an active call.
  Future<void> setSpeakerphoneOn(bool enabled) async {
    speakerphoneOn = enabled;
    await Helper.setSpeakerphoneOn(enabled);
    notifyListeners();
  }

  Future<void> _releaseLocalAudio() async {
    final stream = _localAudioStream;
    _localAudioStream = null;
    if (stream == null) return;
    for (final track in stream.getTracks()) {
      await track.stop();
    }
  }

  /// Ends the talk session. **Per TWO_WAY_TALK_GUIDE.md §3, `POST
  /// /webrtc/stop` tears down the entire connection, not just the talk
  /// leg** — so if talk actually reached [TalkStatus.talking], this ends
  /// live view too; callers should [connect] again afterward if they want
  /// live view to keep playing. Closing out of a [TalkStatus.busy] or
  /// [TalkStatus.error] state (talk was never actually granted) only
  /// resets local state — the live-view connection was never touched.
  Future<void> endTalk() async {
    if (talkStatus == TalkStatus.idle) return;
    final wasTalking = talkStatus == TalkStatus.talking;
    await _releaseLocalAudio();
    talkStatus = TalkStatus.idle;
    talkErrorMessage = null;
    if (!_disposed) notifyListeners();
    if (wasTalking) await stop();
  }

  /// Ends the session — best-effort `POST /webrtc/stop`, sent even if the
  /// session never reached [LiveViewStatus.connected] (see this class's own
  /// doc comment for why).
  Future<void> stop() async {
    if (_disposed) return;
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = null;
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
    await stopRecording();
    await _releaseLocalAudio();
    talkStatus = TalkStatus.idle;
    await _teardownPeerConnection();
    final signalingUrl = _signalingUrl;
    if (signalingUrl != null) {
      try {
        await _http
            .post(signalingUrl.replace(path: '${signalingUrl.path}/stop'))
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best-effort — nothing more to do if the camera is already
        // unreachable at teardown time.
      }
    }
    await _stopWanIfNeeded();
    if (_disposed) return;
    status = LiveViewStatus.stopped;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _disconnectGraceTimer?.cancel();
    _autoRetryTimer?.cancel();
    _wanHealthTimer?.cancel();
    _statsTimer?.cancel();
    unawaited(_releaseLocalAudio());
    unawaited(_teardownPeerConnection());
    unawaited(_stopWanIfNeeded());
    if (_rendererInitialized) unawaited(renderer.dispose());
    super.dispose();
  }
}
