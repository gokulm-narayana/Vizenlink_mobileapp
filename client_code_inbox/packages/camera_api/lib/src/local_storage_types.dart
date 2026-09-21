/// `FR-CF-044`/`FR-NE-087`: live local (SD card) storage status — shared by
/// `LocalStorageClient` (LAN) and `WanLocalStorageClient` (WAN), since both transports report
/// the identical field set.
///
/// [enabled]/[cardPresent] are two independent facts, not one — a card can be present with
/// recording disabled, or enabled with no card physically inserted (the camera rejects turning
/// `enabled` on in that case, but does not retroactively turn it off if a card already recording
/// is later pulled out — see `SETTINGS_API_GUIDE.md`'s "Local Storage" entry for the full
/// card-removal-while-enabled caveat).
class LocalStorageStatus {
  const LocalStorageStatus({
    required this.enabled,
    required this.cardPresent,
    required this.capacityBytes,
    required this.freeBytes,
  });

  final bool enabled;
  final bool cardPresent;
  final int capacityBytes;
  final int freeBytes;
}
