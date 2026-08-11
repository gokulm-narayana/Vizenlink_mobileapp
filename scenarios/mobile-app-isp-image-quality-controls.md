---
feature_id: FEAT-017
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — ISP Image-Quality Controls

Covers the homeowner-facing side of FEAT-017 (ISP Image-Quality Controls): basic brightness,
contrast, saturation, sharpness, white-balance, and exposure adjustment from the app, distinct
from encoder/bitrate settings.

## Scenario: Adjusting brightness and saturation for a shaded porch camera

**Scenario ID:** SCN-050
**Feature ID:** FEAT-017

**Persona:** Priya's porch camera sits under an overhang and looks slightly dim and washed-out
compared to her other cameras.

1. Priya opens the camera's image-quality settings in the app and finds brightness, contrast,
   saturation, sharpness, white balance, and exposure as separate adjustable controls.
2. She raises brightness and saturation slightly using simple sliders.
3. Her live view updates to reflect the changes within a few seconds.
4. The settings persist across app sessions and camera reboots.

**What the user expects:** she can tune how the picture looks with straightforward sliders,
without needing to touch anything related to video quality/bitrate.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide individually adjustable controls for brightness,
  contrast, saturation, sharpness, white-balance mode, and exposure, distinct from any
  encoder/bitrate settings.
- **[camera-firmware]** The camera shall apply ISP image-tuning parameters (brightness, contrast,
  saturation, sharpness, white balance, exposure) independently of encoder configuration, and
  persist them across reboots.

## Scenario: Resetting to factory image defaults after over-adjusting

**Scenario ID:** SCN-051
**Feature ID:** FEAT-017

**Persona:** Priya experimented with the sliders and now the image looks worse than before —
oversaturated and oddly tinted — and she can't remember the original values.

1. Priya opens the image-quality settings and finds a "Reset to Default" option.
2. She taps it, and every slider returns to the camera's factory default values.
3. Her live view returns to how it looked before she started adjusting.

**What the user expects:** she always has an easy way back to a known-good baseline if her own
adjustments make things worse.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a "Reset to Default" control for ISP image-quality
  settings that restores all of brightness/contrast/saturation/sharpness/white-balance/exposure
  to the camera's factory defaults in one action.
- **[camera-firmware]** The camera shall retain its factory-default ISP image-quality values so a
  reset request can restore them exactly, distinct from whatever values are currently applied.
