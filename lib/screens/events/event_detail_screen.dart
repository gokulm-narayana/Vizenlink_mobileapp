import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../app_state/events_controller.dart';
import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../models/event.dart';
import '../../models/event_type_display.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../camera_live/camera_live_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Placeholder sample stream used until a real CCTV protocol (RTSP/ONVIF/
/// HLS) is chosen — see CLAUDE.md. Same asset the Alerts/camera-live
/// screens use for their dummy playback.
const _dummyVideoAsset = 'assets/videos/camera_dummy.mp4';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.event,
    required this.eventsController,
    required this.homesController,
  });

  static const routeName = 'detail';

  final RecordedEvent event;
  final EventsController eventsController;
  final HomesController homesController;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isDownloadingSnapshot = false;
  bool _isDownloadingClip = false;
  bool _isSharing = false;

  RecordedEvent get event => widget.event;

  void _viewLive() {
    Camera? camera;
    for (final home in widget.homesController.value.homes) {
      for (final candidate in home.cameras) {
        if (candidate.id == event.cameraId) {
          camera = candidate;
          break;
        }
      }
    }
    if (camera == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Camera unreachable')));
      return;
    }
    context.go(
      '${DashboardScreen.routeName}/${CameraLiveScreen.routeName}/${camera.id}',
      extra: camera,
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _startPlayback() async {
    if (_videoController != null) {
      setState(() => _isPlaying = true);
      await _videoController!.play();
      return;
    }

    final controller = VideoPlayerController.asset(_dummyVideoAsset);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _videoController = controller;
      _isPlaying = true;
    });
    await controller.play();
  }

  Future<void> _openFullscreen() async {
    final controller = _videoController;
    if (controller == null) return;
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
        builder: (_) => _FullscreenVideo(controller: controller),
      ),
    );
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  String _formattedTimestamp() {
    final t = event.timestamp;
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${t.month}/${t.day}/${t.year} at $hour:$minute $period';
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<Uint8List> _fetchThumbnailBytes() async {
    if (event.thumbnailUrl == null) {
      throw Exception('No thumbnail available');
    }
    final request = await HttpClient().getUrl(Uri.parse(event.thumbnailUrl!));
    final response = await request.close();
    return Uint8List.fromList(
      await response.fold<List<int>>(
        <int>[],
        (previous, chunk) => previous..addAll(chunk),
      ),
    );
  }

  Future<void> _downloadSnapshot() async {
    if (_isDownloadingSnapshot) return;
    setState(() => _isDownloadingSnapshot = true);
    try {
      final bytes = await _fetchThumbnailBytes();
      await Gal.putImageBytes(bytes, name: 'cctv_event_snapshot_${event.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Snapshot saved')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save snapshot')));
    } finally {
      if (mounted) setState(() => _isDownloadingSnapshot = false);
    }
  }

  Future<void> _downloadClip() async {
    if (_isDownloadingClip) return;
    setState(() => _isDownloadingClip = true);
    try {
      final bytes = await rootBundle.load(_dummyVideoAsset);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/cctv_event_clip_${event.id}_'
        '${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Gal.putVideo(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clip saved')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save clip')));
    } finally {
      if (mounted) setState(() => _isDownloadingClip = false);
    }
  }

  Future<void> _shareSnapshot() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final bytes = await _fetchThumbnailBytes();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cctv_event_share_${event.id}.jpg');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${event.type.label} — ${event.cameraName}',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not share snapshot')));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text('This recorded event will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    widget.eventsController.deleteEvent(event.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('EVTDET-001'),
          title: Text(event.type.label),
          leading: BackButton(key: const Key('EVTDET-002')),
          actions: [
            IconButton(
              key: const Key('EVTDET-013'),
              tooltip: 'Share snapshot',
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              onPressed: _isSharing ? null : _shareSnapshot,
            ),
            IconButton(
              key: const Key('EVTDET-014'),
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                key: const Key('EVTDET-003'),
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _MediaView(
                      event: event,
                      videoController: _videoController,
                      isPlaying: _isPlaying,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      onPlayTap: _startPlayback,
                      onFullscreenTap: _openFullscreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            key: const Key('EVTDET-005'),
                            event.cameraName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Chip(
                          key: const Key('EVTDET-006'),
                          avatar: Icon(event.type.icon, size: 18),
                          label: Text(event.type.label),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      key: const Key('EVTDET-007'),
                      _formattedTimestamp(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      key: const Key('EVTDET-008'),
                      'Duration: ${_formatDuration(event.duration)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('EVTDET-010'),
                  onPressed: _viewLive,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('View live'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('EVTDET-012'),
                      onPressed: event.thumbnailUrl == null
                          ? null
                          : (_isDownloadingSnapshot ? null : _downloadSnapshot),
                      icon: _isDownloadingSnapshot
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_back_outlined),
                      label: const Text('Download snapshot'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('EVTDET-011'),
                      onPressed: _isDownloadingClip ? null : _downloadClip,
                      icon: _isDownloadingClip
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: const Text('Download clip'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                key: const Key('EVTDET-015'),
                'More from ${event.cameraName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder(
                valueListenable: widget.eventsController,
                builder: (context, events, _) {
                  final related =
                      events
                          .where(
                            (e) =>
                                e.cameraId == event.cameraId &&
                                e.id != event.id,
                          )
                          .toList()
                        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  if (related.isEmpty) {
                    return Text(
                      'No other events from this camera',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }

                  return SizedBox(
                    key: const Key('EVTDET-015-list'),
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: related.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final relatedEvent = related[index];
                        return _RelatedEventCard(
                          key: Key('EVTDET-015-${relatedEvent.id}'),
                          event: relatedEvent,
                          onTap: () => context.pushReplacement(
                            '/events/${EventDetailScreen.routeName}',
                            extra: relatedEvent,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaView extends StatelessWidget {
  const _MediaView({
    required this.event,
    required this.videoController,
    required this.isPlaying,
    required this.colorScheme,
    required this.isDark,
    required this.onPlayTap,
    required this.onFullscreenTap,
  });

  final RecordedEvent event;
  final VideoPlayerController? videoController;
  final bool isPlaying;
  final ColorScheme colorScheme;
  final bool isDark;
  final VoidCallback onPlayTap;
  final VoidCallback onFullscreenTap;

  @override
  Widget build(BuildContext context) {
    final controller = videoController;
    if (isPlaying && controller != null && controller.value.isInitialized) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: InteractiveViewer(
              maxScale: 4,
              child: VideoPlayer(controller),
            ),
          ),
          IconButton(
            key: const Key('EVTDET-009'),
            tooltip: 'Fullscreen',
            icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
            onPressed: onFullscreenTap,
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: event.thumbnailUrl == null
              ? _thumbnailPlaceholder()
              : Image.network(
                  event.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _thumbnailPlaceholder(),
                ),
        ),
        IconButton(
          key: const Key('EVTDET-004'),
          iconSize: 56,
          color: Colors.white,
          icon: const Icon(Icons.play_circle_fill_rounded),
          onPressed: onPlayTap,
        ),
      ],
    );
  }

  Widget _thumbnailPlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.4),
                  AppColors.cyan.withValues(alpha: 0.18),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.22),
                  AppColors.cyan.withValues(alpha: 0.12),
                ],
        ),
      ),
      child: Center(
        child: Icon(event.type.icon, color: colorScheme.primary, size: 48),
      ),
    );
  }
}

class _RelatedEventCard extends StatelessWidget {
  const _RelatedEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final RecordedEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderRadius: 14,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(event.type.icon, color: colorScheme.primary, size: 20),
              const SizedBox(height: 6),
              Text(
                event.type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideo extends StatelessWidget {
  const _FullscreenVideo({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: InteractiveViewer(
                  maxScale: 4,
                  child: VideoPlayer(controller),
                ),
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
