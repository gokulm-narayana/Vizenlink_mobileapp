import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera_api/camera_api.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:video_player/video_player.dart';
import '../../app_state/debug_transport_override.dart';
import '../../app_state/homes_controller.dart';
import '../../app_state/live_view_controller.dart';
import '../../models/camera.dart';
import '../../models/home.dart';
import '../../widgets/camera_thumbnail_image.dart';
import '../../widgets/settings_save_button.dart' show simulateCameraSave;
import 'multiview_reorder_screen.dart';

/// Watch-all-at-once grid for one home's cameras — see
/// docs/screens/multiview/multiview_screen.md. Distinct from the Dashboard's
/// grid/list layout (which is for browsing/navigating to a single camera):
/// this screen is a live-viewing surface, one [LiveViewController] per
/// visible tile.
///
/// A modal takeover pushed on the root [Navigator] (`rootNavigator: true`,
/// same as CameraLiveScreen's fullscreen/AI Mode) rather than a nested
/// go_router route — this screen lives inside the Dashboard branch's own
/// nested Navigator like every other camera screen does, so a plain
/// `context.push` route would still render underneath MainShell's bottom
/// nav bar. Escaping to the root Navigator is what actually removes it,
/// same reason fullscreen/AI Mode do the same thing.
class MultiviewScreen extends StatefulWidget {
  const MultiviewScreen({
    super.key,
    required this.home,
    required this.homesController,
  });

  final Home home;
  final HomesController homesController;

  @override
  State<MultiviewScreen> createState() => _MultiviewScreenState();
}

enum MultiviewLayout { single, grid2x2, grid3x3 }

class _MultiviewScreenState extends State<MultiviewScreen> {
  MultiviewLayout _layout = MultiviewLayout.grid2x2;
  MultiviewLayout _previousLayout = MultiviewLayout.grid2x2;
  int _focusedIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    // Forces landscape on entry, same as CameraLiveScreen's fullscreen —
    // watching several tiles at once benefits from the wider frame the way
    // fullscreen single-camera viewing does.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _setLayout(MultiviewLayout layout) {
    if (_layout == layout) return;
    setState(() => _layout = layout);
  }

  void _cycleLayout() {
    switch (_layout) {
      case MultiviewLayout.single:
        _setLayout(MultiviewLayout.grid2x2);
      case MultiviewLayout.grid2x2:
        _setLayout(MultiviewLayout.grid3x3);
      case MultiviewLayout.grid3x3:
        _setLayout(MultiviewLayout.single);
    }
  }

  /// Reordering is a plain list, not a video wall — unlike the rest of this
  /// screen it reads fine in portrait, so this temporarily lifts the
  /// landscape-only lock [initState] applies for as long as the reorder
  /// screen is open, then restores it once the user comes back.
  Future<void> _openReorderScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiviewReorderScreen(
          homeId: widget.home.id,
          homesController: widget.homesController,
        ),
      ),
    );
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Home _currentHome(HomesState state) {
    for (final home in state.homes) {
      if (home.id == widget.home.id) return home;
    }
    return widget.home;
  }

  /// Zooms in to a single camera in full screen (1x1 mode) without navigating
  /// away from the Multiview screen.
  void _focusCamera(int index) {
    setState(() {
      _focusedIndex = index;
      _previousLayout = _layout;
      _layout = MultiviewLayout.single;
      _pageController?.dispose();
      _pageController = PageController(initialPage: _focusedIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HomesState>(
      valueListenable: widget.homesController,
      builder: (context, state, _) {
        final home = _currentHome(state);
        final cameras = home.cameras;
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Builder(
                  builder: (context) {
                    if (cameras.isEmpty) {
                      return Center(
                        child: Text(
                          key: const Key('MULTIVIEW-006'),
                          'No cameras in ${home.name} yet',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    if (_layout == MultiviewLayout.single) {
                      _pageController ??= PageController(
                        initialPage: _focusedIndex,
                      );
                      return PageView.builder(
                        controller: _pageController,
                        itemCount: cameras.length,
                        onPageChanged: (index) => _focusedIndex = index,
                        itemBuilder: (context, index) {
                          final camera = cameras[index];
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: _MultiviewTile(
                              key: ValueKey('MULTIVIEW-004-${camera.id}'),
                              camera: camera,
                              isFullScreen: true,
                              // Full resolution — a single full-screen tile
                              // has the display budget for it.
                              profile: 'Profile_1',
                              onDoubleTap: () => _focusCamera(index),
                            ),
                          );
                        },
                      );
                    }

                    final crossAxisCount = _layout == MultiviewLayout.grid2x2
                        ? 2
                        : 3;
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: List.generate(crossAxisCount, (rowIndex) {
                          return Expanded(
                            child: Row(
                              children: List.generate(crossAxisCount, (
                                colIndex,
                              ) {
                                final index =
                                    rowIndex * crossAxisCount + colIndex;
                                Widget tile;
                                if (index < cameras.length) {
                                  final camera = cameras[index];
                                  tile = _MultiviewTile(
                                    key: ValueKey('MULTIVIEW-004-${camera.id}'),
                                    camera: camera,
                                    isFullScreen: false,
                                    // Smaller tile, smaller display budget —
                                    // 2x2 doesn't need full resolution, 3x3
                                    // needs even less. Cuts bandwidth/CPU
                                    // load across the several concurrent
                                    // connections a grid opens at once.
                                    profile: _layout == MultiviewLayout.grid2x2
                                        ? 'Profile_2'
                                        : 'Profile_3',
                                    onDoubleTap: () => _focusCamera(index),
                                  );
                                } else {
                                  tile = const _BlankTile();
                                }

                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: rowIndex == 0 ? 0 : 4,
                                      bottom: rowIndex == crossAxisCount - 1
                                          ? 0
                                          : 4,
                                      left: colIndex == 0 ? 0 : 4,
                                      right: colIndex == crossAxisCount - 1
                                          ? 0
                                          : 4,
                                    ),
                                    child: tile,
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OverlayButton(
                        key: const Key('MULTIVIEW-001'),
                        tooltip: 'Back',
                        icon: Icons.arrow_back,
                        onPressed: () {
                          if (_layout == MultiviewLayout.single) {
                            _setLayout(_previousLayout);
                          } else {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            key: const Key('MULTIVIEW-002'),
                            home.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OverlayButton(
                        key: const Key('MULTIVIEW-009'),
                        tooltip: 'Reorder Cameras',
                        icon: Icons.reorder,
                        onPressed: _openReorderScreen,
                      ),
                      const SizedBox(width: 8),
                      _OverlayButton(
                        key: const Key('MULTIVIEW-003'),
                        tooltip: 'Change Layout',
                        icon: _layout == MultiviewLayout.single
                            ? Icons.crop_square
                            : _layout == MultiviewLayout.grid2x2
                            ? Icons.grid_view
                            : Icons.grid_on,
                        onPressed: _cycleLayout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small circular icon button overlaid on the black surface — same visual
/// treatment as CameraLiveScreen's video-overlay buttons (mute/fullscreen).
class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}

/// One camera's tile — owns its own [LiveViewController] (per
/// STREAMING_GUIDE.md, one connection per signaling port; not shareable
/// across tiles) for the lifetime of this widget. Connects in [initState]
/// and disposes/stops in [dispose], so a tile scrolled far enough out of
/// [GridView]'s cache extent to be removed from the tree tears down its
/// connection, and a tile scrolled back into view reconnects fresh.
class _MultiviewTile extends StatefulWidget {
  const _MultiviewTile({
    super.key,
    required this.camera,
    required this.onDoubleTap,
    this.isFullScreen = false,
    this.profile,
  });

  final Camera camera;
  final VoidCallback onDoubleTap;
  final bool isFullScreen;

  /// Which of the camera's fixed resolution tiers (`Profile_1`/`Profile_2`/
  /// `Profile_3`) to open this tile's [LiveViewController] at — sized to how
  /// much screen space this tile actually has (see call sites). Null
  /// defaults to `Profile_1`.
  final String? profile;

  @override
  State<_MultiviewTile> createState() => _MultiviewTileState();
}

class _MultiviewTileState extends State<_MultiviewTile> {
  LiveViewController? _controller;
  bool _isSpotlightOn = false;
  bool _isSirenOn = false;
  bool _isWarningOn = false;
  bool _isSpotlightShortcutBusy = false;
  bool _isSirenShortcutBusy = false;
  bool _isWarningShortcutBusy = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFullScreen) _loadDeterrenceStatus();
    if (!widget.camera.isOnline) return;
    final connection = widget.camera.connection;
    if (connection == null) return;
    _controller =
        LiveViewController(
            connection,
            initialProfile: widget.profile,
            forceTransport: DebugTransportOverride.instance.value,
          )
          ..addListener(_onChanged)
          ..connect();
  }

  @override
  void didUpdateWidget(covariant _MultiviewTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFullScreen && !oldWidget.isFullScreen) {
      _loadDeterrenceStatus();
    }
  }

  Future<void> _loadDeterrenceStatus() async {
    final connection = widget.camera.connection;
    if (connection == null) return;
    final nuraeye = NuraeyeClient(connection);
    final statusResult = await DeterrenceClient(nuraeye).getDeterrenceStatus();
    nuraeye.close();
    if (!mounted) return;
    if (statusResult case CameraSuccess(:final value)) {
      setState(() {
        _isSpotlightOn = value.spotlight;
        _isSirenOn = value.siren;
        _isWarningOn = value.warning;
      });
    }
  }

  Future<bool> _sendDeterrenceAction(
    Camera camera,
    String action, {
    required bool turningOn,
  }) async {
    final connection = camera.connection;
    if (connection == null) return simulateCameraSave();

    final nuraeye = NuraeyeClient(connection);
    final client = DeterrenceClient(nuraeye);
    var result = turningOn
        ? await client.activateDeterrence(action)
        : await client.deactivateDeterrence(action);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      final wanClient = WanDeterrenceClient(thingName);
      result = turningOn
          ? await wanClient.activateDeterrence(action)
          : await wanClient.deactivateDeterrence(action);
    }
    return result is CameraSuccess;
  }

  Future<void> _toggleSpotlight() async {
    final turningOn = !_isSpotlightOn;
    setState(() => _isSpotlightShortcutBusy = true);
    final succeeded = await _sendDeterrenceAction(
      widget.camera,
      'spotlight',
      turningOn: turningOn,
    );
    if (!mounted) return;
    setState(() => _isSpotlightShortcutBusy = false);
    if (succeeded) {
      setState(() => _isSpotlightOn = turningOn);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${turningOn ? 'turn on' : 'turn off'} spotlight. Try again.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleSiren() async {
    final turningOn = !_isSirenOn;
    setState(() => _isSirenShortcutBusy = true);
    final succeeded = await _sendDeterrenceAction(
      widget.camera,
      'siren',
      turningOn: turningOn,
    );
    if (!mounted) return;
    setState(() => _isSirenShortcutBusy = false);
    if (succeeded) {
      setState(() => _isSirenOn = turningOn);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${turningOn ? 'turn on' : 'turn off'} siren. Try again.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleWarning() async {
    final turningOn = !_isWarningOn;
    setState(() => _isWarningShortcutBusy = true);
    final succeeded = await _sendDeterrenceAction(
      widget.camera,
      'warning',
      turningOn: turningOn,
    );
    if (!mounted) return;
    setState(() => _isWarningShortcutBusy = false);
    if (succeeded) {
      setState(() => _isWarningOn = turningOn);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${turningOn ? 'turn on' : 'turn off'} warning. Try again.',
          ),
        ),
      );
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_onChanged);
    controller?.stop();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            _buildVideo(),
            Positioned(
              left: 4,
              right: 4,
              bottom: 4,
              child: Text(
                widget.camera.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
            if (widget.isFullScreen)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.camera.spotlightCapable != false) ...[
                        _isSpotlightShortcutBusy
                            ? const SizedBox.square(
                                dimension: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _OverlayButton(
                                key: const Key('MULTIVIEW-010'),
                                icon: _isSpotlightOn
                                    ? Icons.lightbulb
                                    : Icons.lightbulb_outline,
                                tooltip: 'Spotlight',
                                onPressed: _toggleSpotlight,
                              ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.camera.sirenCapable != false) ...[
                        _isSirenShortcutBusy
                            ? const SizedBox.square(
                                dimension: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _OverlayButton(
                                key: const Key('MULTIVIEW-011'),
                                icon: _isSirenOn
                                    ? Icons.campaign
                                    : Icons.campaign_outlined,
                                tooltip: 'Siren',
                                onPressed: _toggleSiren,
                              ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.camera.warningCapable != false) ...[
                        _isWarningShortcutBusy
                            ? const SizedBox.square(
                                dimension: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : _OverlayButton(
                                key: const Key('MULTIVIEW-012'),
                                icon: _isWarningOn
                                    ? Icons.volume_up
                                    : Icons.volume_mute,
                                tooltip: 'Warning',
                                onPressed: _toggleWarning,
                              ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final camera = widget.camera;
    if (!camera.isOnline) return _OfflinePlaceholder(camera: camera);

    final controller = _controller;
    if (controller == null) return _OfflinePlaceholder(camera: camera);

    switch (controller.status) {
      case LiveViewStatus.connected:
        if (controller.transport == LiveViewTransport.lan) {
          return RTCVideoView(
            controller.renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          );
        }
        final wanController = controller.wanVideoController;
        if (wanController != null && wanController.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: wanController.value.size.width,
              height: wanController.value.size.height,
              child: VideoPlayer(wanController),
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case LiveViewStatus.failed:
        return _ErrorPlaceholder(
          key: const Key('MULTIVIEW-008'),
          onRetry: controller.connect,
        );
      case LiveViewStatus.connecting:
      case LiveViewStatus.reconnecting:
        return const Center(
          key: Key('MULTIVIEW-007'),
          child: CircularProgressIndicator(color: Colors.white),
        );
      case LiveViewStatus.stopped:
        return _OfflinePlaceholder(camera: camera);
    }
  }
}

class _OfflinePlaceholder extends StatelessWidget {
  const _OfflinePlaceholder({required this.camera});

  final Camera camera;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = camera.thumbnailUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl != null)
          CameraThumbnailImage(
            thumbnailUrl: thumbnailUrl,
            fit: BoxFit.contain,
            placeholderBuilder: () => const ColoredBox(color: Colors.black),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
          ),
          child: const Center(
            child: Icon(
              Icons.videocam_off_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: IconButton(
          tooltip: 'Retry',
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: onRetry,
        ),
      ),
    );
  }
}

class _BlankTile extends StatelessWidget {
  const _BlankTile();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: const ColoredBox(color: Colors.white10),
    );
  }
}
