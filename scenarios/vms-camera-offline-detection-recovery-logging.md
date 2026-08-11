---
feature_id: FEAT-085
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Camera Offline Detection & Recovery-Time Logging

Covers the fleet-operator-facing side of FEAT-085: tracking offline durations and recovery times
across a multi-camera site.

## Scenario: Operator reviews an outage after the fact

**Scenario ID:** SCN-322
**Feature ID:** FEAT-085

**Persona:** Dana, an operator investigating a tenant complaint that "the lobby camera was down
yesterday."

1. Dana opens that camera's health history in the VMS and finds a logged entry: offline from
   14:02 to 14:49 the previous day, with the recovery timestamp recorded.
2. The entry lets her cross-reference against her building's known power-maintenance window,
   confirming the cause without needing to ask IT to dig through raw logs.
3. She exports or shares that single entry as evidence in her response to the tenant.

**What the user expects:** she can answer "was it down, and for how long" for any camera,
after the fact, without having had to be watching live when it happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall maintain a per-camera offline-event history (start time, recovery
  time, duration) queryable after the fact, independent of whether an operator was actively
  monitoring when the outage occurred.
- **[vms]** The VMS shall support exporting or copying a single offline-event record for
  external reference (e.g. a tenant/support response).

## Scenario: Multiple cameras at one site go offline simultaneously

**Scenario ID:** SCN-323
**Feature ID:** FEAT-085

**Persona:** Dana's site loses its uplink entirely, taking all 12 cameras at that location
offline at once.

1. Rather than 12 separate, disconnected alerts, the VMS groups the simultaneous outage under
   the shared site, showing "12 cameras offline at Site: Main Office" as a single summarized
   event, with each camera's individual record still available underneath.
2. As cameras reconnect at slightly different times once the uplink is restored, the VMS updates
   each camera's individual recovery timestamp independently rather than closing the whole group
   at once.
3. Dana can see, per camera, exactly when it personally came back, useful if one camera takes
   noticeably longer to recover than its site-mates.

**What the user expects:** a site-wide outage is presented as the single event it actually is,
without losing the ability to see each camera's own precise recovery time underneath.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect when multiple cameras at the same site go offline within a
  short window and present it as a summarized site-level event, while retaining each camera's
  individual offline/recovery timestamps.
- **[vms]** The VMS shall update each affected camera's recovery timestamp independently as it
  individually reconnects, rather than requiring all cameras in the group to recover before any
  are marked recovered.
