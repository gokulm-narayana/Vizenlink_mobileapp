import 'package:camera_api/camera_api.dart';


/// `FR-NE-099`/`FR-MOB-096`/`FR-MOB-097` (new "Authentication" card): WAN counterpart to
/// `OnvifDeviceClient`'s `setDeviceName`/`setDeviceLocation`/`setTimeZone`/`setUserPassword` —
/// there is no WAN transport for ONVIF SOAP at all, so each method here instead calls the
/// matching `NuraeyeAwsIotCommand_Set*` action added specifically for this
/// (`nuraeye.c`'s `prvAwsIotMessageCallback`). Deliberately **not** an implementation of a
/// shared interface with `OnvifDeviceClient` — method signatures match structurally (same
/// params, same `CameraResult<void>` return) so callers can pick either at a single call site
/// (mirrors `imaging_settings_screen.dart`'s `_nightVision` selection between
/// `WanNightVisionClient`/`NightVisionClient`), without forcing a formal interface onto
/// `OnvifDeviceClient` for the sake of these four simple setters.
///
/// **Read-side added 2026-08-10** (`FR-NE-106`) — previously out of scope, reasoning being
/// `CameraInfoScreen`'s cache-first convention already shows the last-known value with no live
/// fetch required on screen open. Found to be a real gap during a Force-WAN audit: the *first*
/// live fetch (onboarding prefetch, or a cache-miss on a fresh camera) always went via LAN
/// `OnvifDeviceClient`, regardless of `isWan` — the exact same "Get always LAN" bug already fixed
/// for Options endpoints, just for a settings screen with no Options concept at all. One combined
/// [getDeviceIdentity] command (not three, unlike the three `set*` methods below) since the app
/// only ever needs all three fields together for this one screen — see the firmware-side command
/// doc in `nuraeye_types.h` for the full reasoning.
class WanDeviceIdentityClient {
  /// [iotCommandClient] is overridable for tests — defaults to a real [IotCommandClient] for
  /// [thingName].
  WanDeviceIdentityClient(String thingName, {IotCommandClient? iotCommandClient})
    : _iot = iotCommandClient ?? IotCommandClient(thingName);

  final IotCommandClient _iot;

  Future<CameraResult<({String name, String location, String timezone})>> getDeviceIdentity({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final output = await _iot.sendCommandWithResponse(IotCommandClient.getDeviceIdentity);
      if (output == null) return const CameraTimeout();
      final name = output['name'];
      final location = output['location'];
      final timezone = output['timezone'];
      if (name is! String || location is! String || timezone is! String) {
        return CameraFailure('GetDeviceIdentity response missing fields: $output');
      }
      return CameraSuccess((name: name, location: location, timezone: timezone));
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  Future<CameraResult<void>> setDeviceName(
    String name, {
    Duration timeout = const Duration(seconds: 15),
  }) => _send(IotCommandClient.setCameraName, {'name': name});

  Future<CameraResult<void>> setDeviceLocation(
    String location, {
    Duration timeout = const Duration(seconds: 15),
  }) => _send(IotCommandClient.setCameraLocation, {'location': location});

  Future<CameraResult<void>> setTimeZone(
    String tz, {
    Duration timeout = const Duration(seconds: 15),
  }) => _send(IotCommandClient.setTimeZone, {'timezone': tz});

  /// See `OnvifDeviceClient.setUserPassword`'s doc — the same single-account-slot semantics
  /// apply over WAN. **Callers must update their own stored `CameraConnection.password` on
  /// success**, same caveat as the LAN client.
  Future<CameraResult<void>> setUserPassword(
    String username,
    String newPassword, {
    Duration timeout = const Duration(seconds: 15),
  }) => _send(IotCommandClient.setUserPassword, {
    'username': username,
    'new_password': newPassword,
  });

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
