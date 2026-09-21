import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../theme/app_colors.dart';
import 'camera_thumbnail_image.dart';
import 'glass_card.dart';

Widget _thumbnailPlaceholder(
  ColorScheme colorScheme,
  bool isDark, {
  double iconSize = 40,
}) {
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
      child: Icon(
        Icons.videocam_rounded,
        color: colorScheme.primary,
        size: iconSize,
      ),
    ),
  );
}

/// Short relative-time label for a past [DateTime], e.g. "2h ago".
String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String _offlineLabel(Camera camera) => camera.lastSeen != null
    ? 'Camera Offline · Last seen ${_relativeTime(camera.lastSeen!)}'
    : 'Camera Offline';

/// Full overlay for the full-width grid tile: icon + "Camera Offline" +
/// "Last seen …" stacked in the center of the thumbnail.
Widget _offlineOverlay(Camera camera) {
  return Positioned.fill(
    child: DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55)),
      child: Center(
        child: Column(
          key: Key('DASH-006-offline-${camera.id}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 6),
            const Text(
              'Camera Offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            if (camera.lastSeen != null)
              Text(
                'Last seen ${_relativeTime(camera.lastSeen!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Compact overlay for the small list-row thumbnail: just the offline icon,
/// with the full "Camera Offline · Last seen …" detail as a tooltip since
/// there isn't room to render the text without overflowing the 56x56 box.
Widget _offlineOverlayCompact(Camera camera) {
  return Positioned.fill(
    key: Key('DASH-006-offline-${camera.id}'),
    child: Tooltip(
      message: _offlineLabel(camera),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55)),
        child: const Center(
          child: Icon(
            Icons.videocam_off_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    ),
  );
}

/// Small numbered badge showing a camera's unread alert count, e.g. "3". A
/// themed border ring keeps it legible against any thumbnail. Caps the
/// displayed label at "9+" so it never grows the badge past a single-digit
/// width.
Widget _unreadAlertBadge(
  BuildContext context,
  int count, {
  required Key badgeKey,
}) {
  final label = count > 9 ? '9+' : '$count';
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    key: badgeKey,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: isDark ? AppColors.darkMid : Colors.white,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        fontSize: 11,
        color: Colors.white,
        height: 1,
      ),
    ),
  );
}

Widget _statusDot(Color statusColor, {double size = 8}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: statusColor,
      boxShadow: [
        BoxShadow(
          color: statusColor.withValues(alpha: 0.7),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ],
    ),
  );
}

/// Bottom sheet of actions for a camera tile, opened via long-press:
/// Rearrange (enters the Dashboard's reorder mode), Favourite/Unfavourite,
/// Pin/Unpin (All tab only), and Delete (with a confirm dialog). The calling
/// tile highlights itself with a primary-color border for as long as this
/// sheet is open.
Future<void> showCameraActionsMenu(
  BuildContext context, {
  required Camera camera,
  required bool showPinAction,
  required VoidCallback onRearrange,
  required VoidCallback onToggleFavorite,
  required VoidCallback onTogglePin,
  required VoidCallback onDelete,
}) async {
  final colorScheme = Theme.of(context).colorScheme;

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            borderRadius: 20,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      camera.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ListTile(
                    key: const Key('DASH-016-rearrange'),
                    leading: Icon(
                      Icons.drag_indicator,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Rearrange cameras'),
                    onTap: () => Navigator.of(sheetContext).pop('rearrange'),
                  ),
                  ListTile(
                    key: const Key('DASH-016-favorite'),
                    leading: Icon(
                      camera.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: camera.isFavorite
                          ? Colors.amber
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      camera.isFavorite
                          ? 'Remove from favourites'
                          : 'Add to favourites',
                    ),
                    onTap: () => Navigator.of(sheetContext).pop('favorite'),
                  ),
                  if (showPinAction)
                    ListTile(
                      key: const Key('DASH-016-pin'),
                      leading: Icon(
                        camera.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        color: camera.isPinned
                            ? Colors.amber
                            : colorScheme.onSurfaceVariant,
                      ),
                      title: Text(camera.isPinned ? 'Unpin' : 'Pin to top'),
                      onTap: () => Navigator.of(sheetContext).pop('pin'),
                    ),
                  ListTile(
                    key: const Key('DASH-016-delete'),
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppColors.offline,
                    ),
                    title: Text(
                      'Delete camera',
                      style: TextStyle(color: AppColors.offline),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop('delete'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  switch (action) {
    case 'rearrange':
      onRearrange();
    case 'favorite':
      onToggleFavorite();
    case 'pin':
      onTogglePin();
    case 'delete':
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete camera?'),
          content: Text(
            '"${camera.name}" will be removed from this home. '
            'This cannot be undone.',
          ),
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
      if (confirmed == true) onDelete();
  }
}

/// Full-width grid card: thumbnail fills the card, name/status overlaid on
/// top of the image. Long-press opens [showCameraActionsMenu]; a small
/// drag handle in the corner triggers [ReorderableListView] reordering.
class CameraTile extends StatefulWidget {
  const CameraTile({
    super.key,
    required this.camera,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onRearrange,
    this.unreadAlertCount = 0,
    this.showPinToggle = false,
    this.onTogglePin,
    this.isReorderMode = false,
    this.onTap,
  });

  final Camera camera;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  /// Enters the Dashboard's reorder mode (called from the DASH-016
  /// "Rearrange cameras" menu item).
  final VoidCallback onRearrange;
  final int unreadAlertCount;

  /// Pinning is only offered on the Dashboard's "All" tab.
  final bool showPinToggle;
  final VoidCallback? onTogglePin;

  /// While true, tap/long-press are disabled here so the whole tile is free
  /// for [ReorderableListView]'s default long-press-to-drag gesture instead.
  final bool isReorderMode;
  final VoidCallback? onTap;

  @override
  State<CameraTile> createState() => _CameraTileState();
}

class _CameraTileState extends State<CameraTile> {
  bool _menuOpen = false;

  Future<void> _openMenu() async {
    setState(() => _menuOpen = true);
    await showCameraActionsMenu(
      context,
      camera: widget.camera,
      showPinAction: widget.showPinToggle,
      onRearrange: widget.onRearrange,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin ?? () {},
      onDelete: widget.onDelete,
    );
    if (mounted) setState(() => _menuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final camera = widget.camera;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = switch (camera.liveStatus) {
      CameraLiveStatus.online => AppColors.online,
      CameraLiveStatus.needsAttention => AppColors.attention,
      CameraLiveStatus.offline => AppColors.offline,
    };
    final thumbnailUrl = camera.thumbnailUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: _menuOpen
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: widget.isReorderMode ? null : widget.onTap,
              onLongPress: widget.isReorderMode ? null : _openMenu,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailUrl != null)
                    Hero(
                      tag: 'camera_hero_${camera.id}',
                      child: CameraThumbnailImage(
                        thumbnailUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholderBuilder: () =>
                            _thumbnailPlaceholder(colorScheme, isDark),
                      ),
                    )
                  else
                    Hero(
                      tag: 'camera_hero_${camera.id}',
                      child: _thumbnailPlaceholder(colorScheme, isDark),
                    ),
                  // Scrim so the overlaid text stays legible over any thumbnail.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black45],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Row(
                      children: [
                        _statusDot(statusColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            camera.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!camera.isOnline) _offlineOverlay(camera),
                  if (widget.unreadAlertCount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _unreadAlertBadge(
                        context,
                        widget.unreadAlertCount,
                        badgeKey: Key('DASH-014-${camera.id}'),
                      ),
                    ),
                  if (widget.isReorderMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.drag_indicator,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    )
                  else if (camera.needsAttention)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        key: Key('DASH-021-${camera.id}'),
                        color: AppColors.attention,
                        size: 20,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  if (camera.isPinned)
                    Positioned(
                      bottom: 10,
                      right: 12,
                      child: Icon(
                        Icons.push_pin,
                        color: Colors.amber,
                        size: 16,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
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

/// Compact list row: small square thumbnail on the left, name/status in the
/// middle. Long-press opens [showCameraActionsMenu]. Distinct layout from
/// CameraTile — not a resized version of the grid card.
class CameraListTile extends StatefulWidget {
  const CameraListTile({
    super.key,
    required this.camera,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onRearrange,
    this.unreadAlertCount = 0,
    this.showPinToggle = false,
    this.onTogglePin,
    this.isReorderMode = false,
    this.onTap,
  });

  final Camera camera;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  /// Enters the Dashboard's reorder mode (called from the DASH-016
  /// "Rearrange cameras" menu item).
  final VoidCallback onRearrange;
  final int unreadAlertCount;

  /// Pinning is only offered on the Dashboard's "All" tab.
  final bool showPinToggle;
  final VoidCallback? onTogglePin;

  /// While true, tap/long-press are disabled here so the whole tile is free
  /// for [ReorderableListView]'s default long-press-to-drag gesture instead.
  final bool isReorderMode;
  final VoidCallback? onTap;

  @override
  State<CameraListTile> createState() => _CameraListTileState();
}

class _CameraListTileState extends State<CameraListTile> {
  bool _menuOpen = false;

  Future<void> _openMenu() async {
    setState(() => _menuOpen = true);
    await showCameraActionsMenu(
      context,
      camera: widget.camera,
      showPinAction: widget.showPinToggle,
      onRearrange: widget.onRearrange,
      onToggleFavorite: widget.onToggleFavorite,
      onTogglePin: widget.onTogglePin ?? () {},
      onDelete: widget.onDelete,
    );
    if (mounted) setState(() => _menuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final camera = widget.camera;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = switch (camera.liveStatus) {
      CameraLiveStatus.online => AppColors.online,
      CameraLiveStatus.needsAttention => AppColors.attention,
      CameraLiveStatus.offline => AppColors.offline,
    };
    final thumbnailUrl = camera.thumbnailUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: _menuOpen
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          borderRadius: 16,
          child: GestureDetector(
            onTap: widget.isReorderMode ? null : widget.onTap,
            onLongPress: widget.isReorderMode ? null : _openMenu,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        thumbnailUrl != null
                            ? Hero(
                                tag: 'camera_hero_${camera.id}',
                                child: CameraThumbnailImage(
                                  thumbnailUrl: thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: () =>
                                      _thumbnailPlaceholder(
                                        colorScheme,
                                        isDark,
                                        iconSize: 22,
                                      ),
                                ),
                              )
                            : Hero(
                                tag: 'camera_hero_${camera.id}',
                                child: _thumbnailPlaceholder(
                                  colorScheme,
                                  isDark,
                                  iconSize: 22,
                                ),
                              ),
                        if (!camera.isOnline) _offlineOverlayCompact(camera),
                        if (widget.unreadAlertCount > 0)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: _unreadAlertBadge(
                              context,
                              widget.unreadAlertCount,
                              badgeKey: Key('DASH-014-${camera.id}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      _statusDot(statusColor),
                      const SizedBox(width: 8),
                      if (camera.needsAttention) ...[
                        Icon(
                          Icons.warning_amber_rounded,
                          key: Key('DASH-021-${camera.id}'),
                          color: AppColors.attention,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (camera.isPinned) ...[
                        Icon(Icons.push_pin, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          camera.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isReorderMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.drag_indicator,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
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
