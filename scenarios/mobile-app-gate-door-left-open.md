---
feature_id: FEAT-076
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Gate/Door-Left-Open Detection

Covers the homeowner-facing side of FEAT-076: alerting when a gate/door is left open, using a
reliable visual state (or an integrated physical sensor where available).

## Scenario: Gate left open after a visitor leaves

**Scenario ID:** SCN-268
**Feature ID:** FEAT-076

**Persona:** Elena, who wants to be told if her side gate is ever left open, since her dog could
otherwise get out.

1. Elena configures a "gate open" rule against a zone/region she's marked as the gate's visual
   open/closed state, with a duration threshold (e.g. open for more than 5 minutes).
2. A visitor leaves through the gate and doesn't latch it behind them.
3. Once the gate has visually remained in the "open" state continuously past 5 minutes, Elena
   gets a "Gate left open" alert.

**What the user expects:** she's warned about a real, sustained safety gap (not the brief moment
of someone walking through), so she can go close it before the dog notices.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure a gate/door-left-open rule against a
  marked visual region, with a duration threshold before an alert is raised, distinct from an
  ordinary zone entry/presence rule.
- **[camera-firmware]** The camera shall determine the open/closed visual state of a marked
  gate/door region and raise a left-open event only once that state has remained continuously
  "open" past the configured threshold.

## Scenario: Gate ajar in the wind doesn't cause a nuisance alert

**Scenario ID:** SCN-269
**Feature ID:** FEAT-076

**Persona:** Elena, whose gate sometimes swings slightly in strong wind without actually being
left open by a person.

1. The gate moves back and forth slightly in the wind, never settling fully open or fully
   closed for long.
2. Because the camera requires a continuous, stable "open" state for the full threshold
   duration (not just a cumulative or intermittent one), the wind-driven wobble doesn't
   accumulate into a left-open alert.
3. Elena isn't bothered by an alert for what's actually just windy weather.

**What the user expects:** ordinary wind movement isn't mistaken for someone leaving the gate
open — the alert reflects a genuinely sustained, stable open state.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall require the gate/door's visual state to remain
  continuously and stably "open" (not merely open-more-often-than-closed, or intermittently
  open) for the full configured duration before raising a left-open alert, so intermittent
  wind-driven movement does not accumulate into a false trigger.
