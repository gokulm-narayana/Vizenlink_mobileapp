/// Shared wire vocabulary for `SetSystemFactoryDefault`'s `FactoryDefault` type (`FR-CF-111`,
/// `FR-NE-110`) — used by both `lan/onvif/onvif_device_client.dart`'s `OnvifDeviceClient.factoryReset`
/// and `wan/wan_device_identity_client.dart`'s `WanDeviceIdentityClient.factoryReset`, so it
/// lives at the package root rather than under `lan/`, mirroring `anti_flicker_types.dart`.
///
/// Unlike anti-flicker, this **is** a real ONVIF-standard type (`tt:FactoryDefaultType`,
/// `onvif_device_set_system_factory_default.c`'s `parseRequest` accepts exactly these two
/// literal strings) — the WAN command mirrors it only because ONVIF SOAP has no WAN transport
/// in this stack, not because the setting itself is NuraEye-only.
enum FactoryResetMode {
  /// Erases ONVIF user settings only (camera name/location, imaging, masks, OSD, etc.) — network
  /// config (WiFi credentials, DHCP preferred IP) is preserved, so the device stays reachable at
  /// its existing address after it reboots.
  soft,

  /// Erases ONVIF user settings **and** network config — the device re-enters AP provisioning
  /// mode on reboot and must be re-onboarded (WiFi credentials re-entered, WS-Discovery/manual
  /// add repeated) before it's reachable again.
  hard,
}

extension FactoryResetModeWire on FactoryResetMode {
  String get wireValue => switch (this) {
    FactoryResetMode.soft => 'Soft',
    FactoryResetMode.hard => 'Hard',
  };
}
