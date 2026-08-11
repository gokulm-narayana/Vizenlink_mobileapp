import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/camera_preview_thumbnail.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/mode_tile.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/refresh_preview_button.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

/// Night Mode: preview thumbnail plus Infrared/Smart/Full Color selection.
/// Persisted through [HomesController] (see `updateCamera`) so it survives
/// leaving and re-entering the screen — see the note on `videoMode` in
/// `lib/models/camera.dart`.
class NightModeScreen extends StatefulWidget {
  const NightModeScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'night-mode';

  final Camera camera;
  final HomesController homesController;

  @override
  State<NightModeScreen> createState() => _NightModeScreenState();
}

class _NightModeScreenState extends State<NightModeScreen> {
  late CameraNightMode _mode = widget.camera.nightMode;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  void _onModeChanged(CameraNightMode? value) {
    if (value == null) return;
    setState(() {
      _mode = value;
      _isDirty = true;
    });
  }

  Future<void> _refreshPreview() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _previewReloadKey++;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(nightMode: _mode),
      );
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes. Try again.')),
      );
    }
  }

  Future<bool> _confirmLeave() => confirmDiscardOnLeave(
    context: context,
    isDirty: _isDirty,
    onSave: _save,
    isDirtyAfterSave: () => _isDirty,
    dialogKey: const Key('NIGHT-008'),
    discardKey: const Key('NIGHT-009'),
    saveKey: const Key('NIGHT-010'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('NIGHT-001'),
            title: const Text('Night Mode'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('NIGHT-004'),
                isDirty: _isDirty,
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
          body: SavingOverlay(
            isSaving: _isSaving,
            child: FixedPreviewLayout(
              preview: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CameraPreviewThumbnail(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('NIGHT-005'),
                    camera: widget.camera,
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('NIGHT-007'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                Row(
                  key: const Key('NIGHT-006'),
                  children: [
                    Expanded(
                      child: ModeTile(
                        icon: Icons.nightlight,
                        label: 'Infrared',
                        selected: _mode == CameraNightMode.infrared,
                        onTap: () => _onModeChanged(CameraNightMode.infrared),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.auto_awesome,
                        label: 'Smart',
                        selected: _mode == CameraNightMode.smart,
                        onTap: () => _onModeChanged(CameraNightMode.smart),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.palette,
                        label: 'Full Color',
                        selected: _mode == CameraNightMode.fullColor,
                        onTap: () => _onModeChanged(CameraNightMode.fullColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
