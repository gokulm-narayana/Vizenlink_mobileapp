# FEAT-098 — User-Triggered Camera Restart with Health Confirmation

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
existing-FR/code audit). Raised as a "necessary for a basic CCTV camera" candidate for §8.6
Camera tamper and health intelligence.

**Why it's necessary/basic:** A "Restart Camera" action a user/installer can trigger on
demand, with explicit feedback on whether the camera came back up healthy afterward, is
standard troubleshooting UX on any networked camera/NVR product. This is distinct from
`HLT-009`/`FEAT-088` (which detects an *automatic, repeated* reboot pattern as a failure
signal) — this Feature is a deliberate, single, user-initiated action with a direct
success/failure outcome shown to the person who triggered it, not a passive detection
mechanism.

**Cross-check performed:** Re-read all 16 `HLT-*` rows; none describe a user-triggered restart
action or its confirmation feedback. No new hardware required — this repo already reboots the
device via `bsp_rebootAsync()` for OTA finalization, so the underlying mechanism exists; this
Feature is about exposing an on-demand trigger plus a post-restart health check to the user.

**Priority:** P1 — a common troubleshooting necessity, not itself a core P0 security
capability.

**User-Facing:** yes — directly triggered and observed by the user.

**FR Status:** Not started — no FR entry for an on-demand restart action with confirmation.

**Status:** confirmed (2026-07-21).
