import 'dart:io';

import 'package:flutter/material.dart';

/// Renders [thumbnailUrl] as either a network image (`http(s)://` — the
/// `picsum.photos` placeholder seeded per camera in `HomesController`) or a
/// local file image (a real camera snapshot written to disk by
/// `syncCameraFromDevice`), so every thumbnail call site doesn't need to
/// know which kind it currently has.
class CameraThumbnailImage extends StatelessWidget {
  const CameraThumbnailImage({
    super.key,
    required this.thumbnailUrl,
    required this.fit,
    required this.placeholderBuilder,
  });

  final String thumbnailUrl;
  final BoxFit fit;
  final Widget Function() placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl.startsWith('http://') ||
        thumbnailUrl.startsWith('https://')) {
      return Image.network(
        thumbnailUrl,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholderBuilder();
        },
        errorBuilder: (context, error, stackTrace) => placeholderBuilder(),
      );
    }
    return Image.file(
      File(thumbnailUrl),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => placeholderBuilder(),
    );
  }
}
