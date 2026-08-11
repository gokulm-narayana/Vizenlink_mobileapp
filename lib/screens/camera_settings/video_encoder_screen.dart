import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

const _defaultResolution = CameraResolution.p1080;
const _defaultEncoder = CameraEncoderType.h264;
const _defaultProfile = CameraEncoderProfile.main;
const _defaultFrameRate = 15.0;
const _defaultGov = 30.0;
const _defaultQuality = 3.0;
const _defaultBitrateMode = CameraBitrateMode.cbr;
const _defaultBitrateKbps = 2048.0;

/// Video Encoder: resolution, encoder/profile, frame rate, GOV, quality,
/// bitrate mode, and bitrate. Persisted through [HomesController] (see
/// `updateCamera`) — see the note on `videoMode` in `lib/models/camera.dart`.
/// "Reset to Default" resets to this screen's hardcoded factory defaults,
/// not to whatever was last saved.
class VideoEncoderScreen extends StatefulWidget {
  const VideoEncoderScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'video-encoder';

  final Camera camera;
  final HomesController homesController;

  @override
  State<VideoEncoderScreen> createState() => _VideoEncoderScreenState();
}

class _VideoEncoderScreenState extends State<VideoEncoderScreen> {
  late CameraResolution _resolution = widget.camera.videoResolution;
  late CameraEncoderType _encoder = widget.camera.encoderType;
  late CameraEncoderProfile _profile = widget.camera.encoderProfile;
  late double _frameRate = widget.camera.frameRate;
  late double _gov = widget.camera.govLength;
  late double _quality = widget.camera.encoderQuality;
  late CameraBitrateMode _bitrateMode = widget.camera.bitrateMode;
  late double _bitrateKbps = widget.camera.bitrateKbps;
  bool _isDirty = false;
  bool _isSaving = false;

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  void _resetToDefault() {
    _markDirty(() {
      _resolution = _defaultResolution;
      _encoder = _defaultEncoder;
      _profile = _defaultProfile;
      _frameRate = _defaultFrameRate;
      _gov = _defaultGov;
      _quality = _defaultQuality;
      _bitrateMode = _defaultBitrateMode;
      _bitrateKbps = _defaultBitrateKbps;
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
          videoResolution: _resolution,
          encoderType: _encoder,
          encoderProfile: _profile,
          frameRate: _frameRate,
          govLength: _gov,
          encoderQuality: _quality,
          bitrateMode: _bitrateMode,
          bitrateKbps: _bitrateKbps,
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
    dialogKey: const Key('ENC-015'),
    discardKey: const Key('ENC-016'),
    saveKey: const Key('ENC-017'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('ENC-001'),
            title: const Text('Video Encoder'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('ENC-002'),
                isDirty: _isDirty,
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
          body: SavingOverlay(
            isSaving: _isSaving,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    key: const Key('ENC-014'),
                    onPressed: _resetToDefault,
                    child: const Text('Reset to Default'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Resolution',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraResolution>(
                  key: const Key('ENC-003'),
                  initialValue: _resolution,
                  items: const [
                    DropdownMenuItem(
                      value: CameraResolution.p1080,
                      child: Text('1080p'),
                    ),
                    DropdownMenuItem(
                      value: CameraResolution.p720,
                      child: Text('720p'),
                    ),
                    DropdownMenuItem(
                      value: CameraResolution.p480,
                      child: Text('480p'),
                    ),
                  ],
                  onChanged: (value) => _markDirty(() => _resolution = value!),
                ),
                const SizedBox(height: 16),
                Text(
                  'Video encoder',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraEncoderType>(
                  key: const Key('ENC-007'),
                  initialValue: _encoder,
                  items: const [
                    DropdownMenuItem(
                      value: CameraEncoderType.h264,
                      child: Text('H.264'),
                    ),
                    DropdownMenuItem(
                      value: CameraEncoderType.h265,
                      child: Text('H.265'),
                    ),
                  ],
                  onChanged: (value) => _markDirty(() => _encoder = value!),
                ),
                const SizedBox(height: 16),
                Text(
                  'Encoder profile',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraEncoderProfile>(
                  key: const Key('ENC-008'),
                  initialValue: _profile,
                  items: const [
                    DropdownMenuItem(
                      value: CameraEncoderProfile.baseline,
                      child: Text('Baseline'),
                    ),
                    DropdownMenuItem(
                      value: CameraEncoderProfile.main,
                      child: Text('Main'),
                    ),
                    DropdownMenuItem(
                      value: CameraEncoderProfile.high,
                      child: Text('High'),
                    ),
                  ],
                  onChanged: (value) => _markDirty(() => _profile = value!),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Frame rate (${_frameRate.round()} fps)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('ENC-009'),
                        value: _frameRate,
                        min: 1,
                        max: 25,
                        divisions: 24,
                        onChanged: (value) =>
                            _markDirty(() => _frameRate = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'GOV (${_gov.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('ENC-010'),
                        value: _gov,
                        min: 10,
                        max: 50,
                        divisions: 40,
                        onChanged: (value) => _markDirty(() => _gov = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Quality (${_quality.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('ENC-011'),
                        value: _quality,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (value) =>
                            _markDirty(() => _quality = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bitrate mode',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraBitrateMode>(
                  key: const Key('ENC-012'),
                  initialValue: _bitrateMode,
                  items: const [
                    DropdownMenuItem(
                      value: CameraBitrateMode.cbr,
                      child: Text('CBR (Constant)'),
                    ),
                    DropdownMenuItem(
                      value: CameraBitrateMode.vbr,
                      child: Text('VBR (Variable)'),
                    ),
                  ],
                  onChanged: (value) => _markDirty(() => _bitrateMode = value!),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bitrate (${_bitrateKbps.round()} kbps)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('ENC-013'),
                        value: _bitrateKbps,
                        min: 32,
                        max: 8192,
                        divisions: 254,
                        onChanged: (value) =>
                            _markDirty(() => _bitrateKbps = value),
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
