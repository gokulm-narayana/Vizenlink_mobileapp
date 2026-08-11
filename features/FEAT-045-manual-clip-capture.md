# FEAT-045 — Manual Clip Capture from Live Stream

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by a code/FR-reality audit
against §8.3 Recording, storage, and evidence's 15 `REC-*` rows, at the user's request.

**Why it's necessary/basic:** An operator can already trigger an ad-hoc clip capture directly
from a live stream — a manual/on-demand action distinct from `REC-001`'s continuous,
scheduled, and event-triggered recording modes (`FEAT-031`/`FEAT-032`), none of which cover a
human deciding, in the moment, to save what's happening right now. This capability lives on
the **mobile app/VMS/NVR side only** — the camera itself has no equivalent manual-capture
action.

**Cross-check performed:** Re-read all 15 `REC-*` rows; none mention a manual/operator-
triggered capture action, only automatic recording modes (continuous/scheduled/event) and
export of already-recorded footage.

**Priority:** P1 — a real, already-implemented capability, but secondary to the core
automatic-recording requirements.

**User-Facing:** yes — an operator directly triggers this from the live-view UI.

**FR Status:** Existing → `FR-VMS-031` (VMS only — no camera-side equivalent).

**Status:** confirmed (2026-07-21).
