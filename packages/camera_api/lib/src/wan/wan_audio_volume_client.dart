import '../camera_result.dart';
import 'iot_command_client.dart';

/// WAN counterpart to `lan/nuraeye/audio_volume_client.dart`'s `AudioVolumeClient` mic-gain/
/// test-sound half — `SetMicGain`/`GetMicGain` (`FR-NE-086`) have been `Implemented` and
/// hardware-verified on both LAN and WAN in firmware since 2026-07-28, but `AudioSettingsScreen`
/// never wired the WAN side until now.
///
/// Recording on/off (`FR-CF-024`) has no WAN mirror — stays LAN-only. The test-tone commands
/// (`playTestSound`/`stopTestSound`/`isTestSoundPlaying` below) **did too, until `FR-NE-107`
/// (2026-08-11)** — reversed by direct user instruction, since a WAN user needs to confirm the
/// speaker works just as much as a LAN one does.
///
/// **Split out of the former combined `WanAudioVolumeClient` 2026-08-11** — speaker volume is a
/// separate, unrelated command group that happened to live in the same class as these; see
/// `wan_speaker_volume_client.dart` for that one. This class kept its original name since it's
/// the majority-share half of the original.
class WanAudioVolumeClient {
  WanAudioVolumeClient(String thingName, {IotCommandClient? iotCommandClient})
    : _iot = iotCommandClient ?? IotCommandClient(thingName);

  final IotCommandClient _iot;

  Future<CameraResult<int>> getMicGain({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final output = await _iot.sendCommandWithResponse(IotCommandClient.getMicGain);
      if (output == null) return const CameraTimeout();
      final gain = output['gain'];
      if (gain is! num) return CameraFailure('GetMicGain response missing gain: $output');
      return CameraSuccess(gain.toInt());
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  Future<CameraResult<void>> setMicGain(
    int gain, {
    Duration timeout = const Duration(seconds: 15),
  }) => _send(IotCommandClient.setMicGain, {'gain': gain});

  Future<CameraResult<void>> playTestSound({Duration timeout = const Duration(seconds: 15)}) =>
      _sendNoParams(IotCommandClient.playTestSound);

  Future<CameraResult<void>> stopTestSound({Duration timeout = const Duration(seconds: 15)}) =>
      _sendNoParams(IotCommandClient.stopTestSound);

  Future<CameraResult<bool>> isTestSoundPlaying({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final output = await _iot.sendCommandWithResponse(IotCommandClient.getTestSoundStatus);
      if (output == null) return const CameraTimeout();
      final playing = output['playing'];
      if (playing is! bool) {
        return CameraFailure('GetTestSoundStatus response missing playing: $output');
      }
      return CameraSuccess(playing);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  Future<CameraResult<void>> _sendNoParams(int command) async {
    try {
      final output = await _iot.sendCommandWithResponse(command);
      if (output == null) return const CameraTimeout();
      return const CameraSuccess(null);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  Future<CameraResult<void>> _send(int command, Map<String, dynamic> params) async {
    try {
      final output = await _iot.sendCommandWithResponse(command, params: params);
      if (output == null) return const CameraTimeout();
      return const CameraSuccess(null);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }
}
