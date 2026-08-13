import 'package:camera_api/camera_api.dart';
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
/// warning playback, not what gets recorded. Backed by real `camera_api`
/// (`AudioCapabilityClient`/`AudioVolumeClient`/`SpeakerVolumeClient`, LAN
/// only — same "no WAN fallback wired up yet" gap as every other settings
/// screen so far) when the camera has a saved connection, falling back to
/// local-only `HomesController` state (`simulateCameraSave`) otherwise.
/// Speaker volume / mic gain controls are hidden (not disabled) when the
/// camera's own `AudioCapabilityClient.getAudioCapability()` reports no
/// speaker/microphone hardware, per
/// `.claude/rules/mobile-app-screen-conventions.md` item 5. Persisted
/// through [HomesController] (see `updateCamera`) — see the note on
/// `videoMode` in `lib/models/camera.dart`. Reached directly from camera
/// settings (not nested under Video & Display).
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
  late double _speakerVolume = _camera.speakerVolume;
  late double _micGain = _camera.micGain;
  late bool _audioRecordingEnabled = _camera.audioRecordingEnabled;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isPlayingTestSound = false;

  /// Hardware-presence gate from `AudioCapabilityClient.getAudioCapability()`
  /// — null means "camera not verified yet" (no connection, or the check
  /// hasn't returned), in which case every control shows (same fallback
  /// reasoning as `_imagingOptions` in imaging_screen.dart).
  AudioCapability? _audioCapability;

  /// The ONVIF `SpeakerVolume` struct as last read from the camera —
  /// `token`/`name`/`outputToken` must be echoed back verbatim on
  /// `SpeakerVolumeClient.setSpeakerVolume`. Null when unverified.
  SpeakerVolume? _speakerVolumeConfig;

  /// Looked up fresh from [HomesController] on every build (not
  /// [widget.camera] directly), matching every other camera-settings screen.
  Camera get _camera {
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.id == widget.camera.id) return camera;
      }
    }
    return widget.camera;
  }

  @override
  void initState() {
    super.initState();
    _loadRealAudio();
  }

  Future<void> _loadRealAudio() async {
    final connection = _camera.connection;
    if (connection == null) return;

    final capabilityClient = AudioCapabilityClient(connection);
    final capabilityResult = await capabilityClient.getAudioCapability();
    capabilityClient.close();
    if (!mounted) return;

    AudioCapability? capability;
    if (capabilityResult case CameraSuccess(:final value)) {
      capability = value;
      setState(() => _audioCapability = value);
    }

    final futures = <Future<void>>[];
    if (capability?.hasMicrophone ?? true) {
      final volumeClient = AudioVolumeClient(connection);
      futures.add(
        Future(() async {
          final results = await Future.wait([
            volumeClient.getMicGain(),
            volumeClient.isAudioRecordingEnabled(),
          ]);
          volumeClient.close();
          if (!mounted) return;
          setState(() {
            if (results[0] case CameraSuccess<int>(:final value)) {
              _micGain = value.toDouble();
            }
            if (results[1] case CameraSuccess<bool>(:final value)) {
              _audioRecordingEnabled = value;
            }
          });
          widget.homesController.updateCamera(
            widget.camera.id,
            (camera) => camera.copyWith(
              micGain: _micGain,
              audioRecordingEnabled: _audioRecordingEnabled,
            ),
          );
        }),
      );
    }
    if (capability?.hasSpeaker ?? true) {
      final speakerClient = SpeakerVolumeClient(connection);
      futures.add(
        Future(() async {
          final result = await speakerClient.getSpeakerVolume();
          speakerClient.close();
          if (!mounted) return;
          if (result case CameraSuccess<SpeakerVolume>(:final value)) {
            setState(() {
              _speakerVolumeConfig = value;
              _speakerVolume = value.outputLevel.toDouble();
            });
            widget.homesController.updateCamera(
              widget.camera.id,
              (camera) => camera.copyWith(speakerVolume: _speakerVolume),
            );
          }
        }),
      );
    }
    await Future.wait(futures);
  }

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    final connection = _camera.connection;
    setState(() => _isSaving = true);

    final bool succeeded;
    if (connection != null) {
      final results = <CameraResult<void>>[];
      final hasMicrophone = _audioCapability?.hasMicrophone ?? true;
      final hasSpeaker = _audioCapability?.hasSpeaker ?? true;

      if (hasMicrophone) {
        final volumeClient = AudioVolumeClient(connection);
        results.add(await volumeClient.setMicGain(_micGain.round()));
        results.add(
          await volumeClient.setAudioRecordingEnabled(_audioRecordingEnabled),
        );
        volumeClient.close();
      }
      if (hasSpeaker) {
        final speakerConfig = _speakerVolumeConfig;
        if (speakerConfig != null) {
          final speakerClient = SpeakerVolumeClient(connection);
          results.add(
            await speakerClient.setSpeakerVolume(
              speakerConfig.withLevel(_speakerVolume.round()),
            ),
          );
          speakerClient.close();
        }
      }
      succeeded = results.every((r) => r is CameraSuccess);
    } else {
      succeeded = await simulateCameraSave();
    }

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
    final connection = _camera.connection;
    if (connection != null) {
      final volumeClient = AudioVolumeClient(connection);
      await volumeClient.playTestSound();
      volumeClient.close();
    } else {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
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
                if (_audioCapability?.hasMicrophone ?? true) ...[
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
                ],
                if (_audioCapability?.hasSpeaker ?? true) ...[
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
                ],
                if (_audioCapability?.hasMicrophone ?? true)
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
                if (_audioCapability?.hasSpeaker ?? true) ...[
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
