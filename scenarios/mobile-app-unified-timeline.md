---
feature_id: FEAT-118
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Unified Recording/Event Timeline

Covers the mobile-app side of FEAT-118: a single timeline letting a user scrub continuous
recording and jump between AI-flagged events on it.

## Scenario: Scrubbing the timeline and jumping to a flagged event

**Scenario ID:** SCN-431
**Feature ID:** FEAT-118

**Persona:** Priya wants to review what happened on her driveway camera over the past evening.

1. Priya opens the timeline for that camera and sees a single scrubbable bar spanning the past
   24 hours, with small markers on it wherever an AI-flagged event occurred.
2. She drags the scrubber freely through ordinary continuous recording, seeing footage update
   as she drags.
3. She taps directly on one of the event markers, and playback jumps straight to that event's
   moment rather than her needing to scrub manually to find it.
4. A "next event" / "previous event" control lets her hop marker-to-marker without dragging at
   all.

**What the user expects:** one continuous timeline for everything, with flagged events as
fast-travel points on it rather than a separate list she has to cross-reference.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The timeline shall render continuous recorded footage as a single scrubbable
  bar, with AI-flagged events marked as discrete points on that same bar.
- **[mobile-app]** Tapping an event marker shall jump playback directly to that event's start,
  and next/previous controls shall step between markers without manual scrubbing.
- **[mobile-app]** Dragging the scrubber through non-flagged footage shall update the video
  preview continuously as the user drags, not only once released.
- **[camera-firmware]** The camera shall expose event timestamps alongside continuous recording
  so the timeline can align event markers precisely against the recorded footage.

## Scenario: Timeline shows a gap where no recording exists

**Scenario ID:** SCN-432
**Feature ID:** FEAT-118

**Persona:** Priya's camera was offline for two hours overnight (power outage), and she scrubs
back to that period the next morning.

1. The timeline visibly represents the gap — a distinct, clearly-labeled empty stretch — rather
   than silently skipping ahead or showing a frozen/looping frame as if footage existed.
2. Scrubbing into the gap shows an explicit "no recording available" state, with the reason
   shown if known (e.g. "Camera offline").
3. The timeline resumes normal continuous footage immediately after the gap ends.

**What the user expects:** missing footage is honestly represented as missing, never disguised
as continuous coverage.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The timeline shall visually distinguish a period with no recorded footage
  from a period with footage, rather than compressing or silently hiding the gap.
- **[mobile-app]** Scrubbing into a gap shall show an explicit "no recording" state, including
  the reason when the camera reported one (e.g. offline, storage full).
- **[camera-firmware]** The camera shall record and report recording-gap periods (start/end,
  and reason where known) so clients can render them accurately rather than inferring gaps from
  missing data alone.

## Scenario: Jumping between a dense cluster of flagged events

**Scenario ID:** SCN-433
**Feature ID:** FEAT-118

**Persona:** Priya's camera flagged a dozen events in a five-minute span (e.g. delivery
activity) and she wants to review them individually.

1. At the timeline's normal zoom level, the event markers for this cluster overlap too closely
   to tap individually.
2. Priya pinch-zooms into that section of the timeline, and the markers spread out enough to
   become individually tappable.
3. Next/previous-event navigation still steps through every individual marker in the cluster,
   even before zooming in.

**What the user expects:** a burst of closely-spaced events doesn't become impossible to
navigate individually just because they're visually crowded at normal zoom.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The timeline shall support zooming into a time range so closely-spaced event
  markers become individually distinguishable and tappable.
- **[mobile-app]** Next/previous-event navigation shall step through every individual flagged
  event in a dense cluster, independent of the timeline's current zoom level.
