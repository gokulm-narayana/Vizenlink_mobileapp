---
feature_id: FEAT-066
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md]
---

# Scenario: VMS — Rule Filtering by Object Class

Covers the fleet-operator side of FEAT-066: scoping rules to object classes across a
multi-camera site, including a rule that legitimately needs more than one class.

## Scenario: Operator scopes a lobby rule to person class only

**Scenario ID:** SCN-232
**Feature ID:** FEAT-066

**Persona:** Dana, configuring an after-hours lobby rule for a community building where a
service robot occasionally drives through overnight and shouldn't trigger the rule.

1. Dana opens the lobby zone rule and sets its class filter to "Person" only.
2. She saves, and the VMS confirms the filter applies to that rule.
3. Overnight, the service robot's pass-through generates no alert (it's classified as a
   non-person object, if classified at all), while an actual person in the lobby after hours
   still triggers the rule.

**What the user expects:** she can eliminate a known source of nuisance triggers by class,
without disabling the rule or losing real person-detection coverage in the same area.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator scope any rule to one or more specific object classes
  via a class filter, editable per rule, independent of the zone/schedule configuration.
- **[camera-firmware]** The camera shall evaluate a rule's class filter identically regardless
  of which client (mobile app or VMS) configured it, since the filter is stored and applied at
  the camera/rule level.

## Scenario: Rule needs multiple classes for a mixed-traffic site

**Scenario ID:** SCN-233
**Feature ID:** FEAT-066

**Persona:** Dana, configuring a rule for a shared loading area used by both delivery vehicles
and foot traffic, where she wants alerts for either.

1. Dana opens the rule's class filter and selects both "Person" and "Vehicle," leaving
   "Animal" and "Package" unselected.
2. She saves the rule with this two-class filter.
3. Both a delivery van and a person walking through the loading area trigger the rule, while a
   stray dog passing through does not.

**What the user expects:** the class filter isn't limited to a single class — she can combine
exactly the classes relevant to this specific area's real traffic.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS's class filter control shall support selecting more than one object class
  for a single rule, not just a single-class or all-classes choice.
- **[camera-firmware]** The camera shall evaluate a rule's class filter as a match against any
  one of the rule's configured classes (logical OR), triggering on a detection of any included
  class.
