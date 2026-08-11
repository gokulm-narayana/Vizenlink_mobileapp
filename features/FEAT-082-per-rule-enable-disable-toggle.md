# FEAT-082 — Per-Rule Enable/Disable Toggle

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
existing-FR/code audit). Raised as a "necessary for a basic CCTV camera" candidate for §8.5
Security event rules.

**Why it's necessary/basic:** A simple on/off switch for an individual rule — distinct from
`RUL-004`/`FEAT-067` (which governs *when* a rule is active on a schedule) and distinct from
deleting the rule outright — is standard on virtually every rule-based CCTV/NVR system.
Without it, a user who wants to temporarily suppress a rule (e.g. a "vehicle in driveway"
after-hours rule, while a guest's car is parked there for a few days) has no option but to
delete and later recreate the rule, losing its configuration (zone shape, class filter,
schedule) in the process.

**Cross-check performed:** Re-read all 19 `RUL-*` rows; none mention a standalone enable/
disable toggle — `RUL-004` covers schedule-based activity windows, not a manual override
switch. Also checked against the §8.5 existing-code audit's findings — not present there
either.

**Priority:** P0 — a basic usability necessity for any rule the user has already configured.

**User-Facing:** yes — a user/admin directly toggles this.

**FR Status:** Not started — no code, no FR entry.

**Status:** confirmed (2026-07-21).
