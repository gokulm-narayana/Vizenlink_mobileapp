---
feature_id: FEAT-095
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Predictive Failure Trend Analysis

Covers the fleet-operator-facing side of FEAT-095: proactive, fleet-wide failure-trend warnings
that support planned maintenance instead of reactive break-fix.

## Scenario: Operator plans a proactive SD-card replacement round from fleet trend data

**Scenario ID:** SCN-353
**Feature ID:** FEAT-095

**Persona:** Dana, an operator managing 50 cameras, wants to get ahead of storage failures rather
than reacting to them one at a time.

1. Dana opens a fleet-wide predictive-health view that ranks cameras by estimated
   time-to-failure for storage wear, showing the six most at-risk cameras with estimates ranging
   from "1 week" to "6 weeks."
2. She schedules a single proactive maintenance round covering all six before any of them
   actually fail, rather than waiting for six separate reactive failure tickets.
3. As each card is replaced, that camera drops off the at-risk list and its trend resets.

**What the user expects:** predictive data lets her run efficient, planned maintenance instead of
firefighting failures after they've already interrupted recording.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-wide view ranking cameras by estimated
  time-to-failure for tracked degradation trends (storage wear, image quality), to support
  proactive maintenance scheduling.
- **[vms]** The VMS shall remove a camera from the at-risk ranking and reset its trend once the
  underlying component (e.g. storage) has been replaced/serviced.

## Scenario: Predictive model flags a false-positive trend after a firmware update

**Scenario ID:** SCN-354
**Feature ID:** FEAT-095

**Persona:** Dana notices a sudden spike of cameras appearing on the at-risk list right after a
firmware update, which she suspects is a measurement artifact rather than genuine accelerated
wear.

1. Dana cross-references the timing of the spike against the fleet's firmware-version telemetry
   (FEAT-088) and confirms all newly-flagged cameras updated to the same new firmware version at
   the same time.
2. She reports this correlation, and rather than dispatching unnecessary maintenance across the
   whole flagged batch, she flags the trend data itself as suspect pending investigation of the
   new firmware's wear-measurement logic.
3. The VMS lets her mark the affected predictions as "under review" so they don't drive false
   maintenance dispatches while the root cause is investigated, without deleting the underlying
   data.

**What the user expects:** she has enough correlating data (firmware version, fleet-wide timing)
to recognize a predictive-model artifact instead of blindly dispatching maintenance on a
false-positive spike, and a way to pause action on suspect predictions without losing the data.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator cross-reference the fleet-wide predictive-warning list
  against other fleet telemetry (e.g. firmware version) to identify correlated, potentially
  false-positive trends.
- **[vms]** The VMS shall let an operator mark a set of predictive warnings as "under review,"
  suppressing maintenance-dispatch prompts for them without deleting the underlying trend data.
