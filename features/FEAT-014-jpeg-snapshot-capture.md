# FEAT-014 — JPEG Snapshot Capture

**Origin:** Inferred — existing FR/code (no seed row). Not from `design/*Feature_Seed*.md`
§8 prose — this was surfaced by an ad hoc code/FR-reality audit against §8.1 Video and
imaging's 15 `VID-*` rows, at the user's request, distinct from the skill's standard
seed-doc-prose "Gap scan."

**Why it's necessary/basic:** Still-image capture is a baseline camera capability, already
implemented and exposed to both app/VMS clients (an authenticated snapshot endpoint) and
ONVIF clients (`GetSnapshotUri`, `FR-OV-034`) — see `FR-camera-firmware.md` §2.2 Video
Pipeline and `FR-onvif-stack.md` §2.3 Media Service for the implementation-level detail.

None of `VID-001`–`VID-015` mention still-image capture at all — §8.1's seed rows are
entirely stream-oriented (primary/mobile stream resolution, codec, WDR, zoom, etc.). A user
scanning `design/features/INDEX.md` for "does this product support taking a snapshot" would
otherwise find no Feature at all, despite the capability being live in shipped code.

**Cross-check performed:** Not applicable in the usual §3.3 Non-goals / Gated sense (that
cross-check is for the seed doc's own prose scan) — checked instead that no `VID-*` row
covers this, confirmed by re-reading all 15 rows.

**Priority:** P0 — already implemented and already load-bearing (used by ONVIF Profile S
clients and the VMS).

**User-Facing:** yes — a user/operator directly triggers or views a snapshot.

**FR Status:** Existing → [FR-CF-013](../FR-camera-firmware.md#22-video-pipeline),
[FR-OV-034](../FR-onvif-stack.md#23-media-service-profile-s).

**Status:** confirmed (2026-07-21).
