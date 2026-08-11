---
feature_id: FEAT-071
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Dwell/Loitering Detection

Covers the fleet-operator side of FEAT-071: configuring loitering thresholds for common areas,
and avoiding a false-alert storm from a crowd of briefly-dwelling people.

## Scenario: Operator sets a loitering threshold for a common area

**Scenario ID:** SCN-253
**Feature ID:** FEAT-071

**Persona:** Dana, configuring a loitering rule for a community's mailroom area, where a brief
stop to check a mailbox is normal but anyone staying much longer is worth flagging.

1. Dana creates a loitering rule on the mailroom zone with a 5-minute threshold, reflecting how
   long a legitimate mail check should reasonably take.
2. Residents checking their mail and leaving within a minute or two never trigger the rule.
3. A person who remains well past 5 minutes triggers a loitering alert, which Dana can review in
   the VMS's event list alongside the linked clip.

**What the user expects:** she can set a threshold that matches the area's normal expected
activity duration, so the rule only flags genuinely unusual dwell time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator configure a dwell/loitering threshold per rule, with
  the resulting alerts distinctly labeled and filterable in the site event list.

## Scenario: A crowd of briefly-dwelling people doesn't trigger a loitering alert storm

**Scenario ID:** SCN-254
**Feature ID:** FEAT-071

**Persona:** Dana, whose lobby loitering rule is active during a community event where many
people naturally stand around chatting for a few minutes each — well under the configured
threshold, but a lot of simultaneous dwell activity.

1. Dozens of people are present in the lobby zone at once, each individually under the dwell
   threshold.
2. Because the camera tracks dwell time per individual tracked object rather than by aggregate
   zone occupancy, none of them individually trigger the loitering rule.
3. Dana's event list stays quiet through the event, with no false loitering alerts generated
   just because the zone was busy.

**What the user expects:** a crowded-but-normal area doesn't get treated as mass loitering — the
rule reflects genuine per-person dwell time, not simply "the zone had people in it for a while."

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall evaluate dwell/loitering per individually tracked
  object, not by aggregate time-any-object-was-present-in-zone, so a busy zone with many
  short-duration individuals does not falsely accumulate into a loitering trigger.
