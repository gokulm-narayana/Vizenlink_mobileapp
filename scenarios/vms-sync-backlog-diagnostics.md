---
feature_id: FEAT-109
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Sync Backlog Diagnostics (Admin/Support)

Covers FEAT-109: exposing oldest-unsynced-event age, queue size, and storage pressure to
admin/support roles. VMS-only — this is an explicitly admin/support-scoped diagnostic surface,
not a homeowner-facing mobile app view (a homeowner sees sync state per-event via FEAT-101, not
this aggregate diagnostic).

## Scenario: Support engineer diagnoses a customer's "my events are always late" complaint

**Scenario ID:** SCN-399
**Feature ID:** FEAT-109

**Persona:** A support engineer investigating a customer complaint that events consistently
appear an hour or more late.

1. The engineer opens the sync backlog diagnostics for that specific camera and immediately sees
   the oldest-unsynced-event age is currently 58 minutes, plus the current local queue size and a
   storage-pressure indicator, rather than having to reconstruct this from raw logs.
2. The combination (large queue + no reported storage pressure) points them toward a bandwidth/
   connectivity bottleneck rather than a storage or software fault.
3. They resolve it by identifying the camera's WiFi signal is weak (cross-referencing FEAT-096),
   closing the loop on the customer's complaint with a concrete root cause.

**What the user expects:** a support engineer can get straight to root cause using a few
concrete diagnostic numbers, instead of digging through raw device logs for each complaint.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose, per camera, to admin/support roles: the age of the oldest
  currently-unsynced event, the current local sync-queue size, and a storage-pressure indicator,
  in a dedicated diagnostics view.
- **[camera-firmware]** The camera shall report its current unsynced-event queue size, the age
  of its oldest unsynced item, and current storage-pressure level on request, for admin/support
  diagnostic use.

## Scenario: Admin monitors backlog diagnostics across the fleet to catch a brewing problem early

**Scenario ID:** SCN-400
**Feature ID:** FEAT-109

**Persona:** An admin proactively reviewing fleet-wide sync-backlog diagnostics rather than
waiting for individual complaints.

1. The admin sorts the fleet-wide diagnostics view by oldest-unsynced-event age and spots three
   cameras trending upward over the past several days, well before any of them would have
   triggered a customer complaint.
2. Cross-referencing storage pressure for those three, the admin sees all three are also
   nearing local storage capacity, suggesting a shared root cause (e.g. a recent event-rate
   increase outpacing upload bandwidth) rather than three coincidental complaints.
3. The admin proactively reaches out to schedule bandwidth/storage remediation before any
   customer notices delayed events.

**What the user expects:** backlog diagnostics are useful proactively across the whole fleet,
not just reactively per individual support ticket — trends should be visible before they become
customer-facing problems.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-wide, sortable view of sync backlog diagnostics
  (oldest-unsynced-event age, queue size, storage pressure) across all cameras, to admin/support
  roles, to support proactive trend monitoring rather than only per-camera reactive lookup.
