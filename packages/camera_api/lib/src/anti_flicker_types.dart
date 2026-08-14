/// Shared wire vocabulary for `SetAntiFlickerMode`/`GetAntiFlickerMode` (`FR-NE-109`) — used by
/// both `lan/nuraeye/anti_flicker_client.dart`'s `AntiFlickerClient` and
/// `wan/wan_anti_flicker_client.dart`'s `WanAntiFlickerClient`, so it lives at the package root
/// rather than under `lan/`, mirroring `mirror_flip_types.dart`.
///
/// No ONVIF-standard element exists for this setting (checked against the live
/// `ImagingSettings20` schema — see `kb/raw/2026-08-12-feature-antiflicker-mode.md`), so this is
/// NuraEye-only on both transports, same situation as `MirrorFlipMode`.
enum AntiFlickerMode { hz50, hz60, auto }

extension AntiFlickerModeWire on AntiFlickerMode {
  String get wireValue => switch (this) {
    AntiFlickerMode.hz50 => '50Hz',
    AntiFlickerMode.hz60 => '60Hz',
    AntiFlickerMode.auto => 'Auto',
  };

  static AntiFlickerMode? fromWire(String value) {
    return switch (value) {
      '50Hz' => AntiFlickerMode.hz50,
      '60Hz' => AntiFlickerMode.hz60,
      'Auto' => AntiFlickerMode.auto,
      // 'None' is a real camera-side value (forward-compat default) but is never offered as a
      // client-facing choice — treated as unrecognized here rather than given a 4th enum value.
      _ => null,
    };
  }
}
