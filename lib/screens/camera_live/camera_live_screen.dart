import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera_api/camera_api.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../app_state/homes_controller.dart';
import '../../app_state/live_view_controller.dart';
import '../../app_state/route_observer.dart';
import '../../models/camera.dart';
import '../../theme/app_colors.dart';
import '../../widgets/camera_thumbnail_image.dart';
import '../../widgets/camera_timeline.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/live_status_badges.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/settings_save_button.dart' show simulateCameraSave;
import '../camera_settings/camera_settings_screen.dart';
import 'ai_mode_screen.dart';

/// `CameraVideoMode` <-> ONVIF `IrCutFilter` wire values — mirrors
/// `video_mode_screen.dart`'s private mapping of the same name (Dart
/// privacy means it can't be imported directly; this is the only other
/// place in the app that sets this field, so a small local copy is
/// simpler than threading a shared helper file just for this one mapping).
String _videoModeToIrCutFilter(CameraVideoMode mode) => switch (mode) {
  CameraVideoMode.day => 'ON',
  CameraVideoMode.night => 'OFF',
  CameraVideoMode.auto => 'AUTO',
};

const _recordingLimit = Duration(minutes: 5);
const _continuePromptCountdown = Duration(seconds: 5);
const _cellularReminderInterval = Duration(minutes: 5);

/// Placeholder sample stream used until a real CCTV protocol (RTSP/ONVIF/
/// HLS) is chosen — see CLAUDE.md.
const _dummyVideoAsset = 'assets/videos/camera_dummy.mp4';

class CameraLiveScreen extends StatefulWidget {
  const CameraLiveScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'live';

  /// Initial snapshot passed via navigation `extra`. The live, up-to-date
  /// camera (reflecting settings changes made elsewhere, e.g. On-Screen
  /// Display's OSD toggles) is looked up from [homesController] by id — see
  /// `_currentCamera`.
  final Camera camera;
  final HomesController homesController;

  @override
  State<CameraLiveScreen> createState() => _CameraLiveScreenState();
}

class _CameraLiveScreenState extends State<CameraLiveScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final TabController _tabController;
  late final VideoPlayerController _videoController;
  final _videoBoundaryKey = GlobalKey();

  /// Real LAN WebRTC live-view session — null when this camera has no saved
  /// connection yet (falls back to the dummy asset, same convention as
  /// every other camera-settings screen). WAN fallback isn't wired up here
  /// yet — LAN only for now.
  LiveViewController? _liveViewController;
  bool _isMuted = false;
  bool _isSpotlightOn = false;
  bool _isPrivacyShortcutBusy = false;
  bool _isVideoModeShortcutBusy = false;

  bool _isRecording = false;
  DateTime? _recordingStartedAt;
  Timer? _recordingTicker;
  Duration _recordingElapsed = Duration.zero;

  /// Set only when the current recording is real (backed by
  /// [LiveViewController.startRecording]) — null means the dummy-asset trim
  /// fallback is in effect instead. See [_toggleRecording]/[_stopRecording].
  String? _liveRecordingPath;

  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _cellularReminderTicker;

  bool get _isOnCellular =>
      _connectivity.contains(ConnectivityResult.mobile) &&
      !_connectivity.contains(ConnectivityResult.wifi);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });
    _videoController = VideoPlayerController.asset(_dummyVideoAsset)
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController.play();
      });
    final connection = widget.camera.connection;
    if (connection != null) {
      _liveViewController = LiveViewController(connection)
        ..addListener(_onLiveViewChanged)
        ..connect();
      unawaited(_pollSignalStrength());
      _signalPollTimer = Timer.periodic(
        _signalPollInterval,
        (_) => unawaited(_pollSignalStrength()),
      );
      unawaited(_loadRealBitrate());
    }
    _initConnectivity();
  }

  /// Real configured encoder bitrate (LIVE-029's badge) — a stable
  /// configuration fact from Video Encoder settings, not a live
  /// measurement, so a one-time fetch on screen open is enough (unlike
  /// signal strength/bitrate telemetry, this doesn't change mid-session
  /// unless the user visits Video Encoder settings and changes it, which
  /// already persists a fresh value through `HomesController` itself).
  /// Previously `Camera.bitrateKbps` only ever got a real value if the user
  /// had specifically opened Video Encoder settings before — this screen
  /// showed a permanently-stale/default number otherwise.
  Future<void> _loadRealBitrate() async {
    final connection = widget.camera.connection;
    if (connection == null) return;
    final client = OnvifVideoEncoderClient(connection);
    var result = await client.getVideoEncoderSettings();
    client.close();

    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanVideoEncoderClient(thingName).getVideoEncoderSettings();
    }
    if (!mounted) return;
    if (result case CameraSuccess(:final value)) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (current) => current.copyWith(bitrateKbps: value.bitrate.toDouble()),
      );
    }
  }

  /// Real LAN reachability probe (`NetworkInfoClient.getWifiSignalStrength`
  /// — same call `wifi_config_screen.dart` already uses) — LIVE-030's
  /// signal bars used to always read `Camera.signalStrength`'s permanent
  /// default of 0 since nothing ever wrote a real value into it. Persisted
  /// via `HomesController.updateCamera` (unlike the fast-changing bitrate
  /// reading, RSSI genuinely is a "current camera state" fact worth keeping
  /// around, same as `pingCameraReachability`'s `isOnline`).
  static const _signalPollInterval = Duration(seconds: 20);
  Timer? _signalPollTimer;

  Future<void> _pollSignalStrength() async {
    final connection = widget.camera.connection;
    if (connection == null) return;
    final client = NetworkInfoClient(connection);
    final result = await client.getWifiSignalStrength();
    client.close();
    if (!mounted) return;
    if (result case CameraSuccess(:final value)) {
      final bars = barsForRssi(value.rssi);
      widget.homesController.updateCamera(
        widget.camera.id,
        (current) => current.copyWith(signalStrength: bars),
      );
    }
  }

  /// Backgrounding the app doesn't dispose this screen — the widget tree
  /// stays alive, so without this the LAN peer connection / WAN cloud
  /// stream just keeps running with nobody watching (a real complaint: the
  /// camera kept streaming after the phone app was closed/backgrounded).
  /// [paused] covers both "home button pressed" and, on Android, the
  /// process being backgrounded ahead of a possible kill — there's no
  /// reliable further callback once the OS actually terminates the process,
  /// so this is the last point a graceful stop can be sent. Reconnects on
  /// [resumed] only if the session was actually torn down here (not if it
  /// simply failed/was already stopped for an unrelated reason) and the
  /// screen is still on the Live tab.
  bool _stoppedForBackground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _liveViewController;
    if (controller == null) return;
    switch (state) {
      case AppLifecycleState.paused:
        if (controller.status == LiveViewStatus.connected ||
            controller.status == LiveViewStatus.connecting ||
            controller.status == LiveViewStatus.reconnecting) {
          _stoppedForBackground = true;
          unawaited(controller.stop());
        }
      case AppLifecycleState.resumed:
        if (_stoppedForBackground) {
          _stoppedForBackground = false;
          if (_tabController.index == 0) controller.connect();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  /// `context.push`-ing to a sub-screen (e.g. Camera Settings) leaves this
  /// screen mounted underneath the new route, same underlying issue as the
  /// backgrounding fix above — the session doesn't know it's not visible
  /// anymore unless something tells it. A real complaint: the stream/audio
  /// kept running while browsing screens pushed on top of Live view.
  /// [didPushNext] fires when this route gets covered; [didPopNext] fires
  /// when it's back on top. Shares [_stoppedForBackground]'s reasoning for
  /// only reconnecting what this screen itself paused.
  bool _stoppedForNavigation = false;

  @override
  void didPushNext() {
    final controller = _liveViewController;
    if (controller == null) return;
    if (controller.status == LiveViewStatus.connected ||
        controller.status == LiveViewStatus.connecting ||
        controller.status == LiveViewStatus.reconnecting) {
      _stoppedForNavigation = true;
      unawaited(controller.stop());
    }
  }

  @override
  void didPopNext() {
    final controller = _liveViewController;
    if (controller == null) return;
    if (_stoppedForNavigation) {
      _stoppedForNavigation = false;
      if (_tabController.index == 0) controller.connect();
    }
  }

  /// Shifts LIVE-007/LIVE-008 up so they don't sit underneath the talk
  /// status bar (TALK-001) when it's showing at the very bottom edge.
  double get _cornerButtonBottomInset =>
      (_liveViewController?.talkStatus ?? TalkStatus.idle) == TalkStatus.idle
      ? 8
      : 56;

  /// Rebuilds on any [LiveViewController] change (connection status, talk
  /// status) — coarse-grained, matching this screen's existing setState
  /// style, but cheap since this screen's build is small relative to a
  /// video frame render. Deferred to a microtask: [LiveViewController] can
  /// call `notifyListeners()` from a native platform-channel callback that
  /// sometimes lands mid-build, and calling `setState` synchronously in
  /// that case throws ("setState() or markNeedsBuild() called during
  /// build" — hit on real hardware 2026-08-14). A microtask runs just after
  /// the current build finishes instead.
  void _onLiveViewChanged() {
    _syncCameraOnlineStatus();
    Future.microtask(() {
      if (mounted) setState(() {});
    });
  }

  /// The live-view connection attempt *is* a reachability check — a failed
  /// signaling call means the camera genuinely didn't respond, same as the
  /// LAN pings `camera_sync.dart` uses for the dashboard's offline badge.
  /// Without this, `Camera.isOnline` only gets updated by the dashboard's
  /// own 5-minute timer, so a camera that dies mid-stream would still show
  /// "online" everywhere else in the app for up to 5 minutes even though
  /// this screen already knows it's not reachable. Only writes when the
  /// derived online value actually changed, so this doesn't fire on every
  /// unrelated controller notification (talk status, reconnecting, etc).
  void _syncCameraOnlineStatus() {
    final controller = _liveViewController;
    if (controller == null) return;
    final bool? online = switch (controller.status) {
      LiveViewStatus.connected => true,
      LiveViewStatus.failed => false,
      LiveViewStatus.connecting ||
      LiveViewStatus.reconnecting ||
      LiveViewStatus.stopped => null,
    };
    if (online == null) return;
    final current = _currentCamera(widget.homesController.value);
    if (current.isOnline == online) return;
    widget.homesController.updateCamera(
      current.id,
      (camera) => camera.copyWith(
        isOnline: online,
        lastSeen: online ? DateTime.now() : null,
      ),
    );
  }

  Future<void> _initConnectivity() async {
    final initial = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() => _connectivity = initial);
    _updateCellularReminder();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (!mounted) return;
      setState(() => _connectivity = result);
      _updateCellularReminder();
    });
    if (_isOnCellular && widget.camera.isOnline) {
      final shouldContinue = await _confirmCellularUsage();
      if (!mounted) return;
      if (!shouldContinue) context.pop();
    }
  }

  Future<bool> _confirmCellularUsage() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('LIVE-039'),
        title: const Text('You\'re on mobile data'),
        content: const Text(
          'Streaming video will use your mobile data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return shouldContinue ?? false;
  }

  void _updateCellularReminder() {
    if (_isOnCellular) {
      _cellularReminderTicker ??= Timer.periodic(_cellularReminderInterval, (
        _,
      ) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: Key('LIVE-040'),
            content: Text('Still watching on mobile data'),
          ),
        );
      });
    } else {
      _cellularReminderTicker?.cancel();
      _cellularReminderTicker = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _recordingTicker?.cancel();
    _cellularReminderTicker?.cancel();
    _signalPollTimer?.cancel();
    _connectivitySubscription?.cancel();
    _tabController.dispose();
    _videoController.dispose();
    _liveViewController?.removeListener(_onLiveViewChanged);
    _liveViewController?.stop();
    _liveViewController?.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _videoController.setVolume(_isMuted ? 0 : 1);
      _liveViewController?.setAudioEnabled(!_isMuted);
      // WAN playback is a plain VideoPlayerController, not a WebRTC track —
      // setAudioEnabled (above) only affects the LAN renderer's tracks.
      _liveViewController?.wanVideoController?.setVolume(_isMuted ? 0 : 1);
    });
  }

  /// Captures the current on-screen video frame as PNG bytes, without
  /// saving it anywhere — shared by [_takeSnapshot] (LIVE-009, saves to the
  /// gallery) and AI Mode's frozen-frame entry/retake (LIVE-043/AIMODE-006).
  /// Prefers a real capture straight from the remote WebRTC video track
  /// (`LiveViewController.captureSnapshot`) when the Live tab is showing a
  /// connected real feed — a `RenderRepaintBoundary` screenshot of the
  /// platform-view/texture-backed `RTCVideoView` isn't reliable. Falls back
  /// to the boundary screenshot for the Playback tab, or any camera with no
  /// real connection.
  Future<Uint8List?> _captureFrame() async {
    final liveViewController = _liveViewController;
    if (_tabController.index == 0 &&
        liveViewController != null &&
        liveViewController.status == LiveViewStatus.connected) {
      final liveFrame = await liveViewController.captureSnapshot();
      if (liveFrame != null) return liveFrame;
    }
    final boundary =
        _videoBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _takeSnapshot() async {
    try {
      final bytes = await _captureFrame();
      if (bytes == null) return;
      await Gal.putImageBytes(
        bytes,
        name: 'cctv_snapshot_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Snapshot saved')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save snapshot')));
    }
  }

  /// rootNavigator: true — same reasoning as [_openFullscreen]: this screen
  /// lives inside a StatefulShellRoute branch with its own nested Navigator,
  /// so pushing on the branch Navigator alone would keep MainShell's bottom
  /// nav bar visible underneath AI Mode instead of it taking over the
  /// screen. Not a go_router route for the same reason fullscreen isn't —
  /// it's a modal takeover of this screen, not an independently
  /// deep-linkable destination.
  Future<void> _openAiMode(Camera camera) async {
    final frame = await _captureFrame();
    if (!mounted || frame == null) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => AiModeScreen(
          args: AiModeLaunchArgs(
            camera: camera,
            initialFrame: frame,
            captureFrame: _captureFrame,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording(save: true);
      return;
    }

    final liveViewController = _liveViewController;
    // No native frame-capture path exists for WAN's plain HLS playback the
    // way LiveViewController.startRecording has for a real WebRTC track —
    // falling through to the dummy-asset trim below would silently save a
    // fake recording instead, which is worse than not recording at all.
    if (_tabController.index == 0 &&
        liveViewController != null &&
        liveViewController.status == LiveViewStatus.connected &&
        liveViewController.transport == LiveViewTransport.wan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording isn\'t available on a remote connection'),
        ),
      );
      return;
    }
    String? liveRecordingPath;
    if (_tabController.index == 0 &&
        liveViewController != null &&
        liveViewController.status == LiveViewStatus.connected) {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/cctv_live_${DateTime.now().millisecondsSinceEpoch}.mp4';
      if (await liveViewController.startRecording(path)) {
        liveRecordingPath = path;
      }
    }
    if (!mounted) return;

    setState(() {
      _isRecording = true;
      _liveRecordingPath = liveRecordingPath;
      _recordingStartedAt = DateTime.now();
      _recordingElapsed = Duration.zero;
    });
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _recordingStartedAt == null) return;
      setState(() {
        _recordingElapsed = DateTime.now().difference(_recordingStartedAt!);
      });
      if (_recordingElapsed >= _recordingLimit) {
        _recordingTicker?.cancel();
        _promptContinueRecording();
      }
    });
  }

  Future<void> _promptContinueRecording() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _ContinueRecordingDialog(countdown: _continuePromptCountdown),
    );
    if (!mounted) return;
    if (shouldContinue ?? false) {
      // Start a fresh 5-minute window; the recording itself keeps going.
      setState(() {
        _recordingStartedAt = DateTime.now();
        _recordingElapsed = Duration.zero;
      });
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _recordingStartedAt == null) return;
        setState(() {
          _recordingElapsed = DateTime.now().difference(_recordingStartedAt!);
        });
        if (_recordingElapsed >= _recordingLimit) {
          _recordingTicker?.cancel();
          _promptContinueRecording();
        }
      });
    } else {
      _stopRecording(save: true);
    }
  }

  Future<void> _stopRecording({required bool save}) async {
    _recordingTicker?.cancel();
    final recordedDuration = _recordingElapsed;
    final liveRecordingPath = _liveRecordingPath;
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _recordingElapsed = Duration.zero;
      _liveRecordingPath = null;
    });

    if (liveRecordingPath != null) {
      await _liveViewController?.stopRecording();
    }
    if (!save || !mounted) return;

    try {
      if (liveRecordingPath != null) {
        // Real recording, captured straight from the remote WebRTC video
        // track by LiveViewController — see this file's top-level LAN
        // live-view doc.
        await Gal.putVideo(liveRecordingPath);
      } else {
        // No real connection for this camera (or the Playback tab was
        // active) — trim a copy of the dummy asset down to how long the
        // user actually recorded, as a stand-in for "what was recorded".
        final bytes = await DefaultAssetBundle.of(
          context,
        ).load(_dummyVideoAsset);
        final tempDir = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final sourceFile = File('${tempDir.path}/cctv_source_$stamp.mp4');
        await sourceFile.writeAsBytes(bytes.buffer.asUint8List());

        final trimmedFile = File('${tempDir.path}/cctv_recording_$stamp.mp4');
        final clampedSeconds = recordedDuration.inSeconds.clamp(
          1,
          _recordingLimit.inSeconds,
        );
        final session = await FFmpegKit.execute(
          '-y -i "${sourceFile.path}" -t $clampedSeconds -c copy '
          '"${trimmedFile.path}"',
        );
        final returnCode = await session.getReturnCode();
        await sourceFile.delete();
        if (!ReturnCode.isSuccess(returnCode)) {
          throw Exception('ffmpeg trim failed');
        }

        await Gal.putVideo(trimmedFile.path);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recording saved')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save recording')));
    }
  }

  Future<void> _openFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    // rootNavigator: true — this screen lives inside a StatefulShellRoute
    // branch with its own nested Navigator; pushing on the branch Navigator
    // alone would keep MainShell's bottom nav bar visible underneath.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideo(
          controller: _videoController,
          liveViewController: _liveViewController,
          showLiveView: _tabController.index == 0,
          isMuted: _isMuted,
          onMuteChanged: (muted) => setState(() => _isMuted = muted),
        ),
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Toggles two-way talk (LIVE-011) in place, on the same screen — the
  /// live video keeps playing throughout; a status bar overlaid at the
  /// bottom of the video (TALK-001) shows connecting/talking/busy/error and
  /// carries the speakerphone/End controls, per `TWO_WAY_TALK_GUIDE.md`
  /// §5's call-style contract (distinct states, not just a spinner-or-not
  /// toggle; every exit path funnels through one teardown). Starting
  /// requires a real, already-connected LAN session — talk is LAN-only
  /// (§1) and reuses that exact connection rather than opening a new one.
  Future<void> _toggleTalk() async {
    final liveViewController = _liveViewController;
    if (liveViewController == null) return;

    if (liveViewController.talkStatus == TalkStatus.idle) {
      if (liveViewController.status != LiveViewStatus.connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect to the camera to talk')),
        );
        return;
      }
      if (liveViewController.transport == LiveViewTransport.wan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Talk isn\'t available on a remote connection'),
          ),
        );
        return;
      }
      await liveViewController.startTalk();
      return;
    }

    await liveViewController.endTalk();
    // Ending a talk session that actually connected tears down the whole
    // WebRTC connection, not just the talk leg (TWO_WAY_TALK_GUIDE.md §3) —
    // reconnect for live view to keep playing.
    if (mounted && liveViewController.status == LiveViewStatus.stopped) {
      liveViewController.connect();
    }
  }

  /// Quick Privacy Mode shortcut (LIVE-041) — toggles Off<->Full only, same
  /// as tapping the Off/Full tiles on `privacy_mode_screen.dart` (PRIV-002)
  /// but applied immediately, no draft/Apply step, matching Mute/Fullscreen's
  /// existing instant-apply pattern on this screen. If the camera is
  /// currently in Zone mode, this turns it Off rather than jumping to Full —
  /// zone configuration itself is left untouched for later, only reachable
  /// from the full Privacy Mode settings screen. Trusts the cached `Camera`
  /// model for the current mode shown (same as every other shortcut here)
  /// rather than re-fetching live on every screen open.
  Future<void> _togglePrivacyShortcut(Camera camera) async {
    final newMode = camera.privacyMode == CameraPrivacyMode.off
        ? CameraPrivacyMode.full
        : CameraPrivacyMode.off;
    setState(() => _isPrivacyShortcutBusy = true);

    final connection = camera.connection;
    final bool succeeded;
    if (connection != null) {
      final wireMode = newMode == CameraPrivacyMode.full
          ? PrivacyMode.full
          : PrivacyMode.none;
      final nuraeye = NuraeyeClient(connection);
      var result = await PrivacyModeClient(nuraeye).setPrivacyMode(wireMode);
      nuraeye.close();
      // A failed LAN Apply/Set retries over WAN before surfacing an error,
      // per mobile-app-screen-conventions.md's LAN/WAN convention.
      final thingName = connection.thingName;
      if (result is! CameraSuccess && thingName != null) {
        result = await WanPrivacyModeClient(thingName).setPrivacyMode(wireMode);
      }
      succeeded = result is CameraSuccess;
    } else {
      succeeded = await simulateCameraSave();
    }

    if (!mounted) return;
    setState(() => _isPrivacyShortcutBusy = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        camera.id,
        (current) => current.copyWith(privacyMode: newMode),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update privacy mode. Try again.'),
        ),
      );
    }
  }

  /// Quick Video Mode shortcut (LIVE-042) — cycles Day -> Auto -> Night ->
  /// Day on each tap, applied immediately (same instant-apply reasoning as
  /// [_togglePrivacyShortcut]). Doesn't gate on the camera's reported
  /// `IrCutFilter` capability list the way `video_mode_screen.dart` does
  /// (VIDMODE-004) — this shortcut always offers all three; a camera that
  /// doesn't support one will surface that as a failed Set instead.
  Future<void> _cycleVideoModeShortcut(Camera camera) async {
    const order = [
      CameraVideoMode.day,
      CameraVideoMode.auto,
      CameraVideoMode.night,
    ];
    final next = order[(order.indexOf(camera.videoMode) + 1) % order.length];
    setState(() => _isVideoModeShortcutBusy = true);

    final connection = camera.connection;
    final bool succeeded;
    if (connection != null) {
      final client = OnvifImagingClient(connection);
      var result = await client.setImagingSettings(
        ImagingSettings(irCutFilterMode: _videoModeToIrCutFilter(next)),
      );
      client.close();
      // A failed LAN Apply/Set retries over WAN before surfacing an error,
      // per mobile-app-screen-conventions.md's LAN/WAN convention.
      final thingName = connection.thingName;
      if (result is! CameraSuccess && thingName != null) {
        result = await WanImagingClient(
          thingName,
        ).setDayNightMode(_videoModeToIrCutFilter(next));
      }
      succeeded = result is CameraSuccess;
    } else {
      succeeded = await simulateCameraSave();
    }

    if (!mounted) return;
    setState(() => _isVideoModeShortcutBusy = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        camera.id,
        (current) => current.copyWith(videoMode: next),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update video mode. Try again.'),
        ),
      );
    }
  }

  /// The up-to-date [Camera], reflecting settings changes made elsewhere
  /// (e.g. On-Screen Display's OSD toggles). Falls back to the navigation
  /// snapshot if the camera can't be found (e.g. it was deleted).
  Camera _currentCamera(HomesState state) {
    for (final home in state.homes) {
      for (final camera in home.cameras) {
        if (camera.id == widget.camera.id) return camera;
      }
    }
    return widget.camera;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomesState>(
      valueListenable: widget.homesController,
      builder: (context, homesState, _) {
        final camera = _currentCamera(homesState);
        return _buildScaffold(context, camera);
      },
    );
  }

  /// Live tag, audio-recording indicator, Bitrate, and Signal Strength
  /// badges, positioned via [osdPositioned] with stack indices computed
  /// across all four so any that share a corner (Live tag and the
  /// audio-recording indicator are fixed top-left; Bitrate/Signal Strength
  /// are user-positioned from the Tags screen) stack instead of overlapping.
  List<Widget> _buildOsdTags(Camera camera) {
    final entries = [
      if (camera.liveTagOsdEnabled) OsdCorner.topLeft,
      if (camera.audioRecordingEnabled) OsdCorner.topLeft,
      if (camera.bitrateOsdEnabled) camera.bitrateOsdPosition,
      if (camera.signalStrengthOsdEnabled) camera.signalStrengthOsdPosition,
    ];
    final stackIndices = osdStackIndices(entries);
    var i = 0;

    return [
      if (camera.liveTagOsdEnabled)
        osdPositioned(
          OsdCorner.topLeft,
          stackIndex: stackIndices[i++],
          child: LiveStatusBadge(
            key: const Key('LIVE-004'),
            status: camera.liveStatus,
          ),
        ),
      if (camera.audioRecordingEnabled)
        osdPositioned(
          OsdCorner.topLeft,
          stackIndex: stackIndices[i++],
          child: const AudioRecordingBadge(key: Key('LIVE-037')),
        ),
      if (camera.bitrateOsdEnabled)
        osdPositioned(
          camera.bitrateOsdPosition,
          stackIndex: stackIndices[i++],
          child: BitrateBadge(
            key: const Key('LIVE-029'),
            configuredKbps: camera.bitrateKbps,
          ),
        ),
      if (camera.signalStrengthOsdEnabled)
        osdPositioned(
          camera.signalStrengthOsdPosition,
          stackIndex: stackIndices[i++],
          child: SignalStrengthBadge(
            key: const Key('LIVE-030'),
            signalStrength: camera.signalStrength,
            // Prefers the live-measured stream bitrate (real
            // RTCPeerConnection.getStats() reading) over the persisted
            // Camera.networkSpeedKbps, which only reflects whatever was
            // last measured — avoids re-persisting a value that changes
            // every couple of seconds into shared HomesController state.
            networkSpeedKbps:
                _liveViewController?.measuredBitrateKbps ??
                camera.networkSpeedKbps,
          ),
        ),
    ];
  }

  Future<bool> _confirmLeaveWhileRecording() async {
    if (!_isRecording) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('LIVE-031'),
        title: const Text('Recording in progress'),
        content: const Text('Stop and save the recording before leaving?'),
        actions: [
          TextButton(
            key: const Key('LIVE-032'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('LIVE-033'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Stop & Leave'),
          ),
        ],
      ),
    );
    if (shouldLeave == true) {
      await _stopRecording(save: true);
      return true;
    }
    return false;
  }

  Widget _buildScaffold(BuildContext context, Camera camera) {
    return LeaveGuard(
      canLeave: _confirmLeaveWhileRecording,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(key: const Key('LIVE-001'), camera.name),
            leading: IconButton(
              key: const Key('LIVE-002'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_connectivity.any(
                (result) => result != ConnectivityResult.none,
              ))
                Padding(
                  key: const Key('LIVE-038'),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _connectivity.contains(ConnectivityResult.wifi)
                            ? Icons.wifi
                            : Icons.signal_cellular_alt,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        // Real measured throughput (same
                        // RTCPeerConnection.getStats() reading LIVE-030
                        // uses) appended when available — the actual rate
                        // data is currently arriving at, on whichever
                        // network the phone is on, not just which network
                        // type it is. No measurement exists yet on WAN or
                        // before the first two stats samples land.
                        _liveViewController?.measuredBitrateKbps != null
                            ? '${_connectivity.contains(ConnectivityResult.wifi) ? 'Wi-Fi' : 'Mobile data'} · ${formatBitrate(_liveViewController!.measuredBitrateKbps!)}'
                            : _connectivity.contains(ConnectivityResult.wifi)
                            ? 'Wi-Fi'
                            : 'Mobile data',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              IconButton(
                key: const Key('LIVE-017'),
                tooltip: 'Camera settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(
                  '${GoRouterState.of(context).matchedLocation}/${CameraSettingsScreen.routeName}',
                  extra: camera,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (camera.isOnline)
                      RepaintBoundary(
                        key: _videoBoundaryKey,
                        child: _HeroVideo(
                          videoController: _videoController,
                          liveViewController: _liveViewController,
                          showLiveView: _tabController.index == 0,
                        ),
                      )
                    else
                      Positioned.fill(child: _OfflineThumbnail(camera: camera)),
                    if (!camera.isOnline)
                      Positioned.fill(
                        child: _OfflineOverlay(
                          key: const Key('LIVE-028'),
                          camera: camera,
                        ),
                      ),
                    ..._buildOsdTags(camera),
                    Positioned(
                      left: 8,
                      bottom: _cornerButtonBottomInset,
                      child: _VideoOverlayButton(
                        key: const Key('LIVE-007'),
                        tooltip: _isMuted ? 'Unmute' : 'Mute',
                        icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                        onPressed: camera.isOnline ? _toggleMute : null,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: _cornerButtonBottomInset,
                      child: _VideoOverlayButton(
                        key: const Key('LIVE-008'),
                        tooltip: 'Fullscreen',
                        icon: Icons.fullscreen,
                        onPressed: camera.isOnline ? _openFullscreen : null,
                      ),
                    ),
                    // Two-way talk (LIVE-011) stays on this same screen —
                    // the video keeps playing behind this status bar rather
                    // than being replaced by a separate full-screen call
                    // page, so you can still see who/what you're talking to.
                    if (_liveViewController != null &&
                        _liveViewController!.talkStatus != TalkStatus.idle)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _TalkStatusBar(
                          key: const Key('TALK-001'),
                          controller: _liveViewController!,
                          onEnd: _toggleTalk,
                        ),
                      ),
                  ],
                ),
              ),
              TabBar(
                key: const Key('LIVE-005'),
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Live'),
                  Tab(text: 'Playback'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _LiveControls(
                      isEnabled: camera.isOnline,
                      isRecording: _isRecording,
                      recordingElapsed: _recordingElapsed,
                      isTalking:
                          (_liveViewController?.talkStatus ??
                              TalkStatus.idle) !=
                          TalkStatus.idle,
                      isSpotlightOn: _isSpotlightOn,
                      privacyMode: camera.privacyMode,
                      isPrivacyShortcutBusy: _isPrivacyShortcutBusy,
                      videoMode: camera.videoMode,
                      isVideoModeShortcutBusy: _isVideoModeShortcutBusy,
                      onSnapshot: _takeSnapshot,
                      onRecord: _toggleRecording,
                      onTalk: _toggleTalk,
                      onSpotlight: () =>
                          setState(() => _isSpotlightOn = !_isSpotlightOn),
                      onPrivacy: () => _togglePrivacyShortcut(camera),
                      onVideoMode: () => _cycleVideoModeShortcut(camera),
                      onAiMode: () => _openAiMode(camera),
                    ),
                    _PlaybackTab(
                      controller: _videoController,
                      isActive: _tabController.index == 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small circular icon button overlaid directly on the video surface
/// (bottom-left mute, bottom-right fullscreen).
class _VideoOverlayButton extends StatelessWidget {
  const _VideoOverlayButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Opacity(
      opacity: isEnabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Last-known snapshot shown in place of the live video feed while the
/// camera is offline — same `camera.thumbnailUrl` used on the Dashboard
/// tiles, so the offline state still shows something recognizable instead
/// of a blank/frozen player.
class _OfflineThumbnail extends StatelessWidget {
  const _OfflineThumbnail({required this.camera});

  final Camera camera;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = camera.thumbnailUrl;
    if (thumbnailUrl == null) {
      return const ColoredBox(color: Colors.black);
    }
    return CameraThumbnailImage(
      thumbnailUrl: thumbnailUrl,
      fit: BoxFit.cover,
      placeholderBuilder: () => const ColoredBox(color: Colors.black),
    );
  }
}

/// Dark overlay shown over the video when the camera is offline: icon,
/// "Camera Offline", and "Last seen …" if known — same visual language as
/// the offline overlay on the Dashboard's camera tiles.
class _OfflineOverlay extends StatelessWidget {
  const _OfflineOverlay({super.key, required this.camera});

  final Camera camera;

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera Offline',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            if (camera.lastSeen != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Last seen ${_relativeTime(camera.lastSeen!)}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Video surface with pinch-to-zoom (via [InteractiveViewer]) so the feed
/// can be zoomed digitally in both the Live and Playback tabs, and in
/// fullscreen.
class _VideoSurface extends StatelessWidget {
  const _VideoSurface({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: InteractiveViewer(
        maxScale: 4,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

/// Small "Remote" chip shown over the video whenever the current session is
/// playing over WAN (KVS/HLS) rather than the LAN WebRTC path — the two have
/// materially different latency (STREAMING_GUIDE.md §1: sub-second on LAN
/// vs. several seconds on WAN), so it's worth surfacing which one is active
/// rather than leaving that invisible.
class _RemoteStreamBadge extends StatelessWidget {
  const _RemoteStreamBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_outlined, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Remote',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks between the real LAN WebRTC live feed ([liveViewController], shown
/// when [showLiveView] is true and a controller exists) and the dummy-asset
/// fallback (`_VideoSurface(videoController)`) — used for the Playback tab,
/// and for any camera with no saved LAN connection yet (same
/// falls-back-to-local-state convention as every other camera-settings
/// screen). Reused by both the inline hero video area and
/// [_FullscreenVideo] so fullscreen shows whatever was already on screen.
class _HeroVideo extends StatelessWidget {
  const _HeroVideo({
    required this.videoController,
    required this.liveViewController,
    required this.showLiveView,
  });

  final VideoPlayerController videoController;
  final LiveViewController? liveViewController;
  final bool showLiveView;

  @override
  Widget build(BuildContext context) {
    final controller = liveViewController;
    if (!showLiveView || controller == null) {
      return _VideoSurface(controller: videoController);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        switch (controller.status) {
          case LiveViewStatus.connecting:
          case LiveViewStatus.reconnecting:
            return ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      controller.status == LiveViewStatus.reconnecting
                          ? 'Reconnecting…'
                          : 'Connecting…',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          case LiveViewStatus.connected:
            final wanController = controller.wanVideoController;
            if (controller.transport == LiveViewTransport.wan &&
                wanController != null) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _VideoSurface(controller: wanController),
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _RemoteStreamBadge(),
                  ),
                ],
              );
            }
            return RTCVideoView(
              controller.renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            );
          case LiveViewStatus.failed:
            return ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white70, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Camera Offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Retrying automatically…',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.connect,
                      child: const Text('Retry now'),
                    ),
                  ],
                ),
              ),
            );
          case LiveViewStatus.stopped:
            return ColoredBox(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white70, size: 32),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        controller.errorMessage ?? "Couldn't connect to camera",
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.connect,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}

class _LiveControls extends StatelessWidget {
  const _LiveControls({
    required this.isEnabled,
    required this.isRecording,
    required this.recordingElapsed,
    required this.isTalking,
    required this.isSpotlightOn,
    required this.privacyMode,
    required this.isPrivacyShortcutBusy,
    required this.videoMode,
    required this.isVideoModeShortcutBusy,
    required this.onSnapshot,
    required this.onRecord,
    required this.onTalk,
    required this.onSpotlight,
    required this.onPrivacy,
    required this.onVideoMode,
    required this.onAiMode,
  });

  final bool isEnabled;
  final bool isRecording;
  final Duration recordingElapsed;
  final bool isTalking;
  final bool isSpotlightOn;
  final CameraPrivacyMode privacyMode;
  final bool isPrivacyShortcutBusy;
  final CameraVideoMode videoMode;
  final bool isVideoModeShortcutBusy;
  final VoidCallback onSnapshot;
  final VoidCallback onRecord;
  final VoidCallback onTalk;
  final VoidCallback onSpotlight;
  final VoidCallback onPrivacy;
  final VoidCallback onVideoMode;
  final VoidCallback onAiMode;

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ControlTile(
                    key: const Key('LIVE-009'),
                    label: 'Snapshot',
                    icon: Icons.camera_alt_outlined,
                    onPressed: isEnabled ? onSnapshot : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ControlTile(
                    key: const Key('LIVE-010'),
                    label: isRecording
                        ? _formatElapsed(recordingElapsed)
                        : 'Record',
                    icon: isRecording
                        ? Icons.stop_circle
                        : Icons.fiber_manual_record,
                    color: isRecording ? AppColors.offline : null,
                    onPressed: isEnabled ? onRecord : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ControlTile(
                    key: const Key('LIVE-011'),
                    label: isTalking ? 'Stop talking' : 'Talk',
                    icon: isTalking ? Icons.mic : Icons.mic_none,
                    color: isTalking ? AppColors.cyan : null,
                    onPressed: isEnabled ? onTalk : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ControlTile(
                    key: const Key('LIVE-018'),
                    label: isSpotlightOn ? 'Spotlight off' : 'Spotlight',
                    icon: isSpotlightOn
                        ? Icons.flashlight_on
                        : Icons.flashlight_off_outlined,
                    color: isSpotlightOn ? Colors.amber : null,
                    onPressed: isEnabled ? onSpotlight : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ControlTile(
                    key: const Key('LIVE-041'),
                    label: switch (privacyMode) {
                      CameraPrivacyMode.off => 'Privacy Off',
                      CameraPrivacyMode.full => 'Privacy Full',
                      CameraPrivacyMode.zone => 'Privacy Zone',
                    },
                    icon: switch (privacyMode) {
                      CameraPrivacyMode.off => Icons.visibility_outlined,
                      CameraPrivacyMode.full => Icons.visibility_off,
                      CameraPrivacyMode.zone => Icons.crop_square,
                    },
                    color: privacyMode == CameraPrivacyMode.off
                        ? null
                        : AppColors.offline,
                    onPressed: (isEnabled && !isPrivacyShortcutBusy)
                        ? onPrivacy
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ControlTile(
                    key: const Key('LIVE-042'),
                    label: switch (videoMode) {
                      CameraVideoMode.day => 'Day',
                      CameraVideoMode.auto => 'Auto',
                      CameraVideoMode.night => 'Night',
                    },
                    icon: switch (videoMode) {
                      CameraVideoMode.day => Icons.wb_sunny,
                      CameraVideoMode.auto => Icons.brightness_auto,
                      CameraVideoMode.night => Icons.nightlight_round,
                    },
                    onPressed: (isEnabled && !isVideoModeShortcutBusy)
                        ? onVideoMode
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ControlTile(
                    key: const Key('LIVE-043'),
                    label: 'AI Mode',
                    icon: Icons.auto_awesome_outlined,
                    color: AppColors.cyan,
                    onPressed: isEnabled ? onAiMode : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One square card in the Live tab's single-row quick-actions bar: icon
/// above a text label, tappable as a whole.
class _ControlTile extends StatelessWidget {
  const _ControlTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;
    final tint = isEnabled
        ? (color ?? colorScheme.onSurface)
        : colorScheme.onSurface.withValues(alpha: 0.35);

    return SizedBox(
      height: 76,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.6,
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: tint, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One full-day recording entry in the Playback recordings list. Stub data
/// until a real recordings backend exists — every day currently maps to the
/// same dummy video.
class _RecordingDay {
  const _RecordingDay(this.date);

  final DateTime date;
}

/// Type of a detection event used only to space out `_jumpToEvent`'s mock
/// timestamps — not rendered as a timeline marker, since Playback shows only
/// the recording-availability band, not individual events (see EventsScreen
/// for the event-browsing timeline).
enum _EventType { motion, ai }

/// A single event marker, positioned as a fraction of the 24-hour day.
class _TimelineEvent {
  const _TimelineEvent({
    required this.type,
    required this.startFraction,
    required this.endFraction,
  });

  final _EventType type;
  final double startFraction;
  final double endFraction;
}

/// Mock recording-coverage data for the day's timeline band — two gaps
/// included so the gray "no recording" dead zone (and Playback's snap-back
/// behavior) are demonstrable, until a real recordings backend exists (see
/// CLAUDE.md).
const _mockRecordedRanges = [
  TimelineRange(0, 0.25),
  TimelineRange(0.2708, 0.5833),
  TimelineRange(0.6042, 1),
];

/// Stub event data for one day: a handful of motion/AI detections spread
/// across the day, mirroring what a real detection backend would eventually
/// report.
List<_TimelineEvent> _mockDayEvents() {
  const daySeconds = 24 * 3600;
  Duration at(int h, int m) => Duration(hours: h, minutes: m);
  double frac(Duration d) => d.inSeconds / daySeconds;

  return [
    _TimelineEvent(
      type: _EventType.motion,
      startFraction: frac(at(2, 0)),
      endFraction: frac(at(2, 5)),
    ),
    _TimelineEvent(
      type: _EventType.ai,
      startFraction: frac(at(4, 0)),
      endFraction: frac(at(4, 10)),
    ),
    _TimelineEvent(
      type: _EventType.motion,
      startFraction: frac(at(8, 0)),
      endFraction: frac(at(8, 15)),
    ),
    _TimelineEvent(
      type: _EventType.ai,
      startFraction: frac(at(8, 5)),
      endFraction: frac(at(8, 10)),
    ),
    _TimelineEvent(
      type: _EventType.motion,
      startFraction: frac(at(12, 0)),
      endFraction: frac(at(12, 15)),
    ),
    _TimelineEvent(
      type: _EventType.ai,
      startFraction: frac(at(18, 0)),
      endFraction: frac(at(18, 15)),
    ),
  ];
}

/// Playback tab: a day selector, a shared [CameraTimeline] (zoomable,
/// recording-availability band, event markers) with prev/next-event
/// controls, and two draggable handles on the timeline itself marking the
/// clip extraction range — all operating on the shared dummy video.
class _PlaybackTab extends StatefulWidget {
  const _PlaybackTab({required this.controller, required this.isActive});

  final VideoPlayerController controller;

  /// Whether the Playback tab is the currently selected tab.
  final bool isActive;

  @override
  State<_PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends State<_PlaybackTab> {
  late final List<_RecordingDay> _recordingDays = List.generate(
    7,
    (i) => _RecordingDay(DateTime.now().subtract(Duration(days: i))),
  );
  late final List<_TimelineEvent> _events = _mockDayEvents();
  int _selectedDayIndex = 0;

  /// Fraction of the 24-hour day the needle currently sits at — the source
  /// of truth for both the needle's displayed time and the dummy video's
  /// looped playback position.
  double _dayFraction = 8 / 24;

  /// Clip extraction boundaries, set by dragging the two handles directly on
  /// the timeline. Always non-null once a day is selected — there's no
  /// separate "Set Start"/"Set End" step, unlike the earlier button-based
  /// flow.
  late double _clipStartFraction = _dayFraction - (5 / (24 * 60));
  late double _clipEndFraction = _dayFraction + (5 / (24 * 60));

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant _PlaybackTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // The dummy video is shared with the Live tab, which keeps it
      // playing freely from wherever it's at. Snap it to match this tab's
      // timeline needle each time Playback becomes the visible tab, so the
      // video and the needle agree instead of showing unrelated moments.
      _seekToFraction(_dayFraction);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _selectDay(int index) {
    setState(() {
      _selectedDayIndex = index;
      _dayFraction = 8 / 24;
      _clipStartFraction = _dayFraction - (5 / (24 * 60));
      _clipEndFraction = _dayFraction + (5 / (24 * 60));
    });
  }

  void _onClipSelectionChanged(double start, double end) {
    setState(() {
      _clipStartFraction = start;
      _clipEndFraction = end;
    });
  }

  void _seekToFraction(double fraction) {
    setState(() => _dayFraction = fraction.clamp(0.0, 1.0));
    final duration = widget.controller.value.duration;
    if (duration > Duration.zero) {
      widget.controller.seekTo(duration * _dayFraction);
    }
  }

  void _jumpToEvent(int direction) {
    final candidates = _events.map((e) => e.startFraction).toList()..sort();
    if (candidates.isEmpty) return;

    if (direction > 0) {
      final next = candidates.firstWhere(
        (f) => f > _dayFraction + 0.0005,
        orElse: () => candidates.first,
      );
      _seekToFraction(next);
    } else {
      final prev = candidates.lastWhere(
        (f) => f < _dayFraction - 0.0005,
        orElse: () => candidates.last,
      );
      _seekToFraction(prev);
    }
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dayName = isToday ? 'Today' : '${months[date.month - 1]} ${date.day}';
    return '$dayName · 12:00 AM – 11:59 PM';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: PopupMenuButton<int>(
            key: const Key('LIVE-019'),
            tooltip: 'Choose a recorded day',
            offset: const Offset(0, 44),
            onSelected: _selectDay,
            itemBuilder: (context) => [
              for (var i = 0; i < _recordingDays.length; i++)
                PopupMenuItem<int>(
                  key: Key('LIVE-019-$i'),
                  value: i,
                  child: Row(
                    children: [
                      if (i == _selectedDayIndex)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(_formatDayLabel(_recordingDays[i].date)),
                    ],
                  ),
                ),
            ],
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatDayLabel(_recordingDays[_selectedDayIndex].date),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                key: const Key('LIVE-013'),
                onPressed: () => _jumpToEvent(-1),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Prev Event'),
              ),
              TextButton.icon(
                key: const Key('LIVE-020'),
                onPressed: () => _jumpToEvent(1),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Next Event'),
                iconAlignment: IconAlignment.end,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CameraTimeline(
            rulerKey: const Key('LIVE-012'),
            zoomOutKey: const Key('LIVE-034'),
            zoomInKey: const Key('LIVE-035'),
            timeLabelKey: const Key('LIVE-014'),
            legendKey: const Key('LIVE-021'),
            recordingBandKey: const Key('LIVE-036'),
            needleFraction: _dayFraction,
            onNeedleFractionChanged: _seekToFraction,
            enforceRecordingBounds: true,
            recordedRanges: _mockRecordedRanges,
            legend: const [
              TimelineLegendEntry(color: kRecordedBandColor, label: 'Recorded'),
            ],
            markers: const [],
            selectionStartFraction: _clipStartFraction,
            selectionEndFraction: _clipEndFraction,
            selectionStartKey: const Key('LIVE-023'),
            selectionEndKey: const Key('LIVE-024'),
            onSelectionChanged: _onClipSelectionChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                key: const Key('LIVE-015'),
                tooltip: 'Snapshot',
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('LIVE-016'),
                tooltip: 'Download clip',
                icon: const Icon(Icons.download_outlined),
                onPressed: _clipStartFraction < _clipEndFraction ? () {} : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown when a recording hits the 5-minute limit: asks whether to keep
/// recording, counting down from [countdown]. If the countdown reaches
/// zero without a tap, the dialog closes as if "Stop" was pressed (the
/// caller then saves what's been recorded so far).
class _ContinueRecordingDialog extends StatefulWidget {
  const _ContinueRecordingDialog({required this.countdown});

  final Duration countdown;

  @override
  State<_ContinueRecordingDialog> createState() =>
      _ContinueRecordingDialogState();
}

class _ContinueRecordingDialogState extends State<_ContinueRecordingDialog> {
  late int _secondsLeft = widget.countdown.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        Navigator.of(context).pop(false);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('LIVE-025'),
      title: const Text('Continue recording?'),
      content: Text(
        'You\'ve reached the 5-minute recording limit. '
        'Stopping in $_secondsLeft s and saving the clip unless you continue.',
      ),
      actions: [
        TextButton(
          key: const Key('LIVE-026'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Stop'),
        ),
        FilledButton(
          key: const Key('LIVE-027'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// Inline two-way-talk status bar (TALK-001) — overlaid at the bottom edge
/// of the video (not a separate full-screen page) so the feed stays
/// visible throughout a call, per user feedback that a full-screen panel
/// hides exactly what you'd want to see while talking to someone on
/// camera. Still implements `TWO_WAY_TALK_GUIDE.md` §5's call-style
/// contract — a distinct connecting/talking/busy/error state (not just a
/// spinner-or-not toggle) and a speakerphone control — just docked inline
/// instead of taking over the screen. [_CameraLiveScreenState._toggleTalk]
/// is what actually starts/ends the session and funnels every exit path
/// (this bar's End button, or just leaving the screen) through
/// [LiveViewController.endTalk]/`stop()`.
class _TalkStatusBar extends StatelessWidget {
  const _TalkStatusBar({
    super.key,
    required this.controller,
    required this.onEnd,
  });

  final LiveViewController controller;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final status = controller.talkStatus;
    final speakerphoneOn = controller.speakerphoneOn;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                key: const Key('TALK-002'),
                switch (status) {
                  TalkStatus.connecting => Icons.phone_in_talk_outlined,
                  TalkStatus.talking => Icons.mic,
                  TalkStatus.busy => Icons.person_off_outlined,
                  TalkStatus.error => Icons.error_outline,
                  TalkStatus.idle => Icons.mic_none,
                },
                size: 20,
                color: switch (status) {
                  TalkStatus.talking => AppColors.cyan,
                  TalkStatus.busy || TalkStatus.error => AppColors.offline,
                  TalkStatus.connecting || TalkStatus.idle => Colors.white70,
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  key: const Key('TALK-003'),
                  switch (status) {
                    TalkStatus.connecting => 'Calling…',
                    TalkStatus.talking => 'Talking',
                    TalkStatus.busy =>
                      "Camera's busy — someone else is talking",
                    TalkStatus.error =>
                      controller.talkErrorMessage ?? 'Something went wrong',
                    TalkStatus.idle => 'Ending…',
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status == TalkStatus.talking)
                IconButton(
                  key: const Key('TALK-004'),
                  tooltip: speakerphoneOn ? 'Speaker on' : 'Speaker off',
                  color: speakerphoneOn ? AppColors.cyan : Colors.white70,
                  icon: const Icon(Icons.volume_up),
                  onPressed: () =>
                      controller.setSpeakerphoneOn(!speakerphoneOn),
                ),
              IconButton(
                key: const Key('TALK-005'),
                tooltip: 'End',
                color: AppColors.offline,
                icon: const Icon(Icons.call_end),
                onPressed: onEnd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideo extends StatefulWidget {
  const _FullscreenVideo({
    required this.controller,
    required this.liveViewController,
    required this.showLiveView,
    required this.isMuted,
    required this.onMuteChanged,
  });

  final VideoPlayerController controller;
  final LiveViewController? liveViewController;
  final bool showLiveView;
  final bool isMuted;
  final ValueChanged<bool> onMuteChanged;

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  late bool _isMuted = widget.isMuted;

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      widget.controller.setVolume(_isMuted ? 0 : 1);
      widget.liveViewController?.setAudioEnabled(!_isMuted);
      widget.liveViewController?.wanVideoController?.setVolume(
        _isMuted ? 0 : 1,
      );
    });
    widget.onMuteChanged(_isMuted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _HeroVideo(
                videoController: widget.controller,
                liveViewController: widget.liveViewController,
                showLiveView: widget.showLiveView,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: IconButton(
                tooltip: _isMuted ? 'Unmute' : 'Mute',
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: _toggleMute,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Exit fullscreen',
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
