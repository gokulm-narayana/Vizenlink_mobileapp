---
feature_id: FEAT-088
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Device Health Telemetry

Covers the fleet-operator-facing side of FEAT-088: comparing uptime, reboot patterns, and
firmware versions across many cameras.

## Scenario: Operator audits firmware versions across a fleet before a rollout

**Scenario ID:** SCN-334
**Feature ID:** FEAT-088

**Persona:** Dana, an operator planning to push a firmware update, first wants to know what
versions are currently deployed.

1. Dana opens a fleet-wide device-telemetry view listing every camera's current firmware
   version, model, and uptime in a sortable table.
2. She sorts by firmware version and immediately sees which cameras are already current and
   which are behind, without opening each camera individually.
3. She also spots one camera with unusually low uptime relative to its neighbors, prompting her
   to check its reboot history before including it in the rollout.

**What the user expects:** a fleet-wide, sortable view of device telemetry so she can plan
maintenance/rollout work without visiting every camera's page one at a time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-wide, sortable/filterable table of device telemetry
  (uptime, firmware version, model, last-successful-recording timestamp) across all cameras at
  a site.
- **[camera-firmware]** The camera shall report its device telemetry fields on request in a
  format suitable for fleet-wide aggregation, not just single-camera display.

## Scenario: Reboot-pattern alert flags a hardware batch issue

**Scenario ID:** SCN-335
**Feature ID:** FEAT-088

**Persona:** Dana notices several cameras purchased in the same batch all show elevated reboot
counts in the same week, while the rest of the fleet is stable.

1. The VMS's fleet telemetry table highlights each camera with an abnormal reboot pattern with a
   visual flag, so Dana doesn't have to manually compare reboot counts across dozens of rows.
2. She cross-references the flagged cameras' purchase/installation dates (also part of the
   telemetry record) and confirms they share a batch, strengthening her case to escalate to the
   hardware vendor rather than treating each as an unrelated support ticket.
3. She exports the flagged subset's telemetry as a report to attach to her vendor escalation.

**What the user expects:** at fleet scale, a reboot-pattern anomaly should be discoverable as a
cross-camera trend, not just visible one device at a time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall visually flag any camera in the fleet telemetry table whose reboot
  pattern is abnormal relative to its own history, so cross-camera trends are discoverable at a
  glance.
- **[vms]** The VMS shall support exporting a filtered subset of fleet device telemetry (e.g. all
  flagged cameras) as a report for external use (vendor escalation, maintenance record).
