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
  });

  final Key settingsKey;
  final Camera camera;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _CameraPreviewImage(settingsKey: settingsKey, camera: camera),
        ),
      ),
    );
  }
}

class _CameraPreviewImage extends StatelessWidget {
  const _CameraPreviewImage({required this.settingsKey, required this.camera});

  final Key settingsKey;
  final Camera camera;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumbnailUrl = camera.thumbnailUrl;

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
