# FEAT-051 — SD Card Format Action

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
existing-FR/code audit). Raised as a "necessary for a basic CCTV camera" candidate for §8.3
Recording, storage, and evidence.

**Why it's necessary/basic:** A user/installer-triggered format/initialize action for the
camera's microSD card is standard on virtually every consumer camera with local storage —
without it, a brand-new card (needing a filesystem) or a corrupted card (from a bad power
cycle, write failure, or file-system error per `REC-007`) has no recovery path short of
physically removing it and formatting on a PC. `REC-007` (`FEAT-038`) only covers *detecting*
these failure conditions; it says nothing about the corrective action available to the user
once detected.

**Cross-check performed:** Re-read all 15 `REC-*` rows; none mention a format/initialize
action, only detection of storage failure states. Also checked against the §8.3 code/FR-
reality audit's findings — not present there either.

**Priority:** P0 — without this, a new or corrupted card is effectively stuck, undermining
the core local-recording requirement (`REC-002`/`FEAT-033`) it depends on.

**User-Facing:** yes — a user/installer directly triggers this.

**FR Status:** Not started — no code, no FR entry.

**Status:** confirmed (2026-07-21).
