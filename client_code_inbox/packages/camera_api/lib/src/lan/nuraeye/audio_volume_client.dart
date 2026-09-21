import 'package:http/http.dart' as http;

import '../../camera_connection.dart';
import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// Microphone input gain (`FR-MOB-081`, NuraEye `GetMicGain`/`SetMicGain`, `FR-NE-086`), the
/// microphone's own on/off recording state (`FR-CF-024`, NuraEye
/// `GetAudioRecording`/`SetAudioRecording`), and speaker test-tone playback (`FR-NE-098`/
/// `FR-CF-140`, `PlayTestSound`/`StopTestSound`/`GetTestSoundStatus`) — all `/nuraeye` JSON
/// actions via `NuraeyeClient`, distinct from gain (a *level*, meaningless once recording is
/// off) and distinct from the phone's own local volume/mute.
///
/// **Split out of the former combined `AudioVolumeClient` 2026-08-11** — speaker output volume
/// is an unrelated ONVIF Media2 SOAP action that happened to live in the same class as these
/// three; see `lan/onvif/speaker_volume_client.dart` for that one, and
/// `kb/raw/2026-08-11-code-camera-api-lan-wan-restructure.md` for why a single class speaking
/// two protocols didn't belong in a `lan/onvif/` vs `lan/nuraeye/` folder split. This class kept
/// its original name (`AudioVolumeClient`) since it's the majority-share half of the original.
///
/// Recording toggle hardware-verified against `testing_utilities/audio_recording_test.py`'s
/// `AUD-01` wire format. LAN-only, mirroring `OnvifImagingClient`'s own "no app-side WAN command
/// channel yet" gap for the recording toggle specifically (`FR-NE-085`'s WAN mirror is
/// camera-firmware-side only, same as `FR-NE-056`/etc. — the firmware's own
/// `SetAudioRecording`/`GetAudioRecording` MQTT counterpart, `FR-NE-078`, has no app client
/// either) — mic gain and test-sound *do* have WAN counterparts, see `wan/wan_audio_volume_client.dart`.
class AudioVolumeClient {
  AudioVolumeClient(this.connection, {http.Client? httpClient})
      : _nuraeye = NuraeyeClient(connection, httpClient: httpClient);

  final CameraConnection connection;
  final NuraeyeClient _nuraeye;

  Future<CameraResult<int>> getMicGain({Duration timeout = const Duration(seconds: 10)}) async {
    final result = await _nuraeye.call('GetMicGain', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
          final gain = value['gain'];
          if (gain is! num) {
            return CameraFailure<int>('GetMicGain response missing "gain": $value');
          }
          return CameraSuccess<int>(gain.toInt());
        }(),
      CameraFailure(:final reason) => CameraFailure<int>(reason),
      CameraTimeout() => const CameraTimeout<int>(),
    };
  }

  Future<CameraResult<void>> setMicGain(int gain, {Duration timeout = const Duration(seconds: 10)}) async {
    final result = await _nuraeye.call('SetMicGain', params: {'gain': gain}, timeout: timeout);
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  /// Whether the camera's microphone is actively capturing audio at all (`FR-CF-024`) — distinct
  /// from [getMicGain]'s input *level*. Wire format matched against
  /// `testing_utilities/audio_recording_test.py`'s `get_audio_recording()`
  /// (`{"output": {"enabled": bool}}`), the hardware-verified reference for this action.
  Future<CameraResult<bool>> isAudioRecordingEnabled({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetAudioRecording', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
          final enabled = value['enabled'];
          if (enabled is! bool) {
            return CameraFailure<bool>('GetAudioRecording response missing "enabled": $value');
          }
          return CameraSuccess<bool>(enabled);
        }(),
      CameraFailure(:final reason) => CameraFailure<bool>(reason),
      CameraTimeout() => const CameraTimeout<bool>(),
    };
  }

  /// See [isAudioRecordingEnabled]. Wire format matched against
  /// `testing_utilities/audio_recording_test.py`'s `set_audio_recording()`
  /// (`{"enabled": bool}` params, no meaningful `output`).
  Future<CameraResult<void>> setAudioRecordingEnabled(
    bool enabled, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetAudioRecording',
      params: {'enabled': enabled},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  /// `FR-NE-098`/`FR-CF-140`: plays a short prerecorded test tone through the camera's speaker,
  /// letting a user confirm the speaker is audible/wired correctly from the Audio Settings
  /// screen without starting a live two-way-talk session. LAN-only, same as the two-way-talk
  /// session commands (no WAN command channel for this action). No params; duration is the
  /// recorded clip's own length.
  Future<CameraResult<void>> playTestSound({Duration timeout = const Duration(seconds: 10)}) async {
    final result = await _nuraeye.call('PlayTestSound', timeout: timeout);
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  /// Stops test-tone playback started by [playTestSound], if still playing.
  Future<CameraResult<void>> stopTestSound({Duration timeout = const Duration(seconds: 10)}) async {
    final result = await _nuraeye.call('StopTestSound', timeout: timeout);
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }

  /// Whether the test tone started by [playTestSound] is still playing — lets the UI reset its
  /// button/spinner state once the (fixed-length) clip finishes on its own.
  Future<CameraResult<bool>> isTestSoundPlaying({Duration timeout = const Duration(seconds: 10)}) async {
    final result = await _nuraeye.call('GetTestSoundStatus', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
          final playing = value['playing'];
          if (playing is! bool) {
            return CameraFailure<bool>('GetTestSoundStatus response missing "playing": $value');
          }
          return CameraSuccess<bool>(playing);
        }(),
      CameraFailure(:final reason) => CameraFailure<bool>(reason),
      CameraTimeout() => const CameraTimeout<bool>(),
    };
  }

  void close() {
    _nuraeye.close();
  }
}
