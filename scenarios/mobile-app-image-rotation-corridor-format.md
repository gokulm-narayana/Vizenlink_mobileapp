---
feature_id: FEAT-020
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Image Rotation / Corridor Format

Covers the homeowner-facing side of FEAT-020 (Image Rotation / Corridor Format): rotating a
camera's image 90°/270° into portrait orientation for narrow, elongated scenes like hallways or
stairwells.

## Scenario: Rotating a hallway camera into portrait/corridor format

**Scenario ID:** SCN-059
**Feature ID:** FEAT-020

**Persona:** Priya has a camera covering a narrow interior hallway and finds the normal
widescreen view wastes most of the frame on the walls while cutting off the top and bottom of the
hallway itself.

1. Priya opens the camera's orientation settings and finds a rotation option (90°/270°) in
   addition to the mirror/flip controls.
2. She selects 90°.
3. Her live view now shows a tall, portrait-oriented image that captures the full length of the
   hallway floor-to-ceiling, with the app's viewer adjusting its own layout to display the
   rotated aspect ratio properly rather than showing it sideways.

**What the user expects:** the app's live view actually displays correctly in the new
orientation — she isn't left tilting her phone to make sense of a still-sideways image.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a 90°/270° rotation control for camera orientation, and
  shall render the live view and recordings in the corresponding portrait aspect ratio rather than
  displaying a rotated image inside a landscape frame.
- **[camera-firmware]** The camera shall support 90°/270° image rotation applied at the
  encoder/sensor level, producing a correctly-oriented portrait-format stream rather than
  requiring the client to rotate a landscape stream itself.

## Scenario: Recorded corridor-format clips play back correctly outside the app

**Scenario ID:** SCN-060
**Feature ID:** FEAT-020

**Persona:** Priya exports a corridor-format recorded clip and opens it in her phone's normal
video player to share it.

1. Priya exports the clip from the app.
2. When she opens it in a standard video player (not the camera app), the video plays in the
   correct portrait orientation, not sideways or requiring the viewer to rotate their device.

**What the user expects:** the rotation is a real property of the exported video file, not just
something the app's own player fakes on screen.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall encode rotated recordings with correct orientation
  metadata (or physically rotated frames) so standard third-party video players display them
  right-side-up without requiring the camera app specifically.
