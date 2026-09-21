import '../../camera_result.dart';
import '../../night_vision_types.dart';
import 'nuraeye_client.dart';

/// `SetNightVisionType`/`GetNightVisionType` (`FR-NE-037`/`FR-NE-038`, `FR-MOB-067`/`068`) — LAN
/// transport, via the `NuraeyeClient` JSON API. See [NightVisionSource] for the WAN counterpart
/// (`wan/wan_night_vision_client.dart`'s `WanNightVisionClient`, same shared interface).
class NightVisionClient implements NightVisionSource {
  NightVisionClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  @override
  Future<CameraResult<NightVisionStatus>> getNightVisionType({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetNightVisionType', timeout: timeout);
    return switch (result) {
      CameraSuccess(:final value) => () {
          final typeStr = value['type'];
          final colorCapable = value['color_capable'];
          final smartCapable = value['smart_capable'];
          if (typeStr is! String || colorCapable is! bool || smartCapable is! bool) {
            return CameraFailure<NightVisionStatus>(
              'GetNightVisionType response missing fields: $value',
            );
          }
          final type = NightVisionTypeWire.fromWire(typeStr) ?? NightVisionType.grey;
          final subStateStr = value['sub_state'];
          final subState = type == NightVisionType.smart && subStateStr is String
              ? NightVisionTypeWire.fromWire(subStateStr)
              : null;
          return CameraSuccess<NightVisionStatus>(
            NightVisionStatus(
              type: type,
              colorCapable: colorCapable,
              smartCapable: smartCapable,
              subState: subState,
            ),
          );
        }(),
      CameraFailure(:final reason) => CameraFailure<NightVisionStatus>(reason),
      CameraTimeout() => const CameraTimeout<NightVisionStatus>(),
    };
  }

  @override
  Future<CameraResult<void>> setNightVisionType(
    NightVisionType type, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call(
      'SetNightVisionType',
      params: {'type': type.wireValue},
      timeout: timeout,
    );
    return switch (result) {
      CameraSuccess() => const CameraSuccess<void>(null),
      CameraFailure(:final reason) => CameraFailure<void>(reason),
      CameraTimeout() => const CameraTimeout<void>(),
    };
  }
}
