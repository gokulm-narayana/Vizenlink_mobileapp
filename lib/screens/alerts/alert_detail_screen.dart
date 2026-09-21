import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_state/alerts_controller.dart';
import '../../app_state/homes_controller.dart';
import '../../models/alert.dart';
import '../../models/alert_type_display.dart';
import '../../models/camera.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../camera_live/camera_live_screen.dart';
import '../dashboard/dashboard_screen.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.alert,
    required this.alertsController,
    required this.homesController,
  });

  static const routeName = 'detail';

  final Alert alert;
  final AlertsController alertsController;
  final HomesController homesController;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  bool _isDownloadingSnapshot = false;
  bool _isSharing = false;

  Alert get alert => widget.alert;

  void _viewLive() {
    Camera? camera;
    for (final home in widget.homesController.value.homes) {
      for (final candidate in home.cameras) {
        if (candidate.id == alert.cameraId) {
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

  String _formattedTimestamp() {
    final t = alert.timestamp;
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${t.month}/${t.day}/${t.year} at $hour:$minute $period';
  }

  Future<Uint8List> _fetchSnapshotBytes() async {
    if (alert.snapshotUrl == null) {
      throw Exception('No snapshot available');
    }
    final request = await HttpClient().getUrl(Uri.parse(alert.snapshotUrl!));
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
      final bytes = await _fetchSnapshotBytes();
      await Gal.putImageBytes(bytes, name: 'cctv_alert_snapshot_${alert.id}');
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

  Future<void> _shareSnapshot() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final bytes = await _fetchSnapshotBytes();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cctv_alert_share_${alert.id}.jpg');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${alert.type.label} — ${alert.cameraName}',
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
        title: const Text('Delete notification?'),
        content: const Text('This notification will be permanently removed.'),
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
    widget.alertsController.deleteAlert(alert.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSnoozed = widget.alertsController.isCameraSnoozed(alert.cameraId);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('ALERTDET-001'),
          title: Text(alert.type.label),
          leading: BackButton(key: const Key('ALERTDET-002')),
          actions: [
            IconButton(
              key: const Key('ALERTDET-015'),
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
              key: const Key('ALERTDET-010'),
              tooltip: alert.isRead ? 'Mark as unread' : 'Mark as read',
              icon: Icon(
                alert.isRead
                    ? Icons.mark_email_read_outlined
                    : Icons.mark_email_unread_outlined,
              ),
              onPressed: () => alert.isRead
                  ? widget.alertsController.markUnread(alert.id)
                  : widget.alertsController.markRead(alert.id),
            ),
            IconButton(
              key: const Key('ALERTDET-014'),
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
                key: const Key('ALERTDET-003'),
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _MediaView(
                      alert: alert,
                      colorScheme: colorScheme,
                      isDark: isDark,
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
                            key: const Key('ALERTDET-004'),
                            alert.cameraName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Chip(
                          key: const Key('ALERTDET-005'),
                          label: Text(alert.type.label),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      key: const Key('ALERTDET-006'),
                      _formattedTimestamp(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      key: const Key('ALERTDET-007'),
                      alert.description ?? alert.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('ALERTDET-008'),
                  onPressed: _viewLive,
                  icon: const Icon(Icons.videocam_rounded),
                  label: const Text('View live'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('ALERTDET-012'),
                  onPressed: _isDownloadingSnapshot ? null : _downloadSnapshot,
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('ALERTDET-017'),
                  onPressed: () => widget.alertsController.toggleCameraSnooze(
                    alert.cameraId,
                  ),
                  icon: Icon(
                    isSnoozed
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_active_outlined,
                  ),
                  label: Text(
                    isSnoozed
                        ? 'Alerts snoozed for ${alert.cameraName}'
                        : 'Snooze alerts for ${alert.cameraName}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                key: const Key('ALERTDET-018'),
                'Unread notifications — ${alert.cameraName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder(
                valueListenable: widget.alertsController,
                builder: (context, alerts, _) {
                  final related =
                      alerts
                          .where(
                            (a) =>
                                a.cameraId == alert.cameraId &&
                                a.id != alert.id &&
                                a.type == AlertType.motion &&
                                !a.isRead,
                          )
                          .toList()
                        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  if (related.isEmpty) {
                    return Text(
                      'No unread notifications from this camera',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }

                  return SizedBox(
                    key: const Key('ALERTDET-019'),
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: related.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final related_ = related[index];
                        return _RelatedAlertCard(
                          key: Key('ALERTDET-019-${related_.id}'),
                          alert: related_,
                          onTap: () => context.go(
                            '/alerts',
                            extra: (related_.cameraName, related_.type, true),
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

/// Snapshot-only media view — no video, real or fake. There's no real
/// alert-clip API yet, so this used to fall back to playing a bundled dummy
/// video asset in place of "the recording"; removed entirely 2026-09-07 per
/// direct user request ("remove the dummy video in the app completely")
/// rather than keep showing fake footage. Add real inline clip playback back
/// here once a real per-alert clip URL exists.
class _MediaView extends StatelessWidget {
  const _MediaView({
    required this.alert,
    required this.colorScheme,
    required this.isDark,
  });

  final Alert alert;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return alert.snapshotUrl == null
        ? _snapshotPlaceholder()
        : Image.network(
            alert.snapshotUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _snapshotPlaceholder(),
          );
  }

  Widget _snapshotPlaceholder() {
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
        child: Icon(alert.type.icon, color: colorScheme.primary, size: 48),
      ),
    );
  }
}

class _RelatedAlertCard extends StatelessWidget {
  const _RelatedAlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  final Alert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: alert.isRead
              ? null
              : Border.all(color: AppColors.cyan, width: 1.5),
        ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(alert.type.icon, color: colorScheme.primary, size: 20),
                    if (!alert.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: alert.isRead
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
