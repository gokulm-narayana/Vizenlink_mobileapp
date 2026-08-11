---
feature_id: FEAT-015
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — On-Screen Display (OSD) Overlay

Covers the homeowner-facing side of FEAT-015 (OSD Overlay): a simple on/off and basic-content
control for the camera's burned-in timestamp/text overlay, distinct from the deeper installer
configuration available in the VMS.

## Scenario: Homeowner enables a timestamp overlay for exported clips

**Scenario ID:** SCN-046
**Feature ID:** FEAT-015

**Persona:** Priya wants any clip she exports and shares to include a visible timestamp burned
into the video, so the recipient can see exactly when it happened without relying on file
metadata.

1. Priya opens the camera's overlay settings in the app and turns on the timestamp overlay.
2. Her live view and any new recordings now show the date/time burned into a corner of the frame.
3. The next time she exports a clip and sends it, the timestamp travels with the video itself.

**What the user expects:** a simple toggle burns a readable timestamp into the video whenever she
wants that for sharing purposes.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide an on/off control for the camera's timestamp OSD overlay,
  applying to both live view and new recordings.
- **[camera-firmware]** The camera shall burn a configured timestamp overlay into its encoded
  video stream (not just an app-side UI overlay), so it persists in exported/downloaded clips.

## Scenario: Camera name overlay helps distinguish cameras in a multi-camera household

**Scenario ID:** SCN-047
**Feature ID:** FEAT-015

**Persona:** Priya has four cameras around her property and finds it hard to tell which clip is
which once exported and separated from the app's own labeling.

1. Priya sets a short custom name/label for each camera in its overlay settings (e.g. "Front
   Door," "Driveway").
2. Each camera's live view and recordings now show that label burned in alongside the timestamp.
3. Exported clips are now self-identifying even without the app's own file naming.

**What the user expects:** she can tell cameras apart from the video itself, not just from
in-app labels that don't travel with an exported file.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let the user set a short custom text label per camera, displayed
  as part of the burned-in OSD overlay.
- **[camera-firmware]** The camera shall burn the configured camera name/label into its video
  stream alongside the timestamp when the overlay is enabled.
