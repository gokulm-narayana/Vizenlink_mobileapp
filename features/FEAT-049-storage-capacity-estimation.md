# FEAT-049 — Camera-Side Storage Capacity Estimation

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
existing-FR/code audit). Raised as a "necessary for a basic CCTV camera" candidate for §8.3
Recording, storage, and evidence.

**Why it's necessary/basic:** Proactively estimating and displaying "X days/hours of
recording remaining" (based on current bitrate and free local-SD storage) is standard on
virtually every consumer/pro camera and NVR UI (Hikvision, Dahua, Reolink, Synology
Surveillance Station all show this). This is distinct from `REC-007`/`FEAT-038` (which only
detects storage that has *already* failed/filled) — this Feature is about giving the
user/installer advance warning before that point is reached.

Split from a single cross-cutting candidate into camera-side (this Feature) and NVR/VMS-side
(`FEAT-050`), mirroring how `REC-001` was split into `FEAT-031`/`FEAT-032` — the camera needs
its own local-SD estimate, while the NVR/VMS needs an aggregate estimate across all its
cameras' allocated storage; these are different codebases/FR docs.

**Cross-check performed:** Re-read all 15 `REC-*` rows; none mention proactive
capacity/remaining-time estimation, only failure detection after the fact (`REC-007`) and
retention policy (`REC-006`). Also checked against the §8.3 code/FR-reality audit's findings —
not present there either.

**Priority:** P1 — a real usability/planning aid, but not itself a core recording
requirement.

**User-Facing:** yes — installer/user sees this directly.

**FR Status:** Not started — no code, no FR entry.

**Status:** confirmed (2026-07-21).
