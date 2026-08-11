---
feature_id: FEAT-073
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Line-Crossing Counting

Covers FEAT-073: counting people/vehicles crossing a calibrated line, in each direction, as
exposed through the VMS. Skews toward community/operator-scale deployment per counting's
analytics nature.

## Scenario: Operator views daily in/out counts at an entrance

**Scenario ID:** SCN-259
**Feature ID:** FEAT-073

**Persona:** Dana, tracking daily foot traffic through a community clubhouse's main entrance to
inform staffing decisions.

1. Dana opens the entrance camera's line-crossing counter in the VMS and sees running in/out
   counts for the current day, broken out by direction.
2. She can view a historical daily trend (e.g. past 7 days) rather than only the live running
   total.
3. The counts reset automatically at the start of each new day, with the prior day's total
   preserved in the historical view.

**What the user expects:** she gets a simple, reliable daily in/out count without having to
manually tally anything from footage, and can see how today compares to recent days.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display running in/out crossing counts for a calibrated line, with a
  historical daily trend view, and shall reset the current-day counter at a configurable daily
  boundary while preserving prior totals in history.
- **[camera-firmware]** The camera shall count each line-crossing event by direction (in vs.
  out) and report both the event and its direction to the VMS as it happens.

## Scenario: Recalibrating the count after the line is moved

**Scenario ID:** SCN-260
**Feature ID:** FEAT-073

**Persona:** Dana, who needs to widen the counting line after noticing it was missing crossings
at one edge of a wide entrance.

1. Dana edits the line's position/width in the VMS.
2. The VMS makes clear that the historical count data collected under the old line position is
   preserved as-is (not recalculated retroactively), while counts going forward use the new
   line.
3. The VMS visibly marks the point in the historical trend where the line definition changed, so
   Dana isn't misled comparing before/after numbers as if they used the same calibration.

**What the user expects:** editing the line doesn't silently corrupt or misrepresent past
counts — the history stays honest about what configuration produced it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall annotate its historical count trend at any point where the
  underlying line definition changed, so past and future counts are never presented as directly
  comparable without that context.

## Scenario: Two objects crossing simultaneously are counted correctly

**Scenario ID:** SCN-261
**Feature ID:** FEAT-073

**Persona:** Dana, monitoring an entrance during a busy period where two people walk through the
line side by side at the same moment.

1. Two people cross the line together, side by side, in the same direction.
2. The counter increments by two, one for each individually tracked person, not by one for the
   combined crossing event.
3. If one of the two had been crossing in the opposite direction at the same instant, the
   counter would correctly add one to "in" and one to "out" rather than conflating them.

**What the user expects:** the count reflects the actual number of individuals crossing, even
when several cross at once, not an undercount from treating simultaneous crossings as a single
event.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall count each individually tracked object's line crossing
  independently, even when multiple objects cross at the same or overlapping moments, rather
  than collapsing simultaneous crossings into a single counted event.
