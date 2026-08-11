---
feature_id: FEAT-028
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-security-rules-engine.md]
---

# Scenario: VMS — Rule-Driven Automatic Buzzer Alert Channel

Covers the fleet-operator-facing side of FEAT-028 (Rule-Driven Automatic Buzzer Alert Channel):
configuring the buzzer as an automatic alert channel per detection rule across a site's cameras
from the VMS.

## Scenario: Admin configures buzzer response for a restricted-zone rule across several cameras

**Scenario ID:** SCN-083
**Feature ID:** FEAT-028

**Persona:** Marcus is setting up a community site's after-hours restricted-zone detection rule
and wants any camera covering that zone to sound its buzzer automatically when the rule fires, in
addition to the operator alert already configured.

1. Marcus opens the rule's configuration in the VMS and enables the buzzer as an alert channel for
   each camera the rule applies to.
2. He saves, and the VMS confirms the buzzer channel is active for this rule on each selected
   camera.
3. When the rule fires overnight, the relevant camera's buzzer sounds automatically and the VMS
   logs it as a rule-triggered buzzer event, distinct from an operator's manual buzzer trigger.

**What the user expects:** buzzer response can be configured as part of the same rule-authoring
workflow he already uses for other alert channels, across however many cameras the rule covers.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall offer the buzzer as a configurable per-rule, per-camera alert channel
  within its rule-authoring interface, alongside existing alert channels.
- **[vms]** The VMS activity log shall record a rule-triggered buzzer event distinctly from an
  operator-triggered one, per camera.
- **[camera-firmware]** The camera shall sound the buzzer automatically upon a rule condition
  match when the buzzer channel is enabled for that rule, applying the standard bounded-duration
  auto-stop behavior.

## Scenario: Reviewing which rules currently have the buzzer channel enabled, site-wide

**Scenario ID:** SCN-084
**Feature ID:** FEAT-028

**Persona:** Marcus wants to audit, across the whole site, which rules currently have the buzzer
enabled, to make sure residents weren't surprised by an unexpected buzzer configured by a prior
operator.

1. Marcus opens the rules overview and filters for rules with the buzzer channel active.
2. He reviews the list, finds one rule with buzzer enabled that shouldn't be (a testing rule left
   over from commissioning), and disables the buzzer channel on it.

**What the user expects:** auditing buzzer-enabled rules across a whole site is a single filtered
view, not a manual walk through every rule.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow filtering the site's rules by which alert channels (including
  buzzer) are currently enabled, so an operator can audit buzzer-enabled rules without inspecting
  each rule individually.
