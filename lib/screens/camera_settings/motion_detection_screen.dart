import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/camera_preview_thumbnail.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/refresh_preview_button.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

/// Motion Detection: preview (reference only) plus an enable toggle and a
/// sensitivity slider. Persisted through [HomesController] (see
/// `updateCamera`) — see the note on `videoMode` in `lib/models/camera.dart`.
class MotionDetectionScreen extends StatefulWidget {
  const MotionDetectionScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'motion-detection';

  final Camera camera;
  final HomesController homesController;

  @override
  State<MotionDetectionScreen> createState() => _MotionDetectionScreenState();
}

class _MotionDetectionScreenState extends State<MotionDetectionScreen> {
  late bool _enabled = widget.camera.motionDetectionEnabled;
  late double _sensitivity = widget.camera.motionSensitivity;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
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
        (camera) => camera.copyWith(
          motionDetectionEnabled: _enabled,
          motionSensitivity: _sensitivity,
        ),
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
    dialogKey: const Key('MOTION-008'),
    discardKey: const Key('MOTION-009'),
    saveKey: const Key('MOTION-010'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('MOTION-001'),
            title: const Text('Motion Detection'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('MOTION-002'),
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
                    settingsKey: const Key('MOTION-005'),
                    camera: widget.camera,
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('MOTION-007'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: const Key('MOTION-003'),
                    title: const Text('Motion detection'),
                    value: _enabled,
                    onChanged: (value) => _markDirty(() => _enabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sensitivity (${_sensitivity.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('MOTION-004'),
                        value: _sensitivity,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: _enabled
                            ? (value) => _markDirty(() => _sensitivity = value)
                            : null,
                      ),
                    ],
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
