# FEAT-048 — Cloud Snapshot/Thumbnail Upload for Notifications

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by a code/FR-reality audit
against §8.3 Recording, storage, and evidence's 15 `REC-*` rows, at the user's request.

**Why it's necessary/basic:** Push notifications and the alert-history UI need a thumbnail
image to show alongside each alert — this requires uploading periodic or on-demand JPEG
snapshots to cloud storage (S3) specifically to back that delivery path. This is narrower and
more specific than `REC-014` (`FEAT-043`, optional cloud backup of selected *events* for
evidence retention) — `REC-014` is about backing up event evidence itself, while this Feature
is about a small supporting image asset that makes notifications/alert lists visually
scannable. Neither is a substitute for the other, and no `REC-*` row addresses
notification-thumbnail delivery as its own capability.

**Cross-check performed:** Re-read all 15 `REC-*` rows; none mention thumbnails, notification
payloads, or a distinction between evidence backup and UI-supporting image delivery.

**Priority:** P1 — supports notification/alert UX quality, not itself a core evidence or
recording requirement.

**User-Facing:** mixed — the upload mechanism itself is invisible plumbing, but the thumbnail
it produces is directly visible to the user in notifications and alert history.

**FR Status:** Existing → `FR-NE-061`, `FR-NE-072` (nuraeye-service) — both currently
`Planned`, not yet built.

**Status:** confirmed (2026-07-21).
