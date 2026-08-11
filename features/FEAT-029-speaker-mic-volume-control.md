# FEAT-029 — Speaker/Mic Volume Control

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
existing-FR/code audit). Raised as a "necessary for a basic CCTV camera" candidate for §8.2
Audio and deterrence.

**Why it's necessary/basic:** Adjustable speaker output volume (for two-way talk and
prerecorded warning playback) and microphone input gain are standard on virtually every
consumer or CCTV camera with audio hardware — without it, two-way talk or a warning message
may be inaudible or distorted depending on installation environment (room size, ambient
noise, mounting distance), with no way for the installer/user to correct it.

**Cross-check performed:** The prior code/FR-reality audit for §8.2 explicitly checked for
volume-control entries across `FR-camera-firmware.md`, `FR-onvif-stack.md`, and the actual
firmware source, and confirmed none exist — this is a genuine absence, not an
undocumented-but-implemented capability like `FEAT-027`/`FEAT-028`. Also re-read all 8
`AUD-*` seed rows; none mention volume/gain adjustment.

**Priority:** P1 — a basic usability requirement for the audio features that already exist
(two-way talk, deterrence warnings), but not itself a core P0 security capability.

**User-Facing:** yes — installer/user adjusts these levels directly.

**FR Status:** Not started — no code, no FR entry.

**Status:** confirmed (2026-07-21).
