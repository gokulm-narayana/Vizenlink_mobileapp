---
feature_id: FEAT-082
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md]
---

# Scenario: Mobile App — Per-Rule Enable/Disable Toggle

Covers the homeowner-facing side of FEAT-082: turning an individual rule off entirely,
distinct from its schedule and from deleting it.

## Scenario: Homeowner pauses a driveway-vehicle rule while a guest's car is parked

**Scenario ID:** SCN-280
**Feature ID:** FEAT-082

**Persona:** Priya, whose driveway-vehicle rule would otherwise alert her repeatedly while a
guest's unfamiliar car stays parked there for the weekend.

1. Priya opens the driveway rule and taps its enable/disable toggle to "Off."
2. The rule immediately stops evaluating — no further alerts from it — while remaining fully
   configured (zone, schedule, class filter all intact, just inactive).
3. Over the weekend, the guest's car coming and going produces no alerts from this rule, while
   Priya's other rules (e.g. front-door) continue operating normally.

**What the user expects:** she can silence one specific rule for a known reason without losing
its configuration or affecting any of her other rules.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a per-rule enable/disable toggle, independent of the
  rule's schedule configuration, that immediately stops or resumes that rule's evaluation
  without altering any of its other settings.
- **[camera-firmware]** The camera shall skip evaluation entirely for a rule marked disabled,
  regardless of its schedule or trigger conditions, while retaining its full configuration
  unchanged for when it's re-enabled.

## Scenario: Re-enabling a paused rule — toggle vs. schedule vs. delete stay distinct

**Scenario ID:** SCN-281
**Feature ID:** FEAT-082

**Persona:** Priya, whose guest has left and the driveway is back to normal, wanting the rule
active again.

1. Priya reopens the driveway rule and taps the toggle back to "On."
2. The rule resumes evaluating immediately with its original zone, schedule, and class filter
   untouched — she didn't need to reconfigure anything.
3. Reviewing her rules list, Priya can clearly tell apart three distinct states a rule might be
   in: disabled (this toggle), inactive due to its own schedule (e.g. currently outside its
   active hours), and deleted (gone entirely) — the app never conflates any of these three.

**What the user expects:** turning a rule back on is a single action that restores exactly what
was there before, and she's never confused about whether a quiet rule is off, out-of-schedule,
or gone.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall visually distinguish, in the rule list, a manually-disabled
  rule from a rule that is merely outside its active schedule and from a deleted rule, using
  distinct, unambiguous status indicators for each.
