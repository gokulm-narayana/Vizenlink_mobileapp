# FEAT-046 — Multi-Camera Grid View — Live & Synchronized Playback

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by a code/FR-reality audit
against §8.3 Recording, storage, and evidence's 15 `REC-*` rows, at the user's request.

**Why it's necessary/basic:** The VMS already lets an operator view multiple cameras
simultaneously on a shared grid, in two related but distinct modes: a configurable live-video
grid (1×1/2×2/3×3/custom layouts), and synchronized recorded-footage playback across up to 16
cameras on one shared timeline. Both are the same underlying user capability — "see multiple
cameras at once, in context with each other" — just for live vs. recorded content, so they're
tracked as one Feature rather than two, mirroring how `FEAT-004` and `FEAT-038` elsewhere in
this index cluster the same user-facing guarantee across different triggers. No `REC-*` row
mentions cross-camera grid viewing at all — `REC-009` only asks for indexed playback of a
single stream by time/event.

Note this capability is **VMS/NVR-side only** — the camera itself has no multi-camera grid
concept (a single camera has nothing to grid with).

**Cross-check performed:** Re-read all 15 `REC-*` rows; confirmed none address viewing
multiple cameras together, live or recorded. Verified both `FR-VMS-020` and `FR-VMS-033`
carry no "Source: seed ..." attribution in `FR-vms.md`, unlike sibling entries in the same
sections that do cite a seed ID — confirming both predate the seed's integration and have no
backing seed row.

**Priority:** P1 — both halves already implemented and valuable, but secondary to the core
single-camera recording/playback/export requirements.

**User-Facing:** yes — an operator directly selects and uses this grid view.

**FR Status:** Existing → `FR-VMS-020` (live grid), `FR-VMS-033` (synchronized playback).

**Status:** confirmed (2026-07-21).
