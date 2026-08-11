---
feature_id: FEAT-011
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Digital Zoom (Live & Playback)

Covers the homeowner-facing side of FEAT-011 (Digital Zoom): pinch-to-zoom (or button-based zoom)
during both live view and recorded playback, clearly labeled as digital rather than optical.

## Scenario: Zooming in on a delivery person's face during live view

**Scenario ID:** SCN-034
**Feature ID:** FEAT-011

**Persona:** Priya is watching live view when someone approaches her door and wants a closer look
at their face.

1. Priya pinches to zoom in on the live view.
2. The image enlarges around the point she zoomed into, staying reasonably clear at moderate zoom
   levels though visibly softer at the far end of the zoom range.
3. A small label or icon indicates this is a digital zoom, so she understands the image is being
   enlarged from the existing frame rather than the lens physically zooming in.
4. She can pinch back out to return to the normal field of view.

**What the user expects:** she can zoom in for a closer look whenever she wants, understanding
that it's a digital crop-and-enlarge rather than an optical zoom that would stay perfectly sharp.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall support pinch-to-zoom (and/or equivalent zoom controls) on the
  live view, digitally cropping and enlarging the current frame.
- **[mobile-app]** The app shall visibly label any zoomed view as "digital zoom," distinguishing
  it from optical zoom, whenever zoom is active above 1x.
- **[mobile-app]** The app shall let the user return to the full, unzoomed field of view with a
  simple gesture/control.

## Scenario: Zooming into a recorded clip during playback

**Scenario ID:** SCN-035
**Feature ID:** FEAT-011

**Persona:** Priya is reviewing a recorded clip of a package left at her door and wants to zoom in
on the shipping label after the fact.

1. Priya opens the recorded clip and pinches to zoom in during playback, the same way she would
   in live view.
2. The clip continues playing (or she can scrub) while zoomed, letting her follow the zoomed
   region as the video plays.
3. She can zoom back out to see the full frame again without needing to reopen the clip.

**What the user expects:** zoom works the same familiar way whether she's watching live or
reviewing a past recording — she doesn't have to learn two different controls.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall support the same digital zoom gesture/control during recorded
  playback as during live view, without requiring a different interaction pattern.
- **[mobile-app]** Digital zoom during playback shall not interrupt or require restarting video
  playback/scrubbing.
