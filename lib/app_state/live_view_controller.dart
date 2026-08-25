import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:camera_api/camera_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
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
  /// [initialProfile] — one of [_profileLadder] (`Profile_1`/`Profile_2`/
  /// `Profile_3`), defaulting to the highest-resolution `Profile_1` if
  /// omitted. Lets a caller that already knows it only has a small display
  /// budget for this session (e.g. a Multiview grid tile) start below full
  /// resolution instead of connecting at `Profile_1` and immediately
  /// stepping down — the automatic ladder in [_maybeStepDownProfile]/
  /// [_maybeStepUpProfile] still applies on top of whatever this starts at.
  LiveViewController(
    this.connection, {
    http.Client? httpClient,
    String? initialProfile,
    this.forceTransport,
  }) : _http = httpClient ?? http.Client(),
       _profileToken =
           (initialProfile != null && _profileLadder.contains(initialProfile))
           ? initialProfile
           : _profileLadder.first;

  final CameraConnection connection;
  final http.Client _http;
  final renderer = RTCVideoRenderer();

  /// Grace window before an ICE `disconnected` state is treated as a real
  /// drop — see STREAMING_GUIDE.md §2.4.
  static const _iceDisconnectGrace = Duration(seconds: 5);

  /// How long the LAN discovery probe (`GetWebRtcUri`) waits before deciding
  /// the camera isn't reachable on this network — tuned against real WiFi
  /// testing (matches the sibling `nuraeye-rt` app's `lanProbeTimeout`): long
  /// enough to absorb normal same-subnet variance, short enough that a phone
  /// genuinely off the camera's LAN doesn't wait needlessly before WAN is
  /// even attempted.
  static const _lanProbeTimeout = Duration(seconds: 4);

  /// How many times [_connectLan] retries `GetWebRtcUri` before falling
  /// through to [_handleLanExhausted]'s reachability recheck.
  static const _maxLanReconnectAttempts = 1;
  static const _lanRetryPollInterval = Duration(seconds: 1);

  /// Once `GetWebRtcUri` has exhausted its retries, how long the independent
  /// `AreYouNuraeyeDevice` reachability probe waits — distinguishes "camera
  /// isn't on this network at all" (falls to WAN) from "camera IS on this
  /// network but the signaling call itself glitched" (retries LAN instead of
  /// wrongly falling back to the much-higher-latency WAN path).
  static const _lanReachabilityCheckTimeout = Duration(seconds: 5);

  /// WebRTC signaling POST timeout — tightened from an earlier unbounded/10s
  /// value; a genuinely-unreachable-mid-negotiation camera should fail out
  /// quickly enough for reconnect/fallback logic to actually kick in.
  static const _webrtcSignalingTimeout = Duration(seconds: 5);

  /// Bound on waiting for ICE gathering to complete before sending the offer
  /// — see [_negotiate]'s doc comment for why this step exists at all.
  static const _iceGatheringTimeout = Duration(seconds: 3);

  /// `Profile_1` (highest resolution) down to `Profile_3` (lowest) — this
  /// firmware's fixed, compile-time profile set. [_profileToken] steps down
  /// this ladder on sustained LAN trouble and back up once the link recovers
  /// — see [_maybeStepDownProfile]/[_maybeStepUpProfile].
  static const _profileLadder = ['Profile_1', 'Profile_2', 'Profile_3'];
  String _profileToken;

  /// Recent ICE drops within [_lanTroubleWindow] — [_lanTroubleThreshold] or
  /// more within that window steps the resolution ladder down a tier instead
  /// of just reconnecting at the same (evidently struggling) profile.
  final List<DateTime> _recentLanDrops = [];
  static const _lanTroubleWindow = Duration(minutes: 2);
  static const _lanTroubleThreshold = 3;

  /// Stats-based trouble detection — catches a session that stays nominally
  /// ICE-`connected` while actually stalled/starved, which ICE state alone
  /// never sees. See [_pollBitrate].
  int _stallPollCount = 0;
  int _lowBitratePollCount = 0;
  int _healthyPollCount = 0;
  static const _stallPollThreshold = 3;
  static const _lowBitrateThresholdKbps = 100.0;
  static const _lowBitratePollThreshold = 3;
  static const _healthyPollThreshold = 10;

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
  int? _lastFramesDecoded;

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

  /// Test-only manual transport override (see `DebugTransportOverride`'s
  /// doc) — `null` is normal automatic LAN-first/WAN-fallback behavior.
  /// [LiveViewTransport.wan] skips the LAN attempt entirely in [connect]
  /// and stops [_checkWanHealth] from ever switching back to LAN just
  /// because the camera happens to be reachable there; [LiveViewTransport.lan]
  /// stops [connect] from falling back to WAN when the LAN attempt fails.
  final LiveViewTransport? forceTransport;

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

  /// The URI [wanVideoController] is currently (or was last) playing —
  /// distinct from the health monitor's `GetCloudStreamingStatus` check,
  /// this backs [_pollWanStall]'s local-first recovery: a purely phone-side
  /// HLS hiccup (decoder stall, a blip to the CloudFront/S3 endpoint) with a
  /// perfectly healthy camera-side stream doesn't need a fresh AWS resolve,
  /// just a local re-init against the same still-valid URL.
  Uri? _lastWanPlaybackUri;
  Timer? _wanStallTimer;
  Duration? _lastWanPosition;
  int _wanStallPollCount = 0;
  static const _wanStallPollInterval = Duration(seconds: 3);
  static const _wanStallThreshold = 3;

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
  /// entirely for a camera known not to support it ([_wanEligible]). See
  /// [forceTransport]'s doc for the test-only override this defers to
  /// before any of that normal logic runs.
  Future<void> connect() async {
    if (_disposed) return;
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
    status = LiveViewStatus.connecting;
    errorMessage = null;
    notifyListeners();

    if (forceTransport == LiveViewTransport.wan) {
      if (_wanEligible && await _connectWan()) return;
      if (_disposed) return;
      _fail(
        errorMessage ?? 'Could not connect to the camera over WAN (forced)',
      );
      return;
    }

    if (await _connectLan()) return;
    if (_disposed) return;

    if (forceTransport == LiveViewTransport.lan) {
      _fail(errorMessage ?? 'Could not connect to the camera (forced LAN)');
      return;
    }

    if (_wanEligible && await _connectWan()) return;
    if (_disposed) return;

    _fail(errorMessage ?? 'Could not connect to the camera');
  }

  /// `RECORD_AUDIO`/`BLUETOOTH_CONNECT` are Android *runtime* permissions
  /// (API 23+/31+) — a manifest `<uses-permission>` declaration alone is not
  /// enough. `flutter_webrtc`'s native audio device module can crash the
  /// whole process (not a catchable Dart exception) if it touches
  /// audio-routing/Bluetooth APIs without these actually granted, even for
  /// a recvonly-only (non-talk) live-view session — the ADM initializes
  /// audio routing regardless of transceiver direction. Requested here, not
  /// at app startup, so the user only sees the permission prompt when they
  /// actually open live view.
  Future<void> _ensureRuntimePermissions() async {
    if (!Platform.isAndroid) return;
    await [Permission.microphone, Permission.bluetoothConnect].request();
  }

  /// LAN WebRTC path (STREAMING_GUIDE.md §2). Retries `GetWebRtcUri` up to
  /// [_maxLanReconnectAttempts] times before falling through to
  /// [_handleLanExhausted]'s independent reachability recheck — a single
  /// transient failure no longer sends this straight to the much
  /// higher-latency WAN path. Returns true and leaves [status] as
  /// [LiveViewStatus.connected] on success; on failure, sets [errorMessage]
  /// and returns false without touching [status] — the caller ([connect])
  /// decides whether a WAN attempt follows or this is the final failure.
  Future<bool> _connectLan() async {
    await _ensureRuntimePermissions();
    if (_disposed) return false;

    if (!_rendererInitialized) {
      await renderer.initialize();
      _rendererInitialized = true;
    }
    if (_disposed) return false;

    return _tryLan(attempt: 0);
  }

  Future<bool> _tryLan({
    required int attempt,
    bool afterReachabilityRecheck = false,
  }) async {
    if (_disposed) return false;

    final nuraeye = NuraeyeClient(connection);
    final result = await WebRtcUriClient(
      nuraeye,
    ).getWebRtcUri(_profileToken, timeout: _lanProbeTimeout);
    nuraeye.close();
    if (_disposed) return false;

    final WebRtcTarget target;
    final String failureReason;
    switch (result) {
      case CameraSuccess(:final value):
        target = value;
        return _negotiate(target.signalingUrl, talk: false);
      case CameraFailure(:final reason):
        failureReason = reason;
      case CameraTimeout():
        failureReason = 'Timed out reaching the camera';
    }

    if (attempt < _maxLanReconnectAttempts) {
      await Future.delayed(_lanRetryPollInterval);
      if (_disposed) return false;
      return _tryLan(
        attempt: attempt + 1,
        afterReachabilityRecheck: afterReachabilityRecheck,
      );
    }
    // Already gave this one extra shot after confirming the camera was
    // reachable — stop here and let the outer connect()/auto-retry cadence
    // (not a tight recursive loop) handle any further attempts.
    if (afterReachabilityRecheck) {
      errorMessage = failureReason;
      return false;
    }
    return _handleLanExhausted(failureReason);
  }

  /// `GetWebRtcUri` has exhausted its retries — before treating that as
  /// "camera isn't on this network" and falling to WAN, confirm that verdict
  /// with one cheap, independent reachability probe (`AreYouNuraeyeDevice`).
  /// A camera that's still genuinely on this LAN gets one more LAN attempt
  /// instead of being needlessly bounced to the much higher-latency WAN path
  /// on what was actually just a signaling hiccup.
  Future<bool> _handleLanExhausted(String lanFailureReason) async {
    if (_disposed) return false;

    final nuraeye = NuraeyeClient(connection);
    final bool reachable;
    try {
      reachable = await WebRtcUriClient(
        nuraeye,
      ).checkReachable(timeout: _lanReachabilityCheckTimeout);
    } finally {
      nuraeye.close();
    }
    if (_disposed) return false;

    if (reachable) {
      return _tryLan(attempt: 0, afterReachabilityRecheck: true);
    }

    errorMessage = lanFailureReason;
    return false;
  }

  /// Negotiates a brand-new `RTCPeerConnection` against [signalingUrl] —
  /// plain live view (`talk: false`) or with talk's sendrecv audio leg
  /// (`talk: true`, captures the phone's mic and attaches it before the
  /// offer is even created). **Always builds a fresh peer connection —
  /// never renegotiates an existing one.** `module_webrtc.c` holds exactly
  /// one `RTCPeerConnection` per signaling port and tears down whatever
  /// connection currently exists on every accepted offer before rebuilding
  /// it server-side (STREAMING_GUIDE.md §2.3). Sending a second offer over
  /// the *phone's own already-connected* `RTCPeerConnection` (the original
  /// [startTalk] approach) reliably completes the SDP handshake — offer and
  /// answer both say `sendrecv` — but the connection then dies a few
  /// seconds later, because the local ICE agent is still holding
  /// candidates/consent state for a server-side session the camera already
  /// discarded the moment the second offer arrived (confirmed via
  /// real-device log capture, 2026-08-17: every talk attempt reconnected
  /// cleanly then closed ~5s later, exactly matching this app's own
  /// `_iceDisconnectGrace` timeout). The fix, matching the sibling
  /// `vizenlinkvms/nuraeye-rt` app's `WebRtcLiveViewSession.connect`: treat
  /// every negotiation — including toggling talk — as a full replacement,
  /// so the local and remote sides always start ICE in lockstep. Callers
  /// ([_connectLan], [startTalk]) must have already torn down any previous
  /// [_pc] (and told the camera so via `POST /webrtc/stop`, for the talk
  /// case) before calling this. Returns true on success.
  Future<bool> _negotiate(Uri signalingUrl, {required bool talk}) async {
    MediaStream? localStream;
    if (talk) {
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
    } else {
      // iOS-only (no-op elsewhere, see AppleNativeAudioManagement's own
      // platform check): configures AVAudioSession for receive-only remote
      // audio playback before the peer connection exists. Without this,
      // the native WebRTC audio engine renders against an unconfigured
      // session — reproduced as a real SIGSEGV inside WebRTC's own audio
      // unit callback (crash report 2026-08-14, iOS Simulator) once the
      // remote audio track went live. Talk's `localAndRemote` equivalent
      // is set further below, once the mic track is actually attached —
      // that ordering was already what [startTalk] did before this and is
      // not implicated in that crash.
      await AppleNativeAudioManagement.setAppleAudioConfiguration(
        AppleNativeAudioManagement.getAppleAudioConfigurationForMode(
          AppleAudioIOMode.remoteOnly,
        ),
      );
    }
    if (_disposed) {
      if (localStream != null) {
        for (final track in localStream.getTracks()) {
          await track.stop();
        }
      }
      return false;
    }

    try {
      // No STUN/TURN — this is a same-LAN connection with host candidates
      // only (guide §2.2).
      final pc = await createPeerConnection({'iceServers': <dynamic>[]});
      if (_disposed) {
        await pc.close();
        if (localStream != null) {
          for (final track in localStream.getTracks()) {
            await track.stop();
          }
        }
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

      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      final audioTransceiver = await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(
          direction: talk
              ? TransceiverDirection.SendRecv
              : TransceiverDirection.RecvOnly,
        ),
      );
      if (talk && localStream != null) {
        await audioTransceiver.sender.replaceTrack(
          localStream.getAudioTracks().first,
        );
        _localAudioStream = localStream;
        // Sending *and* receiving audio now — reconfigure the iOS session
        // accordingly (see the `remoteOnly` call above for why this
        // matters at all; `localAndRemote` is talk's equivalent).
        await AppleNativeAudioManagement.setAppleAudioConfiguration(
          AppleNativeAudioManagement.getAppleAudioConfigurationForMode(
            AppleAudioIOMode.localAndRemote,
            preferSpeakerOutput: speakerphoneOn,
          ),
        );
      }

      final offer = await pc.createOffer();
      if (talk) {
        // ignore: avoid_print
        print(
          '[Talk] offer audio direction line: '
          '${_extractAudioDirection(offer.sdp)}',
        );
      }
      await pc.setLocalDescription(offer);

      // This camera's WebRTC signaling is non-trickle — it needs host ICE
      // candidates already embedded in the offer SDP, not delivered
      // separately after the fact. Waiting for gathering to finish (bounded,
      // since gathering host-only candidates with no STUN/TURN is normally
      // near-instant but nothing guarantees it can never stall) and
      // re-reading the local description picks those candidates up before
      // the offer is sent — skipping this step can produce a negotiation
      // that "connects" at the SDP level but never actually carries media.
      await _waitForIceGatheringComplete(pc);
      if (_disposed) {
        await pc.close();
        if (localStream != null) {
          for (final track in localStream.getTracks()) {
            await track.stop();
          }
        }
        return false;
      }
      final localDescription = await pc.getLocalDescription();
      final offerSdp = localDescription?.sdp ?? offer.sdp;

      final response = await _http
          .post(
            signalingUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'type': 'offer', 'sdp': offerSdp, 'talk': talk}),
          )
          .timeout(_webrtcSignalingTimeout);
      if (_disposed) return false;
      if (talk) {
        // ignore: avoid_print
        print('[Talk] signaling response: ${response.statusCode}');
      }

      // TWO_WAY_TALK_GUIDE.md §4 — a 409 means another talk session already
      // holds the camera's speaker; nothing to roll back locally since this
      // is always a fresh pc/offer now, just report busy (talk) or a
      // generic rejection (plain connect, though 409 shouldn't occur there).
      if (response.statusCode == 409) {
        if (talk) {
          talkStatus = TalkStatus.busy;
          notifyListeners();
        } else {
          errorMessage = 'Camera rejected the connection (409)';
        }
        await _teardownPeerConnection();
        await _releaseLocalAudio();
        return false;
      }
      if (response.statusCode != 200) {
        final reason =
            'Camera rejected the connection (${response.statusCode})';
        if (talk) {
          _failTalk(reason);
        } else {
          errorMessage = reason;
        }
        await _teardownPeerConnection();
        await _releaseLocalAudio();
        return false;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final answerSdp = body['sdp'] as String?;
      final answerType = body['type'] as String?;
      if (answerSdp == null || answerType == null) {
        const reason = 'Malformed answer from camera';
        if (talk) {
          _failTalk(reason);
        } else {
          errorMessage = reason;
        }
        await _teardownPeerConnection();
        await _releaseLocalAudio();
        return false;
      }
      if (talk) {
        // ignore: avoid_print
        print(
          '[Talk] answer audio direction line: '
          '${_extractAudioDirection(answerSdp)}',
        );
      }
      await pc.setRemoteDescription(
        RTCSessionDescription(answerSdp, answerType),
      );
      if (_disposed) return false;

      _signalingUrl = signalingUrl;
      transport = LiveViewTransport.lan;
      status = LiveViewStatus.connected;
      _retryAttempt = 0;
      _startStatsPolling();
      if (talk) {
        talkStatus = TalkStatus.talking;
        talkErrorMessage = null;
      }
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
      notifyListeners();
      return true;
    } catch (e) {
      if (_disposed) return false;
      if (talk) {
        _failTalk(e.toString());
      } else {
        errorMessage = e.toString();
      }
      await _teardownPeerConnection();
      await _releaseLocalAudio();
      return false;
    }
  }

  /// Bounded wait for [pc]'s ICE gathering to reach
  /// [RTCIceGatheringState.RTCIceGatheringStateComplete] — see the call site
  /// in [_negotiate] for why this matters for this camera's non-trickle
  /// signaling. Proceeding with whatever candidates were gathered so far on
  /// timeout is standard WebRTC practice, not a degraded state.
  Future<void> _waitForIceGatheringComplete(RTCPeerConnection pc) async {
    if (pc.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }
    final completer = Completer<void>();
    pc.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !completer.isCompleted) {
        completer.complete();
      }
    };
    await completer.future.timeout(_iceGatheringTimeout, onTimeout: () {});
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
          if (!_disposed) unawaited(_recordLanDropAndReconnect());
        });
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        _disconnectGraceTimer?.cancel();
        _disconnectGraceTimer = null;
        unawaited(_recordLanDropAndReconnect());
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

  String? _nextLowerProfile() {
    final i = _profileLadder.indexOf(_profileToken);
    if (i == -1 || i + 1 >= _profileLadder.length) return null;
    return _profileLadder[i + 1];
  }

  String? _nextHigherProfile() {
    final i = _profileLadder.indexOf(_profileToken);
    if (i <= 0) return null;
    return _profileLadder[i - 1];
  }

  /// Funnel for every LAN WebRTC drop (disconnect-grace expiry, or a hard
  /// `failed`/`closed` state) — counts drops within [_lanTroubleWindow] and,
  /// once [_lanTroubleThreshold] is hit, steps the resolution ladder down a
  /// tier instead of just reconnecting at the same (evidently struggling)
  /// profile. A marginal LAN link then self-heals into something watchable
  /// rather than repeatedly stalling/reconnecting at full resolution.
  Future<void> _recordLanDropAndReconnect() async {
    if (_disposed) return;
    final now = DateTime.now();
    _recentLanDrops.removeWhere((t) => now.difference(t) > _lanTroubleWindow);
    _recentLanDrops.add(now);
    final lowerProfile = _nextLowerProfile();
    if (transport == LiveViewTransport.lan &&
        _recentLanDrops.length >= _lanTroubleThreshold &&
        lowerProfile != null) {
      await _switchProfile(lowerProfile);
      return;
    }
    await _reconnect();
  }

  /// Moves live view to a different rung of [_profileLadder] — one tier
  /// down on sustained trouble ([_recordLanDropAndReconnect]'s ICE-drop
  /// counter, or a stats-detected stall/low-bitrate run in [_pollBitrate]),
  /// or one tier up after a sustained healthy run. Tears down the current
  /// peer connection and reconnects fresh on [newProfile] via the normal
  /// [connect] path (which still tries LAN-then-WAN, but LAN will now
  /// request the new profile).
  Future<void> _switchProfile(String newProfile) async {
    if (_disposed || transport != LiveViewTransport.lan) return;
    _profileToken = newProfile;
    _recentLanDrops.clear();
    _healthyPollCount = 0;
    _stallPollCount = 0;
    _lowBitratePollCount = 0;
    status = LiveViewStatus.reconnecting;
    notifyListeners();
    await _teardownPeerConnection();
    if (!_disposed) await connect();
  }

  Future<void> _reconnect() async {
    if (_disposed) return;
    // An ICE failure/close tears down this exact peer connection — the talk
    // leg (if any) dies with it, and the fresh connection `connect()` below
    // creates is recvonly-only (talk is only ever added via a later
    // `startTalk()` renegotiation, same as TWO_WAY_TALK_GUIDE.md §3's
    // "`/webrtc/stop` tears down the entire connection, not just the talk
    // leg"). Without resetting `talkStatus` here, the TALK-001 status bar
    // would keep showing "Talking" indefinitely after an automatic
    // reconnect even though the mic leg is gone and nothing is actually
    // being sent — silently stuck, not just briefly wrong. Landing on
    // [TalkStatus.error] rather than [TalkStatus.idle] keeps the status bar
    // visible with an explanation instead of it just vanishing, same as any
    // other talk failure — the user dismisses it via TALK-005 same as usual.
    if (talkStatus != TalkStatus.idle) {
      await _releaseLocalAudio();
      talkStatus = TalkStatus.error;
      talkErrorMessage = 'Talk ended: connection was interrupted';
    }
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
    _lastFramesDecoded = null;
    _stallPollCount = 0;
    _lowBitratePollCount = 0;
    if (measuredBitrateKbps != null) {
      measuredBitrateKbps = null;
      if (!_disposed) notifyListeners();
    }
  }

  /// One `getStats()` sample — computes a rate from the delta against the
  /// previous sample, so the first tick after (re)connecting only seeds the
  /// baseline and doesn't yet update [measuredBitrateKbps]. Also feeds
  /// [_maybeAdjustProfile]'s stall/low-bitrate detection — catches a session
  /// that stays nominally ICE-`connected` while actually stalled/starved,
  /// which [_handleIceConnectionState] alone never sees.
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
        final framesDecoded = (report.values['framesDecoded'] as num?)?.toInt();
        if (bytesReceivedRaw is! num) continue;
        final bytesReceived = bytesReceivedRaw.toInt();
        final timestampMs = report.timestamp;

        final prevBytes = _lastStatsBytesReceived;
        final prevTimestampMs = _lastStatsTimestampMs;
        _lastStatsBytesReceived = bytesReceived;
        _lastStatsTimestampMs = timestampMs;

        double? bitrateKbps;
        if (prevBytes != null && prevTimestampMs != null) {
          final deltaBytes = bytesReceived - prevBytes;
          final deltaSeconds = (timestampMs - prevTimestampMs) / 1000;
          if (deltaSeconds > 0 && deltaBytes >= 0) {
            bitrateKbps = (deltaBytes * 8) / 1000 / deltaSeconds;
            measuredBitrateKbps = bitrateKbps;
            if (!_disposed) notifyListeners();
          }
        }

        final stalled =
            framesDecoded != null &&
            _lastFramesDecoded != null &&
            framesDecoded == _lastFramesDecoded;
        _lastFramesDecoded = framesDecoded;
        await _maybeAdjustProfile(stalled: stalled, bitrateKbps: bitrateKbps);
        return;
      }
    } catch (_) {
      // Best-effort — stats aren't critical to the connection itself.
    }
  }

  /// Steps [_profileToken] down a tier on a sustained stall/low-bitrate run,
  /// or up a tier after a sustained healthy run — the counterpart to
  /// [_recordLanDropAndReconnect]'s ICE-drop-based trigger. Deliberately
  /// slower to step up than down: a marginal link should recover fast, but
  /// shouldn't flap back to full resolution on one good sample.
  Future<void> _maybeAdjustProfile({
    required bool stalled,
    required double? bitrateKbps,
  }) async {
    if (_disposed || transport != LiveViewTransport.lan) return;

    _stallPollCount = stalled ? _stallPollCount + 1 : 0;
    final lowBitrate =
        bitrateKbps != null && bitrateKbps < _lowBitrateThresholdKbps;
    _lowBitratePollCount = lowBitrate ? _lowBitratePollCount + 1 : 0;

    final troubled =
        _stallPollCount >= _stallPollThreshold ||
        _lowBitratePollCount >= _lowBitratePollThreshold;
    final lowerProfile = _nextLowerProfile();
    if (troubled && lowerProfile != null) {
      _healthyPollCount = 0;
      await _switchProfile(lowerProfile);
      return;
    }

    final higherProfile = _nextHigherProfile();
    if (!troubled && higherProfile != null) {
      _healthyPollCount++;
      if (_healthyPollCount >= _healthyPollThreshold) {
        _healthyPollCount = 0;
        await _switchProfile(higherProfile);
      }
    } else if (!troubled) {
      _healthyPollCount = 0;
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
    _startWanStallMonitor();
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
    _lastWanPlaybackUri = uri;
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

  void _startWanStallMonitor() {
    _wanStallTimer?.cancel();
    _lastWanPosition = null;
    _wanStallPollCount = 0;
    _wanStallTimer = Timer.periodic(
      _wanStallPollInterval,
      (_) => unawaited(_pollWanStall()),
    );
  }

  void _stopWanStallMonitor() {
    _wanStallTimer?.cancel();
    _wanStallTimer = null;
    _lastWanPosition = null;
    _wanStallPollCount = 0;
  }

  /// Client-side counterpart to [_checkWanHealth]'s server-side poll — a
  /// purely phone-side hiccup (decoder stall, a blip to the CloudFront/S3
  /// endpoint) with a perfectly healthy camera-side stream can leave
  /// [wanVideoController] frozen while `GetCloudStreamingStatus` keeps
  /// reporting `active`, since the camera side really is fine. Detects that
  /// case directly from the player's own state (an error, or playback
  /// position not advancing) rather than waiting for the next health tick.
  Future<void> _pollWanStall() async {
    if (_disposed ||
        transport != LiveViewTransport.wan ||
        status != LiveViewStatus.connected) {
      return;
    }
    final controller = wanVideoController;
    if (controller == null) return;
    final value = controller.value;

    final stalled =
        value.hasError ||
        (value.isPlaying && value.position == _lastWanPosition);
    _lastWanPosition = value.position;

    _wanStallPollCount = stalled ? _wanStallPollCount + 1 : 0;
    if (_wanStallPollCount < _wanStallThreshold) return;
    _wanStallPollCount = 0;
    await _recoverWanStallLocalFirst();
  }

  /// Re-inits playback against the same, already-valid HLS URI first — no
  /// extra AWS round trip needed for a purely local hiccup — only
  /// escalating to a fresh WAN resolve ([_recoverWanPlayback]) if that
  /// itself fails.
  Future<void> _recoverWanStallLocalFirst() async {
    if (_disposed || transport != LiveViewTransport.wan) return;
    final uri = _lastWanPlaybackUri;
    if (uri != null) {
      for (var attempt = 0; attempt < 3 && !_disposed; attempt++) {
        if (transport != LiveViewTransport.wan) return;
        if (await _playWanUrl(uri)) {
          if (!_disposed) notifyListeners();
          return;
        }
        if (attempt < 2) await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (_disposed || transport != LiveViewTransport.wan) return;
    unawaited(_recoverWanPlayback());
  }

  /// STREAMING_GUIDE.md §5 — two separate watchers, since WAN has no single
  /// live push signal the way LAN's ICE state is one: a cheap LAN
  /// reachability probe first each tick (switch back to LAN the moment the
  /// phone is back on the camera's network, before spending a paid
  /// AWS/Lambda call), then `GetCloudStreamingStatus` itself. **Skips the
  /// LAN probe (and any switch-back) entirely when [forceTransport] is
  /// [LiveViewTransport.wan]** — the whole point of forcing WAN for a test
  /// is to exercise it even when LAN is available, so this must never
  /// switch a forced-WAN session back to LAN just because the camera
  /// happens to be reachable there.
  Future<void> _checkWanHealth() async {
    if (_disposed ||
        transport != LiveViewTransport.wan ||
        status != LiveViewStatus.connected) {
      return;
    }

    if (forceTransport != LiveViewTransport.wan) {
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
    _stopWanStallMonitor();
    _lastWanPlaybackUri = null;
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

  /// Starts a two-way-talk session. Requires [status] to already be
  /// [LiveViewStatus.connected] over LAN; no-op otherwise.
  ///
  /// **Does not renegotiate the existing connection in place** — explicitly
  /// ends it (`POST /webrtc/stop`) and negotiates a completely fresh one
  /// with `talk: true` baked into the very first offer, via [_negotiate].
  /// See [_negotiate]'s doc comment for why: this camera's firmware tears
  /// down and rebuilds its side on every accepted offer regardless, so a
  /// second in-place offer over the phone's already-connected pc leaves the
  /// two sides' ICE state out of sync — it was found to reconnect at the
  /// SDP level but then die a few seconds later, every single time.
  Future<void> startTalk() async {
    if (_disposed ||
        status != LiveViewStatus.connected ||
        transport != LiveViewTransport.lan ||
        _pc == null ||
        _signalingUrl == null) {
      return;
    }

    talkStatus = TalkStatus.connecting;
    talkErrorMessage = null;
    notifyListeners();

    final signalingUrl = _signalingUrl!;
    await _postStop(signalingUrl);
    await _teardownPeerConnection();
    if (_disposed) return;

    final succeeded = await _negotiate(signalingUrl, talk: true);
    // Whatever the outcome, the old connection is already gone (stopped
    // above) — on failure, [_negotiate] has already set talkStatus to
    // busy/error, but live view itself is now dead too unless a fresh
    // plain reconnect is kicked off.
    if (!succeeded && !_disposed) {
      unawaited(connect());
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
    if (signalingUrl != null) await _postStop(signalingUrl);
    await _stopWanIfNeeded();
    if (_disposed) return;
    status = LiveViewStatus.stopped;
    notifyListeners();
  }

  /// Best-effort `POST /webrtc/stop` — tells the camera to release the
  /// signaling slot immediately rather than waiting for it to notice the
  /// connection died on its own. Failures here don't block local teardown.
  Future<void> _postStop(Uri signalingUrl) async {
    try {
      await _http
          .post(signalingUrl.replace(path: '${signalingUrl.path}/stop'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort — nothing more to do if the camera is already
      // unreachable at teardown time.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _disconnectGraceTimer?.cancel();
    _autoRetryTimer?.cancel();
    _wanHealthTimer?.cancel();
    _wanStallTimer?.cancel();
    _statsTimer?.cancel();
    unawaited(_releaseLocalAudio());
    unawaited(_teardownPeerConnection());
    unawaited(_stopWanIfNeeded());
    if (_rendererInitialized) unawaited(renderer.dispose());
    super.dispose();
  }
}
