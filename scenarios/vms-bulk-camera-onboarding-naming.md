---
feature_id: FEAT-167
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Bulk Camera Onboarding & Naming

Covers FEAT-167: select and add multiple discovered cameras together in one batch action, with
an efficient bulk-naming workflow, for community/office deployments installing many cameras at
once.

## Scenario: Operator adds multiple discovered cameras in one batch action

**Scenario ID:** SCN-596
**Feature ID:** FEAT-167

**Persona:** Marcus, setting up eight cameras at a new community clubhouse in one visit.

1. Marcus opens the discovery screen and sees all eight newly installed cameras listed.
2. Instead of adding them one at a time, he selects all eight and taps "Add in Batches."
3. The VMS pairs and configures all eight cameras together, showing progress for the whole
   batch.
4. Within moments, all eight appear in his camera list, added and functional.

**What the user expects:** onboarding a large number of cameras at once shouldn't require
repeating the same single-camera flow eight separate times.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator select multiple discovered cameras and add them
  together in a single batch action.
- **[vms]** The VMS shall show per-camera progress/status during a batch add operation.

## Scenario: One camera in a batch fails while the rest succeed

**Scenario ID:** SCN-597
**Feature ID:** FEAT-167

**Persona:** Marcus, whose eighth camera has a flaky network connection during the batch add.

1. Marcus batch-adds all eight cameras as before.
2. Seven succeed normally; the eighth fails partway through (e.g. it drops off the network
   mid-pairing).
3. The VMS clearly reports which specific camera failed and why, while confirming the other
   seven were added successfully — it doesn't roll back the whole batch or leave Marcus
   guessing which one didn't make it.
4. Marcus retries just the failed camera once its connection is stable, without re-adding the
   other seven.

**What the user expects:** one bad camera in a big batch doesn't derail the whole onboarding
effort or hide which one needs attention.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall report per-camera success/failure results at the end of a batch add
  operation, rather than an all-or-nothing outcome.
- **[vms]** The VMS shall allow retrying only the failed camera(s) from a batch, without
  re-processing the ones that already succeeded.

## Scenario: Efficient bulk naming for a large batch of cameras

**Scenario ID:** SCN-598
**Feature ID:** FEAT-167

**Persona:** Marcus, needing to give all eight newly added clubhouse cameras sensible names
quickly (e.g. "Clubhouse - Lobby," "Clubhouse - Pool") rather than one at a time.

1. After the batch add, Marcus opens a bulk-naming view listing all eight newly added cameras
   together.
2. He applies a naming template (e.g. a common prefix "Clubhouse -" plus a location suffix he
   picks per camera from a short list, or sequential numbering) rather than typing each full
   name from scratch.
3. He reviews the resulting name list in one screen and confirms it, renaming all eight cameras
   in one action.

**What the user expects:** naming a large batch of cameras is a fast, templated bulk operation,
not eight separate rename dialogs.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a bulk-naming workflow for a batch of newly added cameras,
  supporting a shared naming template (e.g. common prefix plus per-camera suffix) rather than
  requiring individual rename actions.
</content>
