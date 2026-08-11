---
feature_id: FEAT-081
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Rule Recalibration After View Change

Covers the fleet-operator side of FEAT-081: recalibration prompts for a camera moved during
maintenance, and how suspended rules are represented across a multi-camera site.

## Scenario: Operator receives a recalibration prompt after camera maintenance

**Scenario ID:** SCN-278
**Feature ID:** FEAT-081

**Persona:** Dana, whose maintenance crew re-mounts a camera after cleaning it, inadvertently
changing its angle.

1. The camera detects the significant view change against its saved reference and reports it to
   the VMS.
2. The VMS surfaces a clear notice against that specific camera in the site dashboard: rules
   suspended, recalibration required.
3. Dana reviews the camera's rules against its new view, redraws the ones that no longer line
   up, confirms the rest, and the VMS lifts the suspension once every rule on that camera is
   accounted for.

**What the user expects:** a maintenance-caused view change on one camera doesn't silently leave
a security gap — she's told exactly which camera and which rules need her attention.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall surface a per-camera "rules suspended — recalibration required"
  status on its site dashboard whenever that camera reports a significant view change, and
  shall clear the status only once every affected rule has been reviewed/confirmed.

## Scenario: Rules stay suspended until every affected rule is individually confirmed

**Scenario ID:** SCN-279
**Feature ID:** FEAT-081

**Persona:** Dana, working through a camera with four rules affected by a view change, having
already confirmed three of them.

1. Dana confirms the first three rules are still correctly aligned to the new view.
2. The VMS keeps the camera marked "partially recalibrated" and the fourth rule still suspended,
   rather than resuming all rules once most of them are done.
3. Only once Dana confirms/redraws the fourth rule does the VMS clear the camera's suspended
   status entirely.

**What the user expects:** partial progress on recalibration doesn't quietly re-arm rules she
hasn't actually reviewed yet — every one of them individually has to be accounted for.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall keep each individual zone/line rule suspended until
  that specific rule has been recalibrated/confirmed, resuming evaluation rule-by-rule rather
  than all-at-once, so a partially-completed recalibration never silently re-arms an
  unreviewed rule.
