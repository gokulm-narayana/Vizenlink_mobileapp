---
feature_id: FEAT-039
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Indexed Playback (Time & Event)

Covers the fleet-operator-facing side of FEAT-039: navigating recorded footage across one or
more cameras both by absolute time and by discrete event.

## Scenario: Operator navigates a multi-camera timeline by time

**Scenario ID:** SCN-139
**Feature ID:** FEAT-039

**Persona:** Marcus needs to review what several cameras at a site captured at a specific
reported incident time.

1. Marcus opens the site's multi-camera playback view and enters the approximate incident time.
2. All selected cameras' timelines seek to that same absolute time simultaneously.
3. Marcus can then scrub or step each camera's timeline independently from that shared starting
   point.

**What the user expects:** he doesn't have to manually align multiple cameras' timelines to the
same moment himself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support seeking multiple selected cameras' playback timelines to the
  same absolute time in a single action.
- **[vms]** The VMS shall allow each camera's timeline to be scrubbed or stepped independently
  after a shared time-jump.

## Scenario: Operator jumps to next/previous event across cameras

**Scenario ID:** SCN-140
**Feature ID:** FEAT-039

**Persona:** Priya is reviewing a site's overnight activity and wants to step through every
detected event across all its cameras in chronological order, not one camera at a time.

1. Priya opens the site's event-indexed playback view, which merges detected events from all
   cameras at the site into one chronological list.
2. She steps forward through events; each step both jumps to the event's time and switches
   focus to whichever camera(s) captured it.
3. She can filter the event list by camera or by event severity before stepping through it.

**What the user expects:** she can review "what happened at this site overnight," in order,
without needing to separately dig through each camera's own timeline.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a site-level event-indexed playback view merging detected
  events from multiple cameras into one chronological, filterable list.
- **[vms]** The VMS shall switch playback focus to the camera(s) that captured an event when the
  operator steps to it from the merged event list.
