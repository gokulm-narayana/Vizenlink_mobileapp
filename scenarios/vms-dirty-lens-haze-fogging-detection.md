---
feature_id: FEAT-090
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Dirty Lens/Haze/Fogging Detection

Covers the fleet-operator-facing side of FEAT-090: surfacing gradual lens degradation across a
multi-camera site, where a maintenance schedule can act on the signal.

## Scenario: Operator schedules a lens-cleaning maintenance round from fleet-wide haze alerts

**Scenario ID:** SCN-342
**Feature ID:** FEAT-090

**Persona:** Dana, an operator responsible for a community's outdoor cameras, uses the VMS to
plan quarterly maintenance visits.

1. Dana filters the fleet alert feed to "lens/haze" conditions and sees six cameras flagged with
   gradually accumulated haze, each showing how long the condition has been building.
2. She batches all six into a single maintenance round for the on-site technician, rather than
   discovering them one at a time as individual complaints arrive.
3. As the technician clears each camera's lens, the VMS marks each one resolved individually as
   its image clarity is confirmed restored.

**What the user expects:** gradual, low-urgency degradation across a fleet is visible in
aggregate, letting her batch routine maintenance efficiently rather than reacting camera by
camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator filter/list all cameras with an active haze/fogging
  condition fleet-wide, each showing condition duration, to support batched maintenance
  planning.
- **[vms]** The VMS shall mark each camera's haze condition resolved independently as its own
  image clarity is confirmed restored, not as a batch action tied to the maintenance round.

## Scenario: A haze alert is dismissed as false during a maintenance visit, then reappears

**Scenario ID:** SCN-343
**Feature ID:** FEAT-090

**Persona:** Dana's technician inspects a flagged camera, finds the lens visually clean, and
suspects the alert was a false positive from unusual weather rather than an actual dirty lens.

1. The technician (or Dana) can dismiss the alert with a note ("inspected, lens clean, likely
   weather") rather than only "resolve," so the VMS's history distinguishes a confirmed-cleaned
   resolution from a dismissed-as-false one.
2. A few days later the same camera trips the haze alert again. Because the earlier entry was
   marked dismissed-as-false rather than cleaned, Dana can see this isn't the "same issue
   recurring after being fixed" — it's a genuinely unresolved or intermittent condition worth
   escalating differently (e.g. sensor recalibration rather than another cleaning visit).
3. Dana escalates it as a possible sensor/firmware issue instead of dispatching another routine
   cleaning visit.

**What the user expects:** the maintenance history distinguishes "we cleaned it and it was
confirmed fixed" from "we checked and found nothing to clean," so a recurrence is diagnosed
correctly instead of repeating the same ineffective response.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator/technician record a haze/fogging alert's resolution as
  either "cleaned and confirmed clear" or "inspected, no issue found / dismissed as false,"
  distinctly, in the camera's maintenance history.
- **[vms]** The VMS shall surface a camera's prior dismissal reason when the same condition
  recurs, so an operator can distinguish a recurrence after a confirmed fix from a repeat of an
  unresolved/false-flagged condition.
