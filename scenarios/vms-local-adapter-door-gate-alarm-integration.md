---
feature_id: FEAT-208
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md]
---

# Scenario: VMS — Local Adapter Integration for Door/Gate/Alarm/Access-Control Events

Covers FEAT-208: an operator configuring VMS to get physical state (door open/closed, alarm
triggered, access granted/denied) directly from the relevant equipment's own signal/API via a
local adapter, rather than inferring it visually from camera footage.

## Scenario: Wiring a door-controller's access events into VMS via a local adapter

**Scenario ID:** SCN-658
**Feature ID:** FEAT-208

**Persona:** Raj's community has an existing electronic door-access system at the main entrance;
he wants VMS to show "access granted"/"access denied" events tied to the entrance camera, sourced
directly from the door controller rather than guessed from video.

1. Raj opens VMS Integrations → Local Adapters and adds the door controller, entering its local
   network address and the adapter type matching that hardware/protocol.
2. VMS confirms it's receiving live state from the door controller (e.g. a "Connected" status and
   a test event when someone badges in).
3. Raj links this adapter's events to the entrance camera, so future access events show up
   correctly labeled and correctly timed alongside that camera's footage in the timeline.

**What the user expects:** access events shown next to the footage are ground truth from the
door system itself, not a visual guess that could misread a badge tap as something else.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support configuring a local adapter to a door/gate/alarm/access-control
  system, and shall confirm live connectivity before the adapter is marked active.
- **[vms]** The VMS shall let an operator link an adapter's event stream to a specific camera so
  its events appear correctly labeled and time-aligned in that camera's event timeline.

## Scenario: The local adapter loses connectivity to the door controller

**Scenario ID:** SCN-659
**Feature ID:** FEAT-208

**Persona:** The door controller's network cable is unplugged during maintenance.

1. VMS shows the adapter as "Disconnected" rather than silently showing stale "last known" state
   as if it were current.
2. VMS does not fabricate or infer access events from camera footage as a fallback while the
   adapter is down — it simply reports no adapter-sourced events during the outage, distinct
   from a period with genuinely no access activity.

**What the user expects:** he can tell the difference between "nothing happened" and "we lost
the ability to know what happened," which matters for any later review of that time window.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall show a local adapter's connectivity status distinctly, and shall not
  present stale state as current once connectivity is lost.
- **[vms]** The VMS shall not substitute visually-inferred events for adapter-sourced events
  during an adapter outage; the outage window shall be distinguishable from a genuine absence
  of activity.

## Scenario: An alarm-panel adapter reports a triggered alarm

**Scenario ID:** SCN-660
**Feature ID:** FEAT-208

**Persona:** A connected alarm panel reports an intrusion trigger via its local adapter.

1. VMS receives the alarm-triggered event directly from the panel and raises it as a high-
   priority alert immediately, tied to the relevant camera(s), rather than waiting for the AI
   detection pipeline to separately notice something in the footage.
2. Operators see the alarm-panel-sourced alert distinctly labeled as coming from the alarm system,
   not attributed to the camera's own AI detection.

**What the user expects:** an alarm panel's own trigger is treated as authoritative and
immediate, and it's clear where the alert actually came from.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** An alarm-panel-sourced trigger event received via a local adapter shall be raised as
  a high-priority alert without waiting on independent AI-detection confirmation, and shall be
  labeled with its actual source (the alarm system, not camera AI).
