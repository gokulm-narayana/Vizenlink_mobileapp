---
feature_id: FEAT-094
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Corrective Action Guidance

Covers the fleet-operator-facing side of FEAT-094: recommended corrective actions attached to
health alerts across a multi-camera site, backed by full diagnostic data.

## Scenario: Operator uses guided actions to triage a batch of alerts quickly

**Scenario ID:** SCN-349
**Feature ID:** FEAT-094

**Persona:** Dana, an operator working through a morning backlog of eight open health alerts
across the site.

1. Each alert in Dana's queue shows a one-line recommended action ("clean lens," "check network
   cable at this camera's switch port," "verify power supply") alongside the specific condition,
   letting her batch similar actions (e.g. all the lens-cleaning ones) into one dispatch.
2. She can still open the full diagnostic detail for any alert if the recommended action doesn't
   feel sufficient before she dispatches a technician.
3. As technicians report back, she records which recommended actions actually resolved their
   conditions, building a track record of how reliable that suggestion has been for this class
   of condition.

**What the user expects:** the recommended action makes triage faster across many alerts at
once, without ever hiding the full diagnostic detail she needs for judgment calls.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display a recommended corrective action alongside every health alert
  in the operator's alert queue, without hiding the underlying diagnostic detail, and shall
  support grouping/dispatching similar recommended actions in batch.
- **[vms]** The VMS shall record whether a recommended corrective action, once applied, actually
  resolved the condition, and track this outcome against that action/condition pairing over
  time.

## Scenario: A recommended action proves unreliable for a specific condition type

**Scenario ID:** SCN-350
**Feature ID:** FEAT-094

**Persona:** Dana notices, over several months, that the standard "check network cable"
recommendation for NVR-unreachable alerts on a particular camera model rarely actually resolves
the issue — the real fix is usually a firmware update.

1. The VMS's tracked outcome history (from SCN-349) shows Dana that this recommendation has a
   low resolution rate for that specific camera model/condition pairing.
2. She flags this to whoever curates the recommendation content, and the VMS's guidance for that
   specific model/condition combination is updated to reflect the more effective fix.
3. Future alerts of that type show the updated recommendation, and the outcome-tracking record
   for the old recommendation remains visible in history rather than being erased, so the change
   is auditable.

**What the user expects:** recommended actions aren't static guesses — the system's own
outcome-tracking data can be used to improve them over time, and past guidance stays visible for
audit rather than silently vanishing when updated.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall surface aggregate resolution-rate data for a given recommended
  action/condition pairing, to support identifying when a recommendation is unreliable.
- **[vms]** The VMS shall retain the history of prior recommended-action content for a
  condition type even after the recommendation is updated, so past guidance remains auditable.
