/// Shared wire vocabulary for `SetPrivacyMode`/`GetPrivacyMode` (`FR-CF-138`/`FR-NE-093`) — used
/// by both `lan/privacy_mode_client.dart`'s `PrivacyModeClient` and
/// `wan/wan_privacy_mode_client.dart`'s `WanPrivacyModeClient`, so it lives at the package root
/// rather than under `lan/`.
enum PrivacyMode { none, zone, full }

extension PrivacyModeWire on PrivacyMode {
  String get wireValue => switch (this) {
    PrivacyMode.none => 'None',
    PrivacyMode.zone => 'Zone',
    PrivacyMode.full => 'Full',
  };

  static PrivacyMode? fromWire(String value) {
    return switch (value) {
      'None' => PrivacyMode.none,
      'Zone' => PrivacyMode.zone,
      'Full' => PrivacyMode.full,
      _ => null,
    };
  }
}
