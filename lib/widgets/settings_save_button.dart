import 'package:flutter/material.dart';

/// AppBar Save action for camera-settings sub-screens: disabled until dirty
/// or while a save is already in flight (loading feedback is shown via a
/// full-screen [SavingOverlay] on the screen, not on this button).
class SettingsSaveButton extends StatelessWidget {
  const SettingsSaveButton({
    super.key,
    required this.settingsKey,
    required this.isDirty,
    required this.isSaving,
    required this.onPressed,
  });

  final Key settingsKey;
  final bool isDirty;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: settingsKey,
      onPressed: (isDirty && !isSaving) ? onPressed : null,
      child: const Text('Save'),
    );
  }
}

/// Simulated camera round-trip for a settings save: always succeeds after a
/// short delay. No backend/protocol wired up yet (see CLAUDE.md) — the
/// bool return keeps a failure path exercisable once one is.
Future<bool> simulateCameraSave() async {
  await Future<void>.delayed(const Duration(milliseconds: 800));
  return true;
}
