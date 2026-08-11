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

/// Video Mode: preview thumbnail plus Day/Auto/Night selection. Persisted
/// through [HomesController] (see `updateCamera`) so it survives leaving and
/// re-entering the screen, and so a future real CCTV stream can read it
/// directly — it has no visible effect on the dummy preview video yet (see
/// CLAUDE.md).
class VideoModeScreen extends StatefulWidget {
  const VideoModeScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'video-mode';

  final Camera camera;
  final HomesController homesController;

  @override
  State<VideoModeScreen> createState() => _VideoModeScreenState();
}

class _VideoModeScreenState extends State<VideoModeScreen> {
  late CameraVideoMode _mode = widget.camera.videoMode;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  void _onModeChanged(CameraVideoMode? value) {
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
        (camera) => camera.copyWith(videoMode: _mode),
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
    dialogKey: const Key('VIDMODE-008'),
    discardKey: const Key('VIDMODE-009'),
    saveKey: const Key('VIDMODE-010'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('VIDMODE-001'),
            title: const Text('Video Mode'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('VIDMODE-005'),
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
                    settingsKey: const Key('VIDMODE-003'),
                    camera: widget.camera,
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('VIDMODE-007'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                Row(
                  key: const Key('VIDMODE-004'),
                  children: [
                    Expanded(
                      child: ModeTile(
                        icon: Icons.wb_sunny,
                        label: 'Day',
                        selected: _mode == CameraVideoMode.day,
                        onTap: () => _onModeChanged(CameraVideoMode.day),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.brightness_auto,
                        label: 'Auto',
                        selected: _mode == CameraVideoMode.auto,
                        onTap: () => _onModeChanged(CameraVideoMode.auto),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.nightlight_round,
                        label: 'Night',
                        selected: _mode == CameraVideoMode.night,
                        onTap: () => _onModeChanged(CameraVideoMode.night),
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
