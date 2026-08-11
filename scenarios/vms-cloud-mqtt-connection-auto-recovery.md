---
feature_id: FEAT-111
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: VMS — Cloud/MQTT Connection Auto-Recovery

Covers the fleet-operator-facing side of FEAT-111: cloud/MQTT reconnection across a
multi-camera fleet without manual per-camera intervention.

## Scenario: Fleet-wide MQTT blip recovers without any operator action

**Scenario ID:** SCN-403
**Feature ID:** FEAT-111

**Persona:** Dana, an operator, notices a brief moment where many cameras' tiles flicker to
"cloud-unreachable" during a transient AWS IoT regional blip, then recover.

1. Dana watches the fleet grid and sees the affected cameras' tiles automatically revert to
   "Online" within a couple of minutes, without her needing to restart, reconnect, or otherwise
   intervene on any of them.
2. The VMS's own alert feed logs the blip and recovery per camera, so she has a record even
   though no action was required from her.
3. She confirms remote live-view and control work normally again on a couple of spot-checked
   cameras, closing out the non-event.

**What the user expects:** at fleet scale, a transient cloud blip resolving itself shouldn't
require her to do anything to any camera individually — full automatic recovery, with a record
kept for reference.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall reflect automatic cloud-connection recovery across all affected
  cameras without requiring any per-camera operator action, and shall log each camera's
  disconnect/reconnect in its history.
- **[cloud-components]** The MQTT/cloud layer shall handle reconnection for many cameras
  concurrently after a shared connectivity blip, without requiring serialized or
  operator-triggered reconnection per device.

## Scenario: One camera in the fleet fails to auto-recover after a blip that resolved for the rest

**Scenario ID:** SCN-404
**Feature ID:** FEAT-111

**Persona:** Dana notices that after a fleet-wide blip, 39 of 40 cameras recovered automatically
but one camera's tile is stuck showing "cloud-unreachable" well past when the others recovered.

1. The VMS flags this one camera distinctly (e.g. "cloud-unreachable — longer than expected")
   once its downtime exceeds what the rest of the fleet needed to recover, rather than treating
   it identically to the transient blip that resolved for everyone else.
2. Dana investigates that specific camera and finds a local issue (e.g. its own network path)
   independent of the broader blip, since the fleet-wide event itself has clearly already
   resolved elsewhere.
3. She can trigger a manual restart (per FEAT-098) on just that one camera rather than waiting
   indefinitely for auto-recovery that isn't happening.

**What the user expects:** the VMS distinguishes a camera that's still stuck after everyone else
recovered from the still-resolving shared blip, so she knows exactly which single camera needs
her direct attention.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall flag a camera whose cloud-unreachable duration significantly exceeds
  its fleet peers' recovery time from the same shared connectivity event, distinguishing an
  isolated stuck camera from an ongoing shared outage.
