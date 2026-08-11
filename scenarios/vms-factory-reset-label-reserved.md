---
feature_id: FEAT-161
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — "Factory Reset" Label Reserved for Destructive Reset Only

Covers the VMS side of FEAT-161: the term "Factory Reset" is never applied to a lesser action —
only to the fully destructive, ownership-clearing reset.

## Scenario: VMS distinguishes a camera restart from a factory reset in its own controls

**Scenario ID:** SCN-580
**Feature ID:** FEAT-161

**Persona:** Jamie, a Security Operator, needing to restart an unresponsive camera during a
shift.

1. Jamie selects the camera and finds a "Restart" action clearly separate from any destructive
   option — restart isn't even offered near a reset control that Jamie's role wouldn't be
   authorized to use anyway.
2. An admin, separately, has access to a "Factory Reset" action for that camera, worded and
   warned distinctly as the fully destructive option.
3. Neither Jamie's restart nor any lesser maintenance action is ever labeled "Factory Reset"
   anywhere in the VMS.

**What the user expects:** operators doing routine maintenance are never one misclick away
from a destructive action mislabeled as something routine.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall label every lesser maintenance action (restart, reboot, network
  reset) with wording distinct from "Factory Reset," and restrict the true Factory Reset action
  to authorized admin roles only.

## Scenario: Bulk factory reset attempt gets an extra confirmation guard

**Scenario ID:** SCN-581
**Feature ID:** FEAT-161

**Persona:** Farid, decommissioning a batch of cameras from a site being shut down, selecting
several cameras at once for reset.

1. Farid selects five cameras in the VMS and chooses "Factory Reset" as a bulk action.
2. Because this is a bulk destructive action affecting multiple devices at once, the VMS shows
   an extra confirmation step listing exactly which five cameras will be wiped, requiring Farid
   to explicitly confirm the count and device list before proceeding.
3. Only after that explicit confirmation does the reset proceed across all five cameras.

**What the user expects:** the risk of accidentally wiping the wrong (or too many) devices in
a bulk action is caught by an extra, specific confirmation step, not just the same single
warning used for a single camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall require an additional, explicit confirmation step for a bulk Factory
  Reset action, listing the specific devices affected, beyond the confirmation required for a
  single-camera reset.
</content>
