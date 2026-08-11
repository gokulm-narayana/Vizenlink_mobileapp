# FEAT-096 — WiFi Signal Strength Indicator

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by a code/FR-reality audit
against §8.6's 16 `HLT-*` rows, at the user's request.

**Why it's necessary/basic:** Live WiFi signal strength (RSSI) is already exposed via the
NuraEye API (`FR-NE-012`, Implemented), but no `HLT-*` row covers signal-quality diagnostics —
`HLT-001` only models discrete connectivity states (online/cloud-unreachable/NVR-unreachable/
offline), not a continuous quality metric. This directly benefits installers judging camera
placement, or explaining a flaky connection before it degrades into a full `HLT-002` offline
event.

**Applicability constraint:** only meaningful when the camera is connected via WiFi — see
`FEAT-097` for the interface-type indicator this pairs with; on Ethernet, RSSI should be
hidden/grayed rather than shown as a stale or zero value.

**Cross-check performed:** Re-read all 16 `HLT-*` rows; none mention signal strength/quality.

**Priority:** P1 — a real, already-implemented diagnostic aid, secondary to core failure
detection.

**User-Facing:** yes — directly viewed by installer/admin.

**FR Status:** Existing → `FR-NE-012` (nuraeye-service).

**Status:** confirmed (2026-07-21).
