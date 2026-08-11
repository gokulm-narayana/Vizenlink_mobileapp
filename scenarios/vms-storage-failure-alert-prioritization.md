---
feature_id: FEAT-123
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Storage-Failure Alert Prioritization

Covers the VMS side of FEAT-123: storage/recording failures must outrank ordinary activity
alerts in the operator alert feed across a fleet.

## Scenario: Storage failure surfaces above routine alerts fleet-wide

**Scenario ID:** SCN-459
**Feature ID:** FEAT-123

**Persona:** Marcus is monitoring the alert feed across six sites when one camera's storage
fails.

1. The storage-failure alert appears at the top of the fleet-wide alert feed, visually distinct
   from routine detection alerts, regardless of which site or how many other alerts have come
   in since.
2. The affected camera's dashboard card also reflects the failure via its health badge (per
   FEAT-114), so the same issue is visible in two places consistently.

**What the user expects:** a storage problem anywhere in the fleet can't get lost among routine
motion alerts from other, unaffected cameras.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The fleet-wide alert feed shall pin storage/recording-failure alerts above routine
  activity alerts regardless of site or camera, with a visually distinct treatment.
- **[vms]** A storage/recording-failure alert shall be reflected consistently in both the alert
  feed and the affected camera's dashboard health badge.

## Scenario: Storage failure alert requires explicit administrator acknowledgment

**Scenario ID:** SCN-460
**Feature ID:** FEAT-123

**Persona:** Diane, the site administrator, needs to track that a storage failure was actually
addressed, not just noticed and ignored.

1. The storage-failure alert requires an explicit "Acknowledge" action from an administrator
   role, recording who acknowledged it and when.
2. Until acknowledged (or the underlying issue resolves on its own), the alert continues to
   surface at the top of the feed on every subsequent login, for every operator with access to
   that site — it isn't cleared just because one operator viewed it.

**What the user expects:** a storage failure creates real operational accountability — it
doesn't disappear just because someone glanced at it once.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** A storage/recording-failure alert shall require an explicit acknowledgment action,
  recording the acknowledging user and timestamp, distinct from merely being viewed.
- **[vms]** An unacknowledged storage-failure alert shall continue to surface at the top of the
  alert feed for every operator with access to the affected site, not just the operator who
  first saw it.
