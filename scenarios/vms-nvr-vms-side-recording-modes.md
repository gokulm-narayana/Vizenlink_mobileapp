---
feature_id: FEAT-032
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — NVR/VMS-Side Recording Modes

Covers the fleet-operator-facing side of FEAT-032: configuring how the NVR/VMS records each
camera's stream — continuous, time-scheduled, or event-triggered — independent of whatever
recording mode the camera itself is running locally.

## Scenario: Operator sets continuous recording for a camera group

**Scenario ID:** SCN-113
**Feature ID:** FEAT-032

**Persona:** Marcus, a security operator managing a small office site, wants every camera in the
"perimeter" group to record continuously to the NVR regardless of activity.

1. Marcus selects the perimeter camera group in the VMS and opens its recording settings.
2. He sets the recording mode to "Continuous" and applies it to the whole group in one action.
3. The VMS confirms each camera in the group individually as the setting is applied, rather than
   reporting group-level success while a camera silently failed to apply it.
4. The VMS's recording-status view shows all perimeter cameras now recording continuously.

**What the user expects:** he can configure a whole group at once without having to babysit
each camera individually, but still finds out if one camera in the group didn't actually take
the setting.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow setting a recording mode (Continuous / Scheduled /
  Event-Triggered) for a camera group in a single action, while confirming the result per
  camera rather than only at the group level.
- **[vms]** The VMS shall display each camera's current NVR-side recording mode/status in a
  recording-status view.

## Scenario: Time-scheduled recording windows across multiple cameras

**Scenario ID:** SCN-114
**Feature ID:** FEAT-032

**Persona:** Priya, operating a community VMS, wants the parking-lot cameras to record to the
NVR only during evening/overnight hours when foot traffic is highest-risk.

1. Priya opens the schedule editor for the parking-lot camera group and defines an overnight
   recording window.
2. The VMS applies the schedule to each camera in the group and shows the resulting per-camera
   recording windows for confirmation.
3. Outside the scheduled window, those cameras' streams remain viewable live but are not written
   to NVR storage.

**What the user expects:** she can apply one schedule across many cameras and trust that each
one is actually following it, without checking each camera one by one.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a schedule editor applicable to a camera or camera group,
  confirming the resulting per-camera schedule after it is applied.
- **[vms]** The VMS shall continue to serve live view for a camera outside its scheduled
  recording window, while withholding that time range from NVR storage.

## Scenario: Event-triggered NVR recording tied to the rules engine

**Scenario ID:** SCN-115
**Feature ID:** FEAT-032

**Persona:** Marcus wants the NVR to record a camera only when the security rules engine (e.g. a
configured line-crossing or zone rule) fires an event for it.

1. Marcus sets a camera's NVR recording mode to "Event-Triggered" and links it to the camera's
   existing detection rules.
2. When a linked rule fires, the VMS begins recording that camera to the NVR for the event's
   duration (plus pre/post-roll, covered separately under FEAT-036).
3. The VMS's event log shows the resulting recording linked back to the rule that triggered it.

**What the user expects:** NVR storage is spent on activity the rules engine actually flagged as
worth keeping, not blanket recording, and he can trace any given recording back to why it exists.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support an Event-Triggered NVR recording mode that records a camera
  only when a rule from its configured security rules engine fires.
- **[vms]** The VMS shall link each event-triggered NVR recording back to the rule/event that
  triggered it in the event log.

## Scenario: Conflicting recording-mode assignment across an overlapping schedule

**Scenario ID:** SCN-116
**Feature ID:** FEAT-032

**Persona:** Marcus accidentally assigns a camera to two different scheduled recording windows
with overlapping times through two different group memberships.

1. Marcus applies a schedule to a camera group that includes a camera already individually
   configured with a conflicting schedule.
2. The VMS detects the conflict before applying the change and presents both conflicting
   configurations, asking Marcus to resolve which one should apply to the affected camera.
3. Nothing is silently overwritten — the camera keeps its prior working configuration until
   Marcus resolves the conflict.

**What the user expects:** the VMS won't let a group-level change silently clobber a
camera-specific setting he set up on purpose.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect a recording-schedule conflict when a group-level change would
  contradict an existing per-camera schedule, and shall require explicit resolution before
  applying either configuration.
- **[vms]** The VMS shall leave the affected camera's prior recording configuration unchanged
  until the conflict is resolved.
