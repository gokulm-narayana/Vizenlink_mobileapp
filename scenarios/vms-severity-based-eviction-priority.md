---
feature_id: FEAT-105
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Severity-Based Eviction Priority

Covers the fleet-operator-facing side of FEAT-105: confirming severity-based retention held
across a multi-camera site during an outage.

## Scenario: Operator confirms high-priority evidence was protected fleet-wide after an outage

**Scenario ID:** SCN-389
**Feature ID:** FEAT-105

**Persona:** Dana, an operator, reviews site-wide impact after a multi-hour outage that caused
several cameras' queues to fill.

1. Dana's post-incident report (per FEAT-104) breaks down, per affected camera, which severity
   tier of events was dropped — confirming that across the fleet, only routine/low-priority
   events were lost while all detected person/vehicle events survived.
2. This gives her confidence to report to stakeholders that no significant security evidence was
   lost during the outage, backed by the severity-tier breakdown rather than a blanket assurance.
3. For the one camera where even high-priority events were affected (an unusually busy one), the
   report calls that out distinctly so she can follow up specifically on that camera.

**What the user expects:** she can confidently report on evidence-loss severity across the whole
fleet after an incident, camera by camera, rather than a single fleet-wide guess.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS's post-incident/queue-full report shall break down dropped events by
  severity tier per camera, so an operator can confirm whether only low-priority events were
  affected or whether high-priority events were also lost at any specific camera.

## Scenario: Operator adjusts severity-priority tiers for a specific deployment's needs

**Scenario ID:** SCN-390
**Feature ID:** FEAT-105

**Persona:** Dana manages a retail site where package-theft evidence at the entrance matters more
than general loitering detections elsewhere, and wants the eviction priority tuned accordingly.

1. Dana finds a fleet/site-level setting where severity-priority tiers can be reviewed (e.g.
   which detection types count as "high priority" for eviction purposes), consistent with the
   security rules engine's zone/event-type configuration.
2. She adjusts the priority so entrance-zone events are treated as highest priority for retention
   purposes, distinct from the default detection-type-based ordering.
3. She confirms via a subsequent outage report that entrance-zone events were indeed retained
   preferentially under the adjusted policy.

**What the user expects:** the severity-priority ordering isn't a rigid one-size-fits-all rule —
she can tune it to reflect what actually matters most for her specific site, and confirm the
adjustment took effect.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator review and adjust which event types/zones are treated
  as higher-priority for local-queue eviction purposes, at the site or fleet level.
- **[camera-firmware]** The camera shall apply an operator-configured severity-priority ordering
  for local-queue eviction, rather than only a fixed built-in default.
