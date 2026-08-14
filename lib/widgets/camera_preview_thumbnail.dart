import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../theme/app_colors.dart';
import 'camera_thumbnail_image.dart';
import 'glass_card.dart';

/// 16:9 camera snapshot preview, glass-carded and rounded. Used at the top
/// of camera-setting sub-screens (video mode, night mode, etc.) that need a
/// quick visual reference for the camera being configured.
class CameraPreviewThumbnail extends StatelessWidget {
  const CameraPreviewThumbnail({
    super.key,
    required this.settingsKey,
    required this.camera,
    this.overrideBytes,
  });

  final Key settingsKey;
  final Camera camera;

  /// A transient, un-persisted frame (e.g. a decrypted WAN preview snapshot
  /// — see `camera_sync.dart`'s `fetchWanPreviewSnapshot` doc for why this
  /// must never be written to `Camera.thumbnailUrl`/disk) to show instead
  /// of [camera]'s normal cached thumbnail, for as long as the caller holds
  /// onto it in local widget state. Null shows the normal cached thumbnail.
  final Uint8List? overrideBytes;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _CameraPreviewImage(
            settingsKey: settingsKey,
            camera: camera,
            overrideBytes: overrideBytes,
          ),
        ),
      ),
    );
  }
}

class _CameraPreviewImage extends StatelessWidget {
  const _CameraPreviewImage({
    required this.settingsKey,
    required this.camera,
    this.overrideBytes,
  });

  final Key settingsKey;
  final Camera camera;
  final Uint8List? overrideBytes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bytes = overrideBytes;
    final thumbnailUrl = camera.thumbnailUrl;

    if (bytes != null) {
      return KeyedSubtree(
        key: settingsKey,
        child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }

    if (thumbnailUrl == null) {
      return KeyedSubtree(
        key: settingsKey,
        child: _placeholder(colorScheme, isDark),
      );
    }

    return KeyedSubtree(
      key: settingsKey,
      child: CameraThumbnailImage(
        thumbnailUrl: thumbnailUrl,
        fit: BoxFit.cover,
        placeholderBuilder: () => _placeholder(colorScheme, isDark),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme, bool isDark) {
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
          size: 40,
        ),
      ),
    );
  }
}
