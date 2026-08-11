import '../../camera_result.dart';
import 'nuraeye_client.dart';

/// Camera capability discovery (`FR-NE-092`) — a single, growing NuraEye action rather than one
/// new action per capability (deliberate 2026-07-31 design choice; the existing per-feature
/// capability actions, `GetDeterrenceCapabilities`/`GetLocalStorageStatus`, keep their own
/// already-shipped contracts unchanged — this is the pattern for *new* capability flags only).
///
/// Mirrors the firmware's two-tier build structure (`FR-CF-137`): [wanCommandCapable] reflects
/// AWS IoT/MQTT itself (`CONFIG_AWS_ENABLED`); [wanLiveViewCapable] additionally requires
/// `REMOTE_LIVE_STREAMING` — a build can have AWS commands without KVS, so the former can be
/// `true` while the latter is `false`. Both also require this specific device to actually have
/// real AWS IoT credentials provisioned, not just build-time support.
class CameraCapabilities {
  const CameraCapabilities({required this.wanCommandCapable, required this.wanLiveViewCapable});

  /// Whether this device can receive AWS IoT/MQTT commands at all (deterrence, settings sync,
  /// WAN control) — independent of KVS. Not yet consumed anywhere in the app (no WAN command
  /// feature currently gates on it), but exposed for future use as WAN command features adopt
  /// capability checks the way `LiveViewController` already does for [wanLiveViewCapable].
  final bool wanCommandCapable;

  final bool wanLiveViewCapable;
}

/// Dispatches over both LAN and WAN on the firmware side (`FR-NE-092`, matching the
/// `GetDeterrenceCapabilities`/`GetLocalStorageStatus` convention), but this client only wraps
/// the LAN path — queried once at onboarding (`add_camera_credentials_screen.dart`, camera is
/// physically at hand) and cached, per the current app's only real use case. No WAN client
/// exists yet; add one (mirroring `IotCommandClient`'s Lambda-relay shape) if/when a feature
/// actually needs to re-check capabilities without being on LAN.
class CapabilitiesClient {
  CapabilitiesClient(this._nuraeye);

  final NuraeyeClient _nuraeye;

  Future<CameraResult<CameraCapabilities>> getCapabilities({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await _nuraeye.call('GetCapabilities', timeout: timeout);

    return switch (result) {
      CameraSuccess(:final value) => () {
          final wanCommandCapable = value['wan_command_capable'];
          final wanLiveViewCapable = value['wan_live_view_capable'];
          if (wanCommandCapable is! bool || wanLiveViewCapable is! bool) {
            return CameraFailure<CameraCapabilities>(
              'GetCapabilities response missing wan_command_capable/wan_live_view_capable: $value',
            );
          }
          return CameraSuccess<CameraCapabilities>(
            CameraCapabilities(
              wanCommandCapable: wanCommandCapable,
              wanLiveViewCapable: wanLiveViewCapable,
            ),
          );
        }(),
      CameraFailure(:final reason) => CameraFailure<CameraCapabilities>(reason),
      CameraTimeout() => const CameraTimeout<CameraCapabilities>(),
    };
  }
}
