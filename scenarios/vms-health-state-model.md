---
feature_id: FEAT-084
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Health State Model (Online/Cloud-Unreachable/NVR-Unreachable/Offline)

Covers the fleet-operator-facing side of FEAT-084: the VMS distinguishing local-online,
cloud-unreachable, NVR-unreachable, and fully-offline states across many cameras.

## Scenario: Fleet grid shows a mix of health states at a glance

**Scenario ID:** SCN-317
**Feature ID:** FEAT-084

**Persona:** Dana, an operator viewing the camera grid for a 40-camera office deployment.

1. Dana's grid shows most tiles with a plain "Online" badge, but two tiles show distinct badges:
   one "NVR-Unreachable" (the VMS itself can't reach that camera even though it may be fine
   locally) and one "Cloud-Unreachable."
2. She can filter the grid to show only cameras not in a fully-healthy state, instead of scanning
   all 40 manually.
3. Clicking a flagged tile shows the specific state and how long it's persisted.

**What the user expects:** at fleet scale, she needs to instantly separate "everything's fine"
from "these specific N cameras need attention," and know which *kind* of problem each one has.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display each camera's health state using the same
  online/cloud-unreachable/NVR-unreachable/offline model, distinctly badged per tile in the
  fleet grid.
- **[vms]** The VMS shall provide a filter/view that shows only cameras not in a fully-healthy
  state, with each flagged camera showing its specific state and its duration.
- **[camera-firmware]** The camera shall report its health state to both the cloud and, where
  applicable, a local NVR/VMS connection independently, so a state like "NVR-unreachable" can be
  distinguished from "cloud-unreachable."

## Scenario: NVR-unreachable while the camera is otherwise fine

**Scenario ID:** SCN-318
**Feature ID:** FEAT-084

**Persona:** Dana's on-prem VMS server loses its LAN route to one camera (e.g. a switch port
issue), while that camera's cloud connection and recording continue normally.

1. The VMS marks that single camera "NVR-Unreachable" rather than lumping it in with cameras
   that are actually fully offline.
2. Dana can still confirm via the app (cloud path) that the camera is online and recording —
   the VMS entry itself notes that cloud-side signals suggest the camera is otherwise healthy,
   so she knows to check her local network path first, not the camera itself.
3. Once the network path is fixed, the tile automatically reverts to "Online" in the VMS.

**What the user expects:** when only the VMS's own local reachability is the problem, the system
should say so specifically, so she doesn't waste a truck-roll on the camera when the fault is
her network infrastructure.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall distinguish "NVR-unreachable" (its own local connection to the camera
  is down) from "offline" (camera unreachable by any path) and from "cloud-unreachable," so an
  operator can localize the fault correctly.
- **[vms]** The VMS shall cross-reference cloud-reported health for an NVR-unreachable camera
  where available, and surface a hint (e.g. "camera appears online via cloud") to help the
  operator distinguish a local-network fault from a camera fault.
- **[cloud-components]** The cloud health service shall expose a camera's last-known cloud-side
  reachability to the VMS so it can be correlated against the VMS's own local reachability
  check.

## Scenario: Conflicting signals — cloud says online, local NVR says offline

**Scenario ID:** SCN-319
**Feature ID:** FEAT-084

**Persona:** Dana notices one camera's VMS tile says "Offline" while its cloud-reported state
(visible via a support dashboard) claims online — a genuine state-source disagreement rather
than a real fault.

1. The VMS doesn't silently pick one source and hide the discrepancy; it shows the conflicting
   signals explicitly rather than guessing.
2. Dana can see both the VMS's own last-successful-local-check time and the cloud's
   last-successful-heartbeat time, so she can judge which is more likely stale.
3. She can manually trigger a fresh local health check from the VMS to resolve the ambiguity
   immediately rather than waiting for the next scheduled poll.

**What the user expects:** when two sources of truth disagree, the system tells her that plainly
instead of confidently reporting a single state that might be wrong — and gives her a way to
force a fresh check.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall surface both its own local reachability signal and the cloud-reported
  reachability signal for a camera when they disagree, rather than silently resolving to a
  single state.
- **[vms]** The VMS shall provide a manual "recheck now" action for a camera's health state that
  bypasses the normal polling interval.
- **[camera-firmware]** The camera shall respond to an on-demand health-check request from the
  VMS with its current state, independent of its normal periodic heartbeat cadence.
