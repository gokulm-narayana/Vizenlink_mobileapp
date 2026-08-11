---
feature_id: FEAT-069
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md]
---

# Scenario: VMS — After-Hours Activity Rule Template

Covers the fleet-operator side of FEAT-069: rolling out the after-hours template across many
cameras at once, and resolving a conflict with an existing custom rule.

## Scenario: Operator rolls out the template across multiple cameras at once

**Scenario ID:** SCN-245
**Feature ID:** FEAT-069

**Persona:** Dana, setting up after-hours alerting for a newly-onboarded community with 10
cameras covering common walkways, all needing the same basic after-hours behavior.

1. Dana selects all 10 cameras in the VMS and applies the "After-Hours Activity" template in one
   action.
2. For each camera, the VMS still requires Dana to confirm (or quickly adjust) that camera's
   zone, since a zone can't be sensibly auto-drawn — but the schedule and class filter defaults
   apply immediately across all 10.
3. Within a few minutes, all 10 cameras have a working after-hours rule instead of Dana
   configuring each one from scratch.

**What the user expects:** the template saves her from repeating the same schedule/class-filter
setup 10 times, while still making her deliberately confirm the one piece (zone) that
legitimately differs per camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator apply the "After-Hours Activity" template to multiple
  selected cameras in a single bulk action, pre-filling schedule and class filter defaults on
  each while still requiring an explicit zone confirmation/drawing per camera.

## Scenario: Template rule conflicts with an existing custom rule on the same zone

**Scenario ID:** SCN-246
**Feature ID:** FEAT-069

**Persona:** Dana, applying the after-hours template to a camera that already has a manually-built
rule covering the same walkway zone with a different class filter.

1. Dana applies the template to that camera and selects the existing "Walkway" zone.
2. The VMS detects that another active rule already references this zone and flags the overlap,
   showing both rules' configurations side by side rather than silently creating a duplicate.
3. Dana decides to keep both (they serve genuinely different purposes) and confirms, with both
   rules now active on the same zone.

**What the user expects:** the VMS proactively surfaces that she's about to layer a new rule
onto a zone that already has one, so she can make an informed choice instead of ending up with
redundant or conflicting rules by accident.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect and surface, before finalizing a template-created rule, any
  existing rule already referencing the same zone, presenting both configurations for the
  operator to compare before confirming.
