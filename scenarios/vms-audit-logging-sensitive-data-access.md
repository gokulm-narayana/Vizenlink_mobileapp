---
feature_id: FEAT-192
status: draft
target_fr_docs: [FR-vms.md, FR-security-lifecycle.md, FR-access-control.md]
---

# Scenario: VMS — Audit Logging for Sensitive Data Access/Export

Covers FEAT-192: a fleet operator/admin being able to see who accessed or exported sensitive
footage/data, and when — for accountability, incident review, and compliance.

## Scenario: Reviewing who exported footage after an incident

**Scenario ID:** SCN-634
**Feature ID:** FEAT-192

**Persona:** Raj, a community admin, needs to know who exported footage related to an incident
that later became a legal dispute.

1. Raj opens the Audit Log view in VMS and filters by action type ("Export") and date range.
2. Each entry shows who performed the export (named user, not just a device/session ID), which
   camera/time range was exported, and when the export happened.
3. Raj can drill into a specific entry to see the export's destination (e.g. downloaded locally,
   shared via a link) if applicable.

**What the user expects:** a reliable, attributable record of sensitive footage handling he can
produce for a legal or internal review, not just a vague "activity happened" log.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall log every footage export with the acting user's identity, the
  camera/time-range exported, the timestamp, and the export destination/method.
- **[vms]** The VMS shall let an admin filter/search the audit log by action type, date range,
  and camera.

## Scenario: Cross-camera search and incident-note access are also audited

**Scenario ID:** SCN-635
**Feature ID:** FEAT-192

**Persona:** Raj wants to confirm that a staff member's cross-camera search (searching multiple
residents' cameras at once) and access to an incident note were both properly logged, not just
exports.

1. Raj filters the audit log to include "Cross-camera search" and "Incident note access" action
   types alongside "Export."
2. Each shows the same acting-user attribution and timestamp, plus the scope searched (e.g.
   which cameras/time range a cross-camera search covered).

**What the user expects:** any access to sensitive aggregated or incident-linked data is
recorded with the same rigor as an export, not treated as lower-stakes because nothing left the
system.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall audit-log cross-camera search actions (acting user, scope searched,
  timestamp) and incident-note access, using the same attribution standard as footage exports.

## Scenario: An admin account is used to view the audit log itself, and that's logged too

**Scenario ID:** SCN-636
**Feature ID:** FEAT-192

**Persona:** During an internal review, someone asks whether the audit log itself can be viewed
or altered without a trace.

1. Raj opens the audit log; that access is itself recorded (view of the audit log = a logged
   event), and the log is not editable/deletable from the VMS UI by any role, including admin.
2. If a data-retention rule ever purges old audit entries, that purge is itself logged distinctly
   from ordinary log entries.

**What the user expects:** the audit trail can't be quietly edited or viewed without a trace by
the very people it's meant to hold accountable, preserving its value as a real record.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall not permit any role, including admin, to edit or delete individual
  audit-log entries through the UI; a purge under a retention rule shall itself be logged as a
  distinct event.
- **[vms]** Viewing the audit log shall itself be a logged action.
