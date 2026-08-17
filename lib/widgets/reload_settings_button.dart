import 'package:flutter/material.dart';

/// AppBar "Reload settings" action for camera-settings sub-screens: re-fetches
/// this screen's fields from the camera (distinct from [SettingsSaveButton],
/// which pushes local edits, and from `RefreshPreviewButton`, which only
/// refetches the preview image). Disabled while a load or save is already in
/// flight — the loading feedback itself is shown via the screen's full-screen
/// `SavingOverlay`, not on this button.
class ReloadSettingsButton extends StatelessWidget {
  const ReloadSettingsButton({
    super.key,
    required this.settingsKey,
    required this.isBusy,
    required this.onPressed,
  });

  final Key settingsKey;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: settingsKey,
      tooltip: 'Reload settings',
      onPressed: isBusy ? null : onPressed,
      icon: const Icon(Icons.refresh),
    );
  }
}
