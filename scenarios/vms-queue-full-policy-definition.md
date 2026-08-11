---
feature_id: FEAT-104
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Queue-Full Policy Definition

Covers the fleet-operator-facing side of FEAT-104: understanding and configuring queue-full
behavior across a multi-camera deployment.

## Scenario: Operator reviews the configured queue-full policy across camera models

**Scenario ID:** SCN-385
**Feature ID:** FEAT-104

**Persona:** Dana, an operator responsible for a mixed-hardware site, wants to understand
retention guarantees before signing off on an SLA with a client.

1. Dana opens a fleet-wide settings/reference view showing each camera model's local queue
   capacity and its documented eviction behavior once full — stated explicitly, not implied.
2. She uses this to set accurate client expectations (e.g. "our cameras buffer roughly N hours
   of typical activity offline; during longer outages, lower-priority events may be dropped")
   rather than promising something the hardware can't actually guarantee.
3. If a client asks about worst-case outage duration before data loss, she has a concrete,
   documented number to reference rather than guessing.

**What the user expects:** the actual, concrete retention/eviction policy is available to her as
plain reference data she can use to set honest expectations downstream, not buried in
engineering documentation she can't access.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose each connected camera model's documented local-queue capacity
  and eviction policy in a reference/settings view accessible to the operator.
- **[camera-firmware]** The camera shall report its queue-full policy parameters (capacity,
  eviction behavior) to the VMS/cloud as part of its capability/telemetry reporting.

## Scenario: Operator investigates a queue-full incident across several cameras after a long outage

**Scenario ID:** SCN-386
**Feature ID:** FEAT-104

**Persona:** Dana's site had an extended outage, and she needs to determine which cameras
actually hit their queue limit and lost events, for a post-incident report.

1. Dana pulls up a fleet-wide report listing, per camera, whether its queue reached capacity
   during the outage window and roughly how many events were affected — not just a single
   site-wide yes/no.
2. She uses this to accurately scope her incident report, distinguishing cameras that lost
   nothing from ones that genuinely lost lower-priority events.
3. She attaches this report when communicating with any affected client, backed by concrete
   per-camera data rather than a blanket apology.

**What the user expects:** she can produce an accurate, camera-by-camera accounting of the
consequences of hitting the documented queue-full policy, rather than only a vague acknowledgment
that "some data may have been lost."

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a post-incident report listing, per camera, whether and how
  much its local queue reached capacity and dropped events during a given outage window.
