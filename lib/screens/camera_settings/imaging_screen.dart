import 'dart:async';

import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';

import '../../app_state/camera_sync.dart';
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

/// `CameraMirrorFlip` <-> `MirrorFlipMode` — same 4 values, different enum
/// types (one app-side, one camera_api-side).
MirrorFlipMode _toWireMirrorFlip(CameraMirrorFlip mode) => switch (mode) {
  CameraMirrorFlip.off => MirrorFlipMode.off,
  CameraMirrorFlip.mirror => MirrorFlipMode.mirror,
  CameraMirrorFlip.flip => MirrorFlipMode.flip,
  CameraMirrorFlip.both => MirrorFlipMode.both,
};

CameraMirrorFlip _fromWireMirrorFlip(MirrorFlipMode mode) => switch (mode) {
  MirrorFlipMode.off => CameraMirrorFlip.off,
  MirrorFlipMode.mirror => CameraMirrorFlip.mirror,
  MirrorFlipMode.flip => CameraMirrorFlip.flip,
  MirrorFlipMode.both => CameraMirrorFlip.both,
};

/// `CameraAutoManual` <-> ONVIF `"AUTO"`/`"MANUAL"` wire values, shared by
/// both the white-balance and exposure mode fields.
String _autoManualToWire(CameraAutoManual mode) => switch (mode) {
  CameraAutoManual.auto => 'AUTO',
  CameraAutoManual.manual => 'MANUAL',
};

CameraAutoManual? _autoManualFromWire(String? wireValue) =>
    switch (wireValue?.toUpperCase()) {
      'AUTO' => CameraAutoManual.auto,
      'MANUAL' => CameraAutoManual.manual,
      _ => null,
    };

const _autoManualSegmentsByMode = {
  CameraAutoManual.auto: ButtonSegment(
    value: CameraAutoManual.auto,
    label: Text('Auto'),
  ),
  CameraAutoManual.manual: ButtonSegment(
    value: CameraAutoManual.manual,
    label: Text('Manual'),
  ),
};

/// Builds the Auto/Manual segments to actually show — only the modes the
/// camera's own Options response reports (never a hardcoded fixed set, per
/// `.claude/rules/mobile-app-screen-conventions.md`), always including
/// [current] defensively so `SegmentedButton`'s `selected` is never outside
/// its own `segments`. Shows both when [wireModes] is null (unverified — no
/// connection yet).
List<ButtonSegment<CameraAutoManual>> _autoManualSegments(
  List<String>? wireModes,
  CameraAutoManual current,
) {
  if (wireModes == null) return _autoManualSegmentsByMode.values.toList();
  final supported = wireModes
      .map(_autoManualFromWire)
      .whereType<CameraAutoManual>()
      .toSet();
  supported.add(current);
  return [
    for (final mode in CameraAutoManual.values)
      if (supported.contains(mode)) _autoManualSegmentsByMode[mode]!,
  ];
}

/// Imaging: preview, mirror/flip, brightness/contrast/saturation/sharpness,
/// WDR, white balance, and exposure. Backed by real `camera_api` when the
/// camera has a saved connection: `OnvifImagingClient` for everything except
/// mirror/flip, which is a separate NuraEye setting (`MirrorFlipClient`) —
/// both are loaded together on screen open and saved together on Save.
/// Falls back to local-only `HomesController` state (`simulateCameraSave`)
/// for a camera with no saved connection yet. Manual exposure's numeric
/// time/gain fields (`ImagingSettings.exposureTime`/`exposureGain`) have no
/// UI here yet — this screen only has an Auto/Manual toggle, not sliders for
/// them, matching the existing design; WAN fallback isn't wired up either.
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
  late CameraMirrorFlip _mirrorFlip = _camera.mirrorFlip;
  late double _brightness = _camera.brightness;
  late double _contrast = _camera.contrast;
  late double _saturation = _camera.saturation;
  late double _sharpness = _camera.sharpness;
  late bool _wdrEnabled = _camera.wdrEnabled;
  late double _wdrLevel = _camera.wdrLevel;
  late CameraAutoManual _whiteBalance = _camera.whiteBalance;
  late CameraAutoManual _exposure = _camera.exposure;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  /// Bounds/choice lists from the camera's own `getImagingOptions()` — null
  /// means "camera not verified yet", in which case every control shows
  /// (same fallback reasoning as `_dummyTimezones` in camera_info_screen).
  ImagingOptions? _imagingOptions;

  @override
  void initState() {
    super.initState();
    _loadRealImaging();
  }

  Future<void> _loadRealImaging() async {
    final connection = _camera.connection;
    if (connection == null) return;
    final imagingClient = OnvifImagingClient(connection);
    final nuraeye = NuraeyeClient(connection);
    final results = await Future.wait([
      imagingClient.getImagingSettings(),
      imagingClient.getImagingOptions(),
      MirrorFlipClient(nuraeye).getMirrorFlip(),
    ]);
    imagingClient.close();
    nuraeye.close();
    if (!mounted) return;

    final settingsResult = results[0] as CameraResult<ImagingSettings>;
    final optionsResult = results[1] as CameraResult<ImagingOptions>;
    final mirrorFlipResult = results[2] as CameraResult<MirrorFlipMode>;

    setState(() {
      if (settingsResult case CameraSuccess(:final value)) {
        if (value.brightness != null) _brightness = value.brightness!;
        if (value.colorSaturation != null) {
          _saturation = value.colorSaturation!;
        }
        if (value.contrast != null) _contrast = value.contrast!;
        if (value.sharpness != null) _sharpness = value.sharpness!;
        if (value.wdrMode != null) {
          _wdrEnabled = value.wdrMode!.toUpperCase() == 'ON';
        }
        if (value.wdrLevel != null) _wdrLevel = value.wdrLevel!;
        final whiteBalance = _autoManualFromWire(value.whiteBalanceMode);
        if (whiteBalance != null) _whiteBalance = whiteBalance;
        final exposure = _autoManualFromWire(value.exposureMode);
        if (exposure != null) _exposure = exposure;
      }
      if (optionsResult case CameraSuccess(:final value)) {
        _imagingOptions = value;
      }
      if (mirrorFlipResult case CameraSuccess(:final value)) {
        _mirrorFlip = _fromWireMirrorFlip(value);
      }
    });

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
  }

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  /// Looked up fresh from [HomesController] on every build (not
  /// [widget.camera] directly) so a refreshed snapshot from [_refreshPreview]
  /// actually shows up without leaving and re-entering this screen.
  Camera get _camera {
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.id == widget.camera.id) return camera;
      }
    }
    return widget.camera;
  }

  Future<void> _refreshPreview() async {
    final connection = _camera.connection;
    if (connection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved connection for this camera yet'),
        ),
      );
      return;
    }
    setState(() => _isRefreshing = true);
    final succeeded = await refreshCameraSnapshot(
      homesController: widget.homesController,
      cameraId: widget.camera.id,
      connection: connection,
    );
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _previewReloadKey++;
    });
    if (!succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to refresh preview')),
      );
    }
  }

  Future<void> _save() async {
    final connection = _camera.connection;
    setState(() => _isSaving = true);

    final bool succeeded;
    if (connection != null) {
      final imagingClient = OnvifImagingClient(connection);
      final wdrSupported = _imagingOptions?.wdrSupported ?? true;
      final imagingResult = await imagingClient.setImagingSettings(
        ImagingSettings(
          brightness: _brightness,
          colorSaturation: _saturation,
          contrast: _contrast,
          sharpness: _sharpness,
          wdrMode: wdrSupported ? (_wdrEnabled ? 'ON' : 'OFF') : null,
          wdrLevel: (wdrSupported && _wdrEnabled) ? _wdrLevel : null,
          whiteBalanceMode: _autoManualToWire(_whiteBalance),
          exposureMode: _autoManualToWire(_exposure),
        ),
      );
      imagingClient.close();

      final nuraeye = NuraeyeClient(connection);
      final mirrorFlipResult = await MirrorFlipClient(
        nuraeye,
      ).setMirrorFlip(_toWireMirrorFlip(_mirrorFlip));
      nuraeye.close();

      succeeded =
          imagingResult is CameraSuccess && mirrorFlipResult is CameraSuccess;
    } else {
      succeeded = await simulateCameraSave();
    }

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
      if (connection != null) unawaited(_refreshPreview());
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
                    camera: _camera,
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
                  // Without this, the selected segment's checkmark eats
                  // into an already-tight 4-segment row, wrapping "Mirror"
                  // mid-word ("Mirro"/"r") on narrower screens.
                  showSelectedIcon: false,
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
                // Hidden outright (not just disabled) when the camera's own
                // Options response says WDR isn't supported on this sensor —
                // per ImagingOptions.wdrSupported's doc. Shown when
                // unverified (no connection yet, _imagingOptions == null).
                if (_imagingOptions?.wdrSupported ?? true) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      key: const Key('IMG-012'),
                      title: const Text('WDR'),
                      value: _wdrEnabled,
                      onChanged: (value) =>
                          _markDirty(() => _wdrEnabled = value),
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
                ],
                const SizedBox(height: 16),
                Text(
                  'White balance',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<CameraAutoManual>(
                  key: const Key('IMG-009'),
                  segments: _autoManualSegments(
                    _imagingOptions?.whiteBalanceModes,
                    _whiteBalance,
                  ),
                  selected: {_whiteBalance},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      _markDirty(() => _whiteBalance = selection.first),
                ),
                const SizedBox(height: 16),
                Text('Exposure', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<CameraAutoManual>(
                  key: const Key('IMG-010'),
                  segments: _autoManualSegments(
                    _imagingOptions?.exposureModes,
                    _exposure,
                  ),
                  selected: {_exposure},
                  showSelectedIcon: false,
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
