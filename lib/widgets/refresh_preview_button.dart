import 'package:flutter/material.dart';

/// Right-aligned "Refresh preview" text button with a spinner while
/// refreshing. Used below a [CameraPreviewThumbnail] on camera-settings
/// sub-screens so the preview can be reloaded without leaving the screen.
class RefreshPreviewButton extends StatelessWidget {
  const RefreshPreviewButton({
    super.key,
    required this.settingsKey,
    required this.isRefreshing,
    required this.onPressed,
  });

  final Key settingsKey;
  final bool isRefreshing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        key: settingsKey,
        onPressed: isRefreshing ? null : onPressed,
        icon: isRefreshing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 18),
        label: const Text('Refresh preview'),
      ),
    );
  }
}
