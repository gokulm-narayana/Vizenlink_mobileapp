---
feature_id: FEAT-039
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Indexed Playback (Time & Event)

Covers the homeowner-facing side of FEAT-039: navigating recorded footage both by absolute time
and by discrete event, not just a continuous scrub timeline.

## Scenario: Scrubbing to an absolute time

**Scenario ID:** SCN-137
**Feature ID:** FEAT-039

**Persona:** Marcus remembers roughly when a delivery happened yesterday and wants to jump
straight to that time.

1. Marcus opens playback for his front-door camera and taps a time-jump control.
2. He enters or picks an approximate time (e.g. "yesterday, 2:15pm").
3. The app seeks directly to that point in the recorded timeline, playing from there, without
   requiring him to scrub through hours of footage by hand.

**What the user expects:** he can jump straight to roughly when something happened instead of
dragging a scrub bar for minutes.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a direct time-entry/time-jump control for recorded
  playback, seeking to the requested absolute time without requiring manual scrubbing.
- **[camera-firmware]** The camera (or its recording index) shall support seeking recorded
  footage directly to an arbitrary absolute timestamp.

## Scenario: Jumping between discrete events on the timeline

**Scenario ID:** SCN-138
**Feature ID:** FEAT-039

**Persona:** Priya wants to review just the motion events from overnight, not scrub through
hours of an empty driveway.

1. Priya opens playback and switches to an event-indexed view showing discrete detected events
   as markers along the timeline.
2. She taps "next event" repeatedly to jump from one detected event directly to the next,
   skipping the footage in between.
3. Each jump lands her at the start of that event's clip (including its pre-roll), not an
   arbitrary point within it.

**What the user expects:** reviewing an overnight period means watching what actually happened,
not fast-forwarding through empty footage herself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide an event-indexed playback view showing discrete
  detected events as timeline markers, distinct from the continuous scrub timeline.
- **[mobile-app]** The app shall support jumping directly to the next/previous event, landing at
  the start of that event's clip (including pre-roll) rather than an arbitrary point.
- **[camera-firmware]** The camera (or its recording index) shall expose a list of discrete
  event timestamps within a recorded range, so a client can navigate by event without scanning
  the full continuous stream.
