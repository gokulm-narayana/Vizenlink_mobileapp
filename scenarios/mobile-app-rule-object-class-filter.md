---
feature_id: FEAT-066
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md]
---

# Scenario: Mobile App — Rule Filtering by Object Class

Covers the homeowner-facing side of FEAT-066: scoping a security rule to specific object classes
so nuisance alerts (e.g. pets) don't trigger it.

## Scenario: Homeowner scopes a driveway rule to vehicles only

**Scenario ID:** SCN-230
**Feature ID:** FEAT-066

**Persona:** Marcus, whose driveway zone rule used to alert on his cat as well as arriving cars.

1. Marcus opens the driveway rule's settings and finds an object-class filter, currently set to
   "Any."
2. He changes it to "Vehicle" only and saves.
3. From then on, the cat crossing the driveway produces no alert, while a car pulling in still
   triggers the rule normally.

**What the user expects:** he can narrow a rule down to just the class of object he actually
cares about, without having to build a whole new rule or accept nuisance alerts as the cost of
having the driveway rule at all.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an authorized user scope a rule to one or more specific
  object classes (person, vehicle, animal, package) via an explicit class filter on the rule,
  editable independently of the rule's zone/schedule.
- **[camera-firmware]** The camera shall evaluate a rule's trigger condition only against
  detections whose classified object class matches the rule's configured class filter, treating
  a non-matching detection as if it never occurred for that rule.

## Scenario: Rule left with no class filter falls back to "any object"

**Scenario ID:** SCN-231
**Feature ID:** FEAT-066

**Persona:** Marcus, setting up a brand-new rule on a side-yard zone where he genuinely wants to
know about anything at all entering — person, animal, or otherwise.

1. Marcus creates the rule and leaves the class filter at its default, unset state.
2. The app makes clear that "no filter selected" means the rule triggers on any detected
   object class, not that the rule is broken or incomplete.
3. Any detection type entering that zone — person, vehicle, animal, or package — triggers the
   rule as expected.

**What the user expects:** he isn't forced to explicitly select every class just to get the
same behavior as "no filter" — an unfiltered rule is a legitimate, clearly-labeled choice, not
an error state.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall clearly label a rule with no class filter selected as
  "Any object class," distinct visually from a rule scoped to specific classes, so the user
  can tell at a glance which rules are broad vs. narrowed.
- **[camera-firmware]** The camera shall treat a rule with no configured class filter as
  matching every detected object class, requiring no special-case handling by the client.
