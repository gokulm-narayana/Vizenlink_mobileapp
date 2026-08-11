---
feature_id: FEAT-087
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Night Vision Usability Monitoring

Covers the fleet-operator-facing side of FEAT-087: flagging cameras whose night vision quality
has become unusable, across a multi-camera site.

## Scenario: Operator spots a pattern of failing IR illuminators across a site

**Scenario ID:** SCN-330
**Feature ID:** FEAT-087

**Persona:** Dana, an operator noticing several cameras from the same installation batch flagged
"Night Vision Unusable" within the same week.

1. Each affected camera shows a night-vision-attention badge, but only active during their local
   night hours — daytime health for those same cameras stays normal.
2. The VMS's alert feed lets Dana filter to just night-vision alerts, and she notices three
   cameras installed around the same time are all affected, suggesting a batch hardware issue
   rather than three unrelated faults.
3. She logs a single maintenance ticket referencing all three cameras instead of three separate
   unrelated tickets, since the VMS makes the pattern visible.

**What the user expects:** at fleet scale, a per-camera "night vision unusable" flag surfaces
clearly enough that a systemic pattern (e.g. a bad batch of IR illuminators) is discoverable, not
just handled as isolated incidents.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall badge a camera as night-vision-attention only during that camera's
  actual night-mode hours, leaving its daytime health status unaffected.
- **[vms]** The VMS shall let an operator filter the fleet alert feed to night-vision-unusable
  alerts specifically, to help identify multi-camera patterns.

## Scenario: Night vision alert during a scheduled overnight recording review

**Scenario ID:** SCN-331
**Feature ID:** FEAT-087

**Persona:** Dana is reviewing last night's recorded footage from a specific camera after an
incident report, and finds the footage unusable due to poor night vision — but no alert had
been raised at the time.

1. Dana checks that camera's health history for the relevant night and confirms no
   night-vision-unusable alert was logged, meaning the condition either didn't cross the
   sustained threshold or wasn't evaluated at all that night.
2. She flags this gap to support, since being able to trust that "no alert = footage was usable"
   matters for her evidentiary reviews after the fact.
3. The VMS distinguishes "no alert raised" from "alert raised and since cleared" in its history,
   so she isn't left guessing which case applies.

**What the user expects:** she can trust the alert history as an honest record — if there's no
alert for a given night, that's a real signal the system evaluated the footage and found it
acceptable, not an unmonitored gap.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall retain a per-camera night-vision health history distinguishing "no
  condition detected," "condition detected and cleared," and "condition still open" for each
  night, so an operator reviewing footage after the fact can tell which applied.
- **[camera-firmware]** The camera shall run its night-vision usability evaluation every night it
  is in night mode, so the absence of a logged alert reliably means the condition was evaluated
  and found acceptable rather than simply not checked.
