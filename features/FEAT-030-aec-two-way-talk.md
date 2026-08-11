# FEAT-030 — Acoustic Echo Cancellation (AEC) for Two-Way Talk

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
existing-FR/code audit). Raised as a "necessary for a basic CCTV camera" candidate for §8.2
Audio and deterrence.

**Why it's necessary/basic:** Two-way talk (`AUD-004`, tracked as `FEAT-023`) requires the
camera's mic and speaker to run simultaneously in the same enclosure. Without acoustic echo
cancellation, the speaker's own output feeds back into the mic and the remote party hears
their own voice echoed back — in practice this makes two-way talk unusable, not merely
lower-quality. This is a usability *precondition* for a capability already marked P0 in the
seed doc, not an optional enhancement layered on top of it.

**Cross-check performed:** The prior code/FR-reality audit for §8.2 explicitly checked for AEC
entries across all three FR docs and the firmware source and confirmed none exist. Re-read
`AUD-004`'s text; it specifies "secure, permission-checked two-way talk" but says nothing
about audio quality/echo — silent on this precondition, not deliberately deferring it.

**Priority:** P0 — without it, the already-P0 two-way-talk requirement doesn't actually
deliver usable two-way talk.

**User-Facing:** no — this is audio-pipeline signal processing; the user experiences its
absence as a symptom (echo/feedback), not a control they operate. No AEC "setting" is implied.

**FR Status:** Not started — no code, no FR entry.

**Status:** confirmed (2026-07-21).
