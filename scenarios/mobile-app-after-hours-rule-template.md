---
feature_id: FEAT-069
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md]
---

# Scenario: Mobile App — After-Hours Activity Rule Template

Covers the homeowner-facing side of FEAT-069: a pre-built rule template combining schedule +
person/vehicle class filter + zone, for common after-hours alerting.

## Scenario: Homeowner enables the after-hours template in a few taps

**Scenario ID:** SCN-243
**Feature ID:** FEAT-069

**Persona:** Elena, a new camera owner who wants "alert me if someone's in the backyard at
night" without manually configuring schedule, class filter, and zone separately.

1. Elena opens "Rule Templates" and selects "After-Hours Activity."
2. The app walks her through drawing (or picking an existing) zone and confirms sensible
   defaults are already filled in: schedule set to a typical overnight window, class filter set
   to Person + Vehicle.
3. Elena taps "Enable" and the rule is active immediately, with all three pieces (schedule,
   class filter, zone) already configured.

**What the user expects:** she gets a working, sensible after-hours rule in a couple of taps,
without needing to understand that it's actually three separate configurable pieces underneath.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer an "After-Hours Activity" rule template that pre-fills a
  sensible default schedule and a Person+Vehicle class filter, requiring the user only to
  select/draw the zone before enabling it.
- **[camera-firmware]** The camera shall accept and evaluate a template-created rule exactly as
  it would any manually-assembled rule with the same schedule, class filter, and zone —
  the template is a client-side authoring convenience, not a distinct rule type on-device.

## Scenario: Customizing the template's default hours

**Scenario ID:** SCN-244
**Feature ID:** FEAT-069

**Persona:** Elena, who works night shifts and wants her "after-hours" window to actually be
daytime, when her house is normally empty.

1. After creating the template-based rule, Elena opens its schedule and edits the default
   overnight window to a daytime range matching her actual absence hours.
2. The app saves this as a normal schedule edit on the rule — the same schedule control any
   manually-built rule uses.
3. The rule now fires during her chosen daytime window instead of the template's original
   overnight default.

**What the user expects:** the template is just a fast starting point, not a fixed, uneditable
package — she can adjust any of its pieces afterward like any other rule.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user edit any individual piece (schedule, class filter,
  zone) of a template-created rule after creation, using the same editing controls as a
  manually-built rule, with no special template-locked state.
