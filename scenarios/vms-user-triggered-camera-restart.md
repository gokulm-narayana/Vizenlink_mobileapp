---
feature_id: FEAT-098
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — User-Triggered Camera Restart with Health Confirmation

Covers the fleet-operator-facing side of FEAT-098: restarting one or more cameras remotely from
the VMS with confirmed health-outcome reporting.

## Scenario: Operator restarts a single misbehaving camera remotely

**Scenario ID:** SCN-365
**Feature ID:** FEAT-098

**Persona:** Dana, an operator, notices one camera's stream has been stuttering and decides to
try a remote restart before dispatching a technician.

1. Dana selects "Restart" on that camera's tile in the VMS, confirms the interruption warning,
   and watches the tile show a "restarting" state.
2. Once the camera reconnects, the VMS reports the outcome directly on that camera's card
   ("Restarted — Healthy") and logs the action (who triggered it, when, and the outcome) in the
   camera's history.
3. Because the restart resolved the stuttering, Dana closes out the issue without needing a
   truck roll.

**What the user expects:** she can attempt a low-cost remote fix first, with the VMS clearly
confirming whether it worked, saving an unnecessary site visit when it does.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a per-camera "Restart" action with confirmation, tracking the
  restart through to reconnection and reporting the resulting health outcome directly on that
  camera's tile/card.
- **[vms]** The VMS shall log every operator-triggered restart (who, when, outcome) in the
  camera's persistent history.

## Scenario: Operator restarts a batch of cameras after a firmware rollout

**Scenario ID:** SCN-366
**Feature ID:** FEAT-098

**Persona:** Dana has just pushed a firmware update to 20 cameras and wants to restart all of
them to apply it, then confirm each came back healthy.

1. Dana selects all 20 cameras and triggers a batch restart, with a single confirmation covering
   the group rather than 20 individual prompts.
2. As each camera reconnects (likely at slightly different times), the VMS updates that
   specific camera's status individually rather than waiting for all 20 before reporting
   anything.
3. At the end, Dana sees a summary: e.g. "18 healthy, 1 still restarting, 1 failed to
   reconnect," letting her immediately identify the one camera that needs individual follow-up
   rather than assuming the whole batch succeeded uniformly.

**What the user expects:** a batch restart is efficient to trigger but still gives her
per-camera visibility into the outcome, so a single failure within the batch doesn't get lost
in an assumed-successful group action.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support triggering a restart across a selected batch of cameras with a
  single confirmation, while tracking and reporting each camera's individual reconnection
  outcome separately.
- **[vms]** The VMS shall present a summary of a batch restart's outcomes (healthy /
  still-restarting / failed) that clearly identifies any camera needing individual follow-up.
