---
feature_id: FEAT-094
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md]
---

# Scenario: Mobile App — Corrective Action Guidance

Covers the homeowner-facing side of FEAT-094: showing a recommended corrective action alongside
any health condition, while still exposing the raw diagnostic data underneath.

## Scenario: Dirty-lens alert comes with a clear next step

**Scenario ID:** SCN-347
**Feature ID:** FEAT-094

**Persona:** Marcus, a non-technical homeowner, receives a "Lens May Need Cleaning" alert (per
FEAT-090).

1. Alongside the alert, Marcus sees a short, plain-language recommendation: "Clean the camera
   lens with a soft, dry cloth," rather than just a raw technical description of the condition.
2. If he wants more detail, he can expand to see the underlying diagnostic (the clarity
   comparison, how long the condition has persisted) — the guidance doesn't replace or hide the
   raw data, it sits alongside it.
3. After following the suggestion, he can mark the action as done, which the app cross-checks
   against the condition actually clearing rather than just trusting his self-report blindly.

**What the user expects:** he's told what to actually do, in plain language, without losing
access to the underlying technical detail if he wants to dig deeper or if he's troubleshooting
with support.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a plain-language recommended corrective action
  alongside every health condition alert, without removing access to the underlying raw
  diagnostic data (which remains available via an expand/detail view).
- **[mobile-app]** The app shall let a user mark a suggested corrective action as completed, and
  shall independently verify against the condition's actual clear/unclear status rather than
  solely trusting the self-reported completion.

## Scenario: Recommended action doesn't fix the condition

**Scenario ID:** SCN-348
**Feature ID:** FEAT-094

**Persona:** Marcus cleans the lens as suggested, but the haze alert persists — the actual cause
is internal condensation, not surface dirt.

1. Marcus marks the suggested action as done, but the app notices the underlying condition
   hasn't actually cleared after a reasonable follow-up window.
2. Rather than silently leaving him stuck, the app offers an escalated recommendation (e.g.
   "still hazy after cleaning? this may indicate an internal fault — contact support") instead of
   just repeating the same cleaning suggestion indefinitely.
3. He can access support with the diagnostic history already attached, saving him from having to
   re-explain what he already tried.

**What the user expects:** if the suggested fix doesn't work, the app recognizes that and offers
a next step rather than looping him on the same ineffective advice.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall detect when a marked-complete corrective action did not result
  in the underlying condition clearing within a reasonable follow-up window, and shall escalate
  to a different recommendation rather than repeating the same suggestion.
- **[mobile-app]** The app shall let a user reach support directly from an unresolved condition,
  pre-attaching the condition's diagnostic history and the corrective action(s) already
  attempted.
