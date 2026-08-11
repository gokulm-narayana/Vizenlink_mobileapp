---
feature_id: FEAT-068
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Zone Entry/Exit/Crossing/Presence Detection

Covers the homeowner-facing side of FEAT-068: choosing the trigger type (entry, exit,
line-crossing, or presence) a rule evaluates against, on top of a drawn zone/line.

## Scenario: Homeowner picks "entry" for the backyard and "presence" for the porch

**Scenario ID:** SCN-239
**Feature ID:** FEAT-068

**Persona:** Marcus, who wants an immediate alert the instant anything enters his backyard, but
wants his porch rule to only fire if someone actually stays there, not just walks past.

1. On the backyard zone's rule, Marcus selects trigger type "Entry."
2. On the porch zone's rule, he selects trigger type "Presence" instead.
3. Someone briefly cutting across the edge of the porch without stopping produces no alert from
   the porch rule (no sustained presence), while a person stepping into the backyard triggers
   the backyard rule the moment they cross in.

**What the user expects:** the same drawn shape can be evaluated in different ways depending on
what he actually wants to know — a single "enters at all" moment vs. "sticks around."

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user select a trigger type (entry, exit, crossing,
  presence) independently on each rule, applied against that rule's associated zone or line.
- **[camera-firmware]** The camera shall evaluate a rule's trigger condition according to its
  configured trigger type — firing on the entry instant, the exit instant, a line-crossing
  event, or continued presence past a threshold — rather than a single fixed interpretation of
  "detected in the zone."

## Scenario: Object exits the zone mid-evaluation

**Scenario ID:** SCN-240
**Feature ID:** FEAT-068

**Persona:** Marcus, whose backyard rule is set to "Exit" (alert when something leaves the
zone, e.g. to catch a pet escaping through a gap in the fence).

1. His dog is already inside the backyard zone when Marcus opens the app; no alert fires yet
   since the dog hasn't exited.
2. The dog later squeezes through a fence gap and leaves the zone boundary.
3. The moment the dog's tracked position crosses out of the zone, the exit rule fires and
   Marcus gets an alert.

**What the user expects:** an "exit" rule only cares about the moment of leaving, not about
mere presence — so it doesn't fire the whole time the dog is safely inside, only when it
actually leaves.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall fire an "exit" trigger only at the moment a tracked
  object's position transitions from inside to outside the zone boundary, not while the object
  remains inside the zone regardless of duration.
- **[mobile-app]** The app shall label an exit-triggered alert distinctly from an
  entry-triggered one in the alert list, so the user can tell which direction of movement
  caused it.
