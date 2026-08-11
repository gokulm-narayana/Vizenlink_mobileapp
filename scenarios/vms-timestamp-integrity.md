---
feature_id: FEAT-008
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Timestamp Integrity (NTP/RTC + Uncertain-Time Flag)

Covers the fleet-operator-facing side of FEAT-008 (Timestamp Integrity): monitoring clock health
across many cameras and being able to trust (or distrust, when flagged) recorded timestamps used
for incident review.

## Scenario: Operator reviews a fleet-wide clock health view

**Scenario ID:** SCN-023
**Feature ID:** FEAT-008

**Persona:** Marcus periodically checks that all cameras at a site have healthy, synchronized
clocks, since evidentiary review across cameras depends on consistent timestamps.

1. Marcus opens the site's camera health/status view in the VMS.
2. Each camera shows its clock sync status (synced via NTP, or running on RTC fallback) alongside
   its other health indicators.
3. All cameras show as synced, so he moves on without further action.

**What the user expects:** clock health is just another line item in the same fleet health view he
already checks, not something he has to dig for separately.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display each camera's clock sync status (NTP-synced vs. RTC fallback vs.
  uncertain) in the site's fleet health view.
- **[camera-firmware]** The camera shall report its current clock sync status via the same status
  channel used for other health telemetry, so the VMS can surface it without a separate query
  mechanism.

## Scenario: One camera's clock goes uncertain and affects an incident review

**Scenario ID:** SCN-024
**Feature ID:** FEAT-008

**Persona:** Marcus is pulling footage across three cameras to reconstruct the order of events
around an incident, and one of those cameras had a prolonged NTP outage during that window.

1. Marcus opens the fleet health view and sees that one camera is flagged with an uncertain-time
   warning covering part of the time range he's investigating.
2. When he pulls that camera's footage for the incident window, the clip is visibly marked as
   having an uncertain timestamp.
3. Because he was warned rather than left to assume the timestamp was reliable, he cross-checks
   that camera's footage against the other two cameras' confirmed timestamps instead of trusting
   its time label at face value.

**What the user expects:** an operator piecing together a timeline across cameras is warned before
he unknowingly relies on a camera's inaccurate clock.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall flag a camera in its fleet health view when it reports an uncertain-time
  condition, and continue showing that flag against affected historical recordings even after the
  camera resyncs.
- **[vms]** The VMS shall visually mark any footage/event pulled from a period during which the
  source camera's uncertain-time flag was active, wherever that footage is reviewed.
