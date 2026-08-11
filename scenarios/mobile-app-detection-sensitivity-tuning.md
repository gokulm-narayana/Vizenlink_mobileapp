---
feature_id: FEAT-054
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Per-Camera Detection Sensitivity Tuning

Covers the homeowner-facing side of FEAT-054: the per-camera confidence threshold and
persistence (frame-count) filtering controls, and their safe defaults.

## Scenario: Lowering sensitivity to stop tree-branch nuisance alerts

**Scenario ID:** SCN-212
**Feature ID:** FEAT-054

**Persona:** Elena, a homeowner whose backyard camera faces a tree that sways in the wind and
keeps triggering low-confidence "object detected" alerts.

1. Elena opens the camera's detection settings in the app and finds a sensitivity slider/value,
   currently at the factory-default safe setting.
2. She nudges the sensitivity down one notch and saves.
3. Over the following nights, the wind-triggered false detections stop, while a person actually
   walking through the yard still reliably triggers an alert.
4. The app makes clear which camera this setting applies to — it doesn't affect her other
   cameras.

**What the user expects:** she can dial down false positives from her specific problem camera
without having to accept the same trade-off on every other camera, and without needing to
understand what "confidence threshold" means under the hood beyond "make it less twitchy."

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall expose a per-camera detection sensitivity control (a simple
  slider or discrete levels, not a raw numeric confidence value) in that camera's detection
  settings, scoped to the one camera being edited.
- **[camera-firmware]** The camera shall apply an adjustable minimum confidence threshold to
  its detection pipeline, using the value most recently set for that camera, independent of the
  threshold used by any other camera on the account.

## Scenario: Frame-count persistence filter avoids a single-frame flicker alert

**Scenario ID:** SCN-213
**Feature ID:** FEAT-054

**Persona:** Elena, whose driveway camera occasionally shows a single-frame glare artifact from
a passing headlight reflection.

1. A stray reflection produces a detection-like blob for a single frame, then vanishes.
2. Because the camera requires the same object to persist across a minimum number of consecutive
   frames before it counts as a real detection, no alert is generated for the one-frame flicker.
3. When an actual car later enters and stays in frame across multiple consecutive frames, the
   persistence check passes and Elena gets the alert as expected.
4. Elena never has to configure or even know about the frame-count filter directly — it's part
   of the same sensitivity setting, shipped with a safe default.

**What the user expects:** momentary visual glitches don't turn into phone notifications, while
genuine, sustained detections still come through promptly.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall require a detected object to persist across a
  configurable minimum number of consecutive frames before raising an alert-worthy event, with a
  safe factory default that filters single-frame artifacts without noticeably delaying
  genuine detections.
- **[mobile-app]** The app's sensitivity control shall be presented as a single combined
  setting (confidence + persistence) with safe factory defaults already applied, rather than
  exposing the frame-count parameter as a separate control the user must independently tune.
