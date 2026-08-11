# FEAT-097 — Active Network Interface Indicator

**Origin:** Inferred — existing FR/code (no seed row). Surfaced during discussion of
`FEAT-096` (WiFi signal strength) — user asked whether "current active network interface"
also belongs in camera health, since RSSI is only meaningful on WiFi.

**Why it's necessary/basic:** Knowing whether the camera is currently connected via WiFi or
Ethernet is itself a useful health/diagnostic data point — it determines whether `FEAT-096`'s
RSSI value is meaningful at all, and helps installers/support reason about connectivity
issues differently depending on connection type. The seed doc's own SKU-B description notes
"Ethernet option preferred even when Wi-Fi is present," implying dual-interface hardware where
knowing which is active matters.

**Cross-check performed:** Grepped the BSP source directly — `bsp_getNetworkInterfaceAddresses()`
already detects the active interface and distinguishes Ethernet from WiFi by name prefix, but
this is currently wired **only into the debug-build-only OSD statistics overlay** (`FR-CF-130`,
already decided out of scope per the §8.1 gap scan — debug-build-only, never ships to
production). No production-facing API (NuraEye or ONVIF) exposes this today. Re-read all 16
`HLT-*` rows; none mention interface type.

**Priority:** P1 — a real diagnostic aid, secondary to core failure detection.

**User-Facing:** yes — directly viewed by installer/admin.

**FR Status:** Existing in code (BSP-level interface detection), but **no FR entry yet** and
no production API — the underlying detection logic exists, wiring it to a real endpoint is
future FR/Design/Code work, not something this compile step performs.

**Status:** confirmed (2026-07-21).
