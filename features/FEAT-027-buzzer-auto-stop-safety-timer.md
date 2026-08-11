# FEAT-027 — Buzzer Auto-Stop Safety Timer & Status Query

**Origin:** Inferred — existing FR/code (no seed row). Surfaced by a code/FR-reality audit
against §8.2 Audio and deterrence's 8 `AUD-*` rows, at the user's explicit request (same
practice established for §8.1 Video and imaging).

**Why it's necessary/basic:** The buzzer's activation is already implemented as bounded and
self-terminating — an activation call takes a duration and auto-stops via a timer, with a
repeat activation restarting the countdown rather than stacking, plus a status query and an
immediate-stop action that cancels any pending auto-off. This is a distinct safety property
from `AUD-006`'s confirmation gate: `AUD-006` is about *authorizing* activation (confirm
before it starts), while this Feature is about the activation *never running forever*
regardless of how it was triggered — locally confirmed, remote, or rule-triggered. Neither
`AUD-005` nor `AUD-006` mention bounded/self-terminating behavior or a status query at all.

**Cross-check performed:** Re-read `AUD-005`/`AUD-006`; confirmed neither addresses activation
duration limits or status querying — they only cover deterrence-hardware presence and the
pre-activation confirmation policy.

**Priority:** P1 — already implemented, and a real safety property (an indefinitely-running
siren/buzzer is a genuine nuisance/liability risk), but secondary to the core confirmation-gate
requirement it complements.

**User-Facing:** yes — a user/operator sees the buzzer's current state and can stop it early.

**FR Status:** Existing → `FR-CF-124` (camera-firmware), `FR-NE-035` (nuraeye-service).

**Status:** confirmed (2026-07-21).
