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

const _defaultBrightness = 50.0;
const _defaultContrast = 50.0;
const _defaultSaturation = 50.0;
const _defaultSharpness = 50.0;
const _defaultMirrorFlip = CameraMirrorFlip.off;
const _defaultWdrEnabled = false;
const _defaultWdrLevel = 50.0;
const _defaultWhiteBalance = CameraAutoManual.auto;
const _defaultExposure = CameraAutoManual.auto;

/// Imaging: preview, mirror/flip, brightness/contrast/saturation/sharpness,
/// white balance, and exposure. Persisted through [HomesController] (see
/// `updateCamera`) — see the note on `videoMode` in `lib/models/camera.dart`.
/// "Reset to Default" resets to this screen's hardcoded factory defaults,
/// not to whatever was last saved.
class ImagingScreen extends StatefulWidget {
  const ImagingScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'imaging';

  final Camera camera;
  final HomesController homesController;

  @override
  State<ImagingScreen> createState() => _ImagingScreenState();
}

class _ImagingScreenState extends State<ImagingScreen> {
  late CameraMirrorFlip _mirrorFlip = widget.camera.mirrorFlip;
  late double _brightness = widget.camera.brightness;
  late double _contrast = widget.camera.contrast;
  late double _saturation = widget.camera.saturation;
  late double _sharpness = widget.camera.sharpness;
  late bool _wdrEnabled = widget.camera.wdrEnabled;
  late double _wdrLevel = widget.camera.wdrLevel;
  late CameraAutoManual _whiteBalance = widget.camera.whiteBalance;
  late CameraAutoManual _exposure = widget.camera.exposure;
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
          mirrorFlip: _mirrorFlip,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          sharpness: _sharpness,
          wdrEnabled: _wdrEnabled,
          wdrLevel: _wdrLevel,
          whiteBalance: _whiteBalance,
          exposure: _exposure,
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

  void _resetToDefault() {
    _markDirty(() {
      _mirrorFlip = _defaultMirrorFlip;
      _brightness = _defaultBrightness;
      _contrast = _defaultContrast;
      _saturation = _defaultSaturation;
      _sharpness = _defaultSharpness;
      _wdrEnabled = _defaultWdrEnabled;
      _wdrLevel = _defaultWdrLevel;
      _whiteBalance = _defaultWhiteBalance;
      _exposure = _defaultExposure;
    });
  }

  Future<bool> _confirmLeave() => confirmDiscardOnLeave(
    context: context,
    isDirty: _isDirty,
    onSave: _save,
    isDirtyAfterSave: () => _isDirty,
    dialogKey: const Key('IMG-015'),
    discardKey: const Key('IMG-016'),
    saveKey: const Key('IMG-017'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('IMG-001'),
            title: const Text('Imaging'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('IMG-002'),
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
                    settingsKey: const Key('IMG-003'),
                    camera: widget.camera,
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('IMG-014'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    key: const Key('IMG-011'),
                    onPressed: _resetToDefault,
                    child: const Text('Reset to Default'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mirror / Flip',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<CameraMirrorFlip>(
                  key: const Key('IMG-004'),
                  segments: const [
                    ButtonSegment(
                      value: CameraMirrorFlip.off,
                      label: Text('Off'),
                    ),
                    ButtonSegment(
                      value: CameraMirrorFlip.mirror,
                      label: Text('Mirror'),
                    ),
                    ButtonSegment(
                      value: CameraMirrorFlip.flip,
                      label: Text('Flip'),
                    ),
                    ButtonSegment(
                      value: CameraMirrorFlip.both,
                      label: Text('Both'),
                    ),
                  ],
                  selected: {_mirrorFlip},
                  onSelectionChanged: (selection) =>
                      _markDirty(() => _mirrorFlip = selection.first),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SliderRow(
                        settingsKey: const Key('IMG-005'),
                        label: 'Brightness',
                        value: _brightness,
                        onChanged: (value) =>
                            _markDirty(() => _brightness = value),
                      ),
                      _SliderRow(
                        settingsKey: const Key('IMG-006'),
                        label: 'Contrast',
                        value: _contrast,
                        onChanged: (value) =>
                            _markDirty(() => _contrast = value),
                      ),
                      _SliderRow(
                        settingsKey: const Key('IMG-007'),
                        label: 'Saturation',
                        value: _saturation,
                        onChanged: (value) =>
                            _markDirty(() => _saturation = value),
                      ),
                      _SliderRow(
                        settingsKey: const Key('IMG-008'),
                        label: 'Sharpness',
                        value: _sharpness,
                        onChanged: (value) =>
                            _markDirty(() => _sharpness = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: const Key('IMG-012'),
                    title: const Text('WDR'),
                    value: _wdrEnabled,
                    onChanged: (value) => _markDirty(() => _wdrEnabled = value),
                  ),
                ),
                if (_wdrEnabled) ...[
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SliderRow(
                          settingsKey: const Key('IMG-013'),
                          label: 'WDR level',
                          value: _wdrLevel,
                          min: 1,
                          onChanged: (value) =>
                              _markDirty(() => _wdrLevel = value),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'White balance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<CameraAutoManual>(
                  key: const Key('IMG-009'),
                  segments: const [
                    ButtonSegment(
                      value: CameraAutoManual.auto,
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: CameraAutoManual.manual,
                      label: Text('Manual'),
                    ),
                  ],
                  selected: {_whiteBalance},
                  onSelectionChanged: (selection) =>
                      _markDirty(() => _whiteBalance = selection.first),
                ),
                const SizedBox(height: 16),
                Text('Exposure', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<CameraAutoManual>(
                  key: const Key('IMG-010'),
                  segments: const [
                    ButtonSegment(
                      value: CameraAutoManual.auto,
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: CameraAutoManual.manual,
                      label: Text('Manual'),
                    ),
                  ],
                  selected: {_exposure},
                  onSelectionChanged: (selection) =>
                      _markDirty(() => _exposure = selection.first),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.settingsKey,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final Key settingsKey;
  final String label;
  final double value;
  final double min;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$label (${value.round()})',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          key: settingsKey,
          value: value,
          min: min,
          max: 100,
          divisions: (100 - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
