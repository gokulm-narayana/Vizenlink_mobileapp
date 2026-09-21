import 'package:camera_api/camera_api.dart';

/// WAN counterpart to `LoiteringDurationClient` (`camera_api`'s LAN NuraEye client) —
/// `GetLoiteringDuration`/`SetLoiteringDuration` (`FR-NE-121`, commands `72`/`71`). Same wire
/// vocabulary and bounds as LAN.
class WanLoiteringDurationClient {
  WanLoiteringDurationClient(String thingName, {IotCommandClient? iotCommandClient})
    : _iot = iotCommandClient ?? IotCommandClient(thingName);

  final IotCommandClient _iot;

  Future<CameraResult<int>> getLoiteringDuration({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final output = await _iot.sendCommandWithResponse(IotCommandClient.getLoiteringDuration);
      if (output == null) return const CameraTimeout();
      final seconds = output['loitering_duration_seconds'];
      if (seconds is! num) {
        return CameraFailure(
            'GetLoiteringDuration response missing loitering_duration_seconds: $output');
      }
      return CameraSuccess(seconds.toInt());
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  Future<CameraResult<void>> setLoiteringDuration(
    int seconds, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final output = await _iot.sendCommandWithResponse(
        IotCommandClient.setLoiteringDuration,
        params: {'loitering_duration_seconds': seconds},
      );
      if (output == null) return const CameraTimeout();
      return const CameraSuccess(null);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }
}
