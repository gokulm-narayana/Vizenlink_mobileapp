# FEAT-015 — On-Screen Display (OSD) Overlay

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by an ad hoc code/FR-reality
audit against §8.1 Video and imaging's 15 `VID-*` rows, at the user's request — distinct from
the skill's standard seed-doc-prose "Gap scan."

**Why it's necessary/basic:** ONVIF's OSD service is already implemented, letting an
installer/admin configure text, timestamp, and logo overlays burned into the video stream —
see `FR-onvif-stack.md` §2.7 (roadmap section covering OSD) for the implementation-level
detail. None of `VID-001`–`VID-015` mention overlay/OSD configuration at all.

**Cross-check performed:** Re-read all 15 `VID-*` rows; none reference on-screen overlays or
burned-in text/logo/timestamp display (VID-009's timestamp requirement is about clock
*accuracy*, not the on-screen rendering of that timestamp).

**Priority:** P1 — a real, already-implemented capability, but not core to the product's
security value proposition the way streaming/recording/AI detection are.

**User-Facing:** yes — an installer/admin directly configures what appears on the overlay,
and any operator viewing the stream sees the result.

**FR Status:** Existing → [FR-OV-100](../FR-onvif-stack.md#27-events-service-profile-s-roadmap).

**Status:** confirmed (2026-07-21).
