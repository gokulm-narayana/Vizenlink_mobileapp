/// `FR-HLT-009` (Stage 3, first slice, extended 2026-08-26): camera health/vitals — shared by
/// `HealthClient` (LAN) and `WanHealthClient` (WAN), since both transports report the identical
/// field set.
///
/// [lastRebootUtc] reads `0` until the camera's first NTP sync of the current boot corrects it
/// (no battery-backed RTC — every boot's clock starts uncertain by definition, see `FR-CF-114`)
/// — `0` therefore means "not yet corrected this boot," not "camera has never booted."
///
/// [clockSyncState]/[uncertainSince] mirror `FR-HLT-022`'s status half — only two states exist
/// (`synced`/`uncertain`), not a third "free-running since boot" sub-state, since the camera's
/// BSP layer doesn't distinguish that from a full sync.
///
/// [firmwareVersion] duplicates what `OnvifDeviceClient.getDeviceInformation()` already reports
/// — included here too so one health call covers full vitals without a second round trip.
///
/// This is `FR-HLT-009`'s first slice only — a reboot-loop flag and AI-model version are not
/// implemented yet, and last-recording-segment timestamp isn't either.
enum ClockSyncState { synced, uncertain }

class HealthStatus {
  const HealthStatus({
    required this.rebootCount,
    required this.lastRebootUtc,
    required this.uptimeSeconds,
    required this.clockSyncState,
    required this.uncertainSince,
    required this.firmwareVersion,
  });

  final int rebootCount;
  final int lastRebootUtc;
  final int uptimeSeconds;
  final ClockSyncState clockSyncState;

  /// UTC epoch seconds the clock became uncertain; `0` if [clockSyncState] is
  /// [ClockSyncState.synced].
  final int uncertainSince;
  final String firmwareVersion;
}
