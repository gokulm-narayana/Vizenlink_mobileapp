---
feature_id: FEAT-106
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Dropped/Downgraded Event Accounting

Covers the fleet-operator-facing side of FEAT-106: a fleet-wide accounting of dropped/downgraded
events, useful for post-incident review and SLA reporting.

## Scenario: Operator produces an incident-loss report across the fleet

**Scenario ID:** SCN-393
**Feature ID:** FEAT-106

**Persona:** Dana needs to produce a written report to a client after an extended outage,
accounting for any lost evidence across their contracted cameras.

1. Dana pulls a fleet-wide accounting report for the outage window, broken down per camera:
   events fully dropped, events downgraded (metadata-only), and events fully preserved.
2. The report is precise enough to attach directly to her client communication without needing
   manual reconciliation from raw camera logs.
3. Where a camera had zero loss, the report states that explicitly rather than omitting the
   camera from the report (which could look like an oversight).

**What the user expects:** she can generate an accurate, complete, per-camera accounting of
event loss/downgrade for any incident window, suitable for external reporting, without manual
log-diving.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-wide dropped/downgraded-event accounting report for a
  selectable time window, broken down per camera, including cameras with zero loss stated
  explicitly.
- **[cloud-components]** The cloud ingestion pipeline shall record dropped/downgraded-event
  notices reported by each camera and retain them for later fleet-wide reporting.

## Scenario: Operator distinguishes a downgraded event from a genuinely missing one during review

**Scenario ID:** SCN-394
**Feature ID:** FEAT-106

**Persona:** Dana is reviewing a specific camera's timeline during an investigation and finds an
entry with no clip attached.

1. Dana checks the entry's accounting metadata and confirms it's marked "downgraded — clip
   discarded under storage pressure," not simply a broken/missing entry from a software bug.
2. This distinction matters for her investigation: she now knows to look elsewhere (e.g. other
   cameras' footage of the same time window) rather than assuming a system malfunction that needs
   a bug report.
3. She notes in her investigation log that this specific window has a known evidence gap, citing
   the accounting record as the reason.

**What the user expects:** she can always tell the difference between "this is a known,
accounted-for gap due to storage pressure" and "something might genuinely be broken," so she
handles each correctly during an investigation.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator inspect any event lacking full content and see whether
  it's an accounted-for downgrade (with reason and outage window) versus an unexplained
  gap, to distinguish expected loss from a potential system fault.
