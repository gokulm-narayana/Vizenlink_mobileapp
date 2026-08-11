import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

/// Audio: a "Record Audio" toggle (whether recordings include an audio
/// track), speaker volume, microphone gain, and a test-sound action. Record
/// Audio is independent of the volume sliders, which affect two-way talk and
/// warning playback, not what gets recorded. Persisted through
/// [HomesController] (see `updateCamera`) — see the note on `videoMode` in
/// `lib/models/camera.dart`. Reached directly from camera settings (not
/// nested under Video & Display).
class AudioScreen extends StatefulWidget {
  const AudioScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'audio';

  final Camera camera;
  final HomesController homesController;

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  late double _speakerVolume = widget.camera.speakerVolume;
  late double _micGain = widget.camera.micGain;
  late bool _audioRecordingEnabled = widget.camera.audioRecordingEnabled;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isPlayingTestSound = false;

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
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
          speakerVolume: _speakerVolume,
          micGain: _micGain,
          audioRecordingEnabled: _audioRecordingEnabled,
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

  Future<void> _playTestSound() async {
    setState(() => _isPlayingTestSound = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playing test sound on camera speaker…')),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isPlayingTestSound = false);
  }

  Future<bool> _confirmLeave() => confirmDiscardOnLeave(
    context: context,
    isDirty: _isDirty,
    onSave: _save,
    isDirtyAfterSave: () => _isDirty,
    dialogKey: const Key('AUD-009'),
    discardKey: const Key('AUD-010'),
    saveKey: const Key('AUD-011'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('AUD-001'),
            title: const Text('Audio'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('AUD-002'),
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
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: const Key('AUD-012'),
                    title: const Text('Record Audio'),
                    subtitle: const Text(
                      'Include an audio track with this camera\'s recordings',
                    ),
                    value: _audioRecordingEnabled,
                    onChanged: (value) =>
                        _markDirty(() => _audioRecordingEnabled = value),
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Speaker volume (${_speakerVolume.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('AUD-006'),
                        value: _speakerVolume,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (value) =>
                            _markDirty(() => _speakerVolume = value),
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
                        'Microphone gain (${_micGain.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('AUD-007'),
                        value: _micGain,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (value) =>
                            _markDirty(() => _micGain = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const Key('AUD-008'),
                  onPressed: _isPlayingTestSound ? null : _playTestSound,
                  icon: _isPlayingTestSound
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Test Sound'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
