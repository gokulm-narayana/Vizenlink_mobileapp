# FEAT-047 — Media Sharing / Share-Link Generation

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by a code/FR-reality audit
against §8.3 Recording, storage, and evidence's 15 `REC-*` rows, at the user's request.

**Why it's necessary/basic:** Part of the VMS's Media Gallery (`FR-VMS-081`, Implemented), this
lets an operator generate a shareable URL for a clip or snapshot — a recipient (e.g. a
resident, community admin, or law enforcement contact) opens the link and downloads the media
directly to their phone or laptop, without needing an app/VMS account. This is a distinct
distribution path from `REC-010`/`REC-011` (`FEAT-040`), which cover file export with a
cryptographic integrity manifest — that's a formal evidence-handling export, while this is an
informal, convenience-oriented sharing mechanism. Neither `REC-*` row anticipates a URL-based
sharing path.

**Cross-check performed:** Re-read all 15 `REC-*` rows; none mention link-based sharing,
only file export with metadata/integrity guarantees.

**Priority:** P1 — a convenience capability, not core to evidence handling.

**User-Facing:** yes — an operator generates and shares the link directly.

**FR Status:** Existing → `FR-VMS-081` (VMS/NVR only — no camera-side equivalent).

**Status:** confirmed (2026-07-21).
