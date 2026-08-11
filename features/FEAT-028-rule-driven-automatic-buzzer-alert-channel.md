# FEAT-028 — Rule-Driven Automatic Buzzer Alert Channel

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by a code/FR-reality audit
against §8.2 Audio and deterrence's 8 `AUD-*` rows, at the user's explicit request.

**Why it's necessary/basic:** The buzzer can already be configured, per detection rule, as an
automatic alert channel alongside mobile push notifications — an admin/installer can choose
whether a given rule (e.g. after-hours intrusion) triggers the buzzer automatically when it
fires, independent of any manual/remote trigger. This is a different activation path from
`AUD-005` (deterrence hardware presence) and `AUD-006` (a confirmation gate specifically
scoped to *remote* activation) — neither seed row covers a rule-driven, automatic trigger with
no human-in-the-loop confirmation step at the moment of activation. `FEAT-027`'s auto-stop
safety timer applies regardless of which path (manual/remote/rule-driven) triggered the
buzzer, but the rule-driven *configuration surface* itself is a separate, undocumented-in-seed
capability.

**Cross-check performed:** Re-read all 8 `AUD-*` rows; none mention per-rule alert-channel
configuration or an automatic (non-confirmed) buzzer trigger path.

**Priority:** P1 — already implemented, a real differentiator for the deterrence story, but
secondary to the core recording/two-way-talk requirements.

**User-Facing:** yes — an installer/admin configures which detection rules trigger the
buzzer.

**FR Status:** Existing → `FR-NE-034`, `FR-NE-020`, `FR-NE-021` (nuraeye-service).

**Status:** confirmed (2026-07-21).
