---
feature_id: FEAT-010
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Full-Color Low-Light / Spotlight Color Mode

Covers the homeowner-facing side of FEAT-010: a Night Vision mode selector letting the user
choose between standard black-and-white infrared night vision and full-color night capture (via
sensor-based low-light sensitivity or spotlight-assisted color), on SKUs that support it.

## Scenario: Switching to color night vision

**Scenario ID:** SCN-029
**Feature ID:** FEAT-010

**Persona:** Priya has a camera model with a full-color low-light sensor and wants to be able to
identify a visitor's clothing color at night, not just a grayscale silhouette.

1. Priya opens the camera's Night Vision setting in the app and finds an option alongside the
   usual Auto/Day/Night control for choosing black-and-white IR vs. full-color night capture.
2. She selects color night vision.
3. Once it's dark, her live view shows a color (not grayscale) image, brighter than a normal dark
   scene would look to the eye, with the camera's spotlight or enhanced low-light sensitivity
   doing the work.
4. The app clearly labels which mode is currently active so she isn't confused about why the image
   looks different from her other cameras still on standard IR night vision.

**What the user expects:** she can choose to see color at night when she wants more identifying
detail, and always knows which night vision mode is currently active.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an authorized user select between black-and-white infrared
  night vision and full-color night vision, on cameras that report support for color night
  capture.
- **[mobile-app]** The app shall clearly label the currently active night vision mode (IR
  black-and-white vs. full-color) in the live view UI.
- **[camera-firmware]** The camera shall support switching its low-light capture between
  IR-illuminated black-and-white and full-color (sensor-based or spotlight-assisted) modes on
  SKUs equipped for it, applying the selected mode without requiring a camera restart.

## Scenario: Color night vision control absent on IR-only SKUs

**Scenario ID:** SCN-030
**Feature ID:** FEAT-010

**Persona:** Priya has an older or lower-tier camera without a full-color low-light sensor or
spotlight.

1. She opens that camera's Night Vision settings expecting the same color option she has
   elsewhere.
2. The color night vision option isn't shown for this camera — only the standard black-and-white
   IR night vision applies, and nothing suggests a broken or non-functional control.

**What the user expects:** she isn't shown an option that this particular camera's hardware can't
actually deliver.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall hide the full-color night vision option for any camera that does
  not report support for it, based on a camera-reported capability rather than a fixed app-wide
  assumption.
- **[camera-firmware]** The camera shall report a color-night-vision capability flag distinguishing
  SKUs with a full-color low-light sensor or spotlight from IR-only SKUs.

## Scenario: Spotlight-assisted color mode and a nearby sleeping occupant

**Scenario ID:** SCN-031
**Feature ID:** FEAT-010

**Persona:** Priya's spotlight-equipped camera faces her own driveway, close enough to a bedroom
window that a bright white spotlight firing every time a car passes at night would be disruptive.

1. Priya selects color night vision on this camera, which relies on an active spotlight (rather
   than a fully passive low-light sensor) to produce color images.
2. Before finishing, the app makes clear to her that this mode will illuminate the scene with a
   visible light source at night, distinct from the passive/invisible IR mode she's used to.
3. She can decide, informed by that, whether to proceed, choose a schedule/motion-triggered-only
   behavior instead of continuous, or stick with standard IR night vision.

**What the user expects:** she isn't surprised by a spotlight lighting up her driveway at night
just because she picked "color" without understanding what makes that mode possible on this
camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall clearly indicate, before a user enables spotlight-assisted color
  night vision, that this mode activates a visible light source rather than passive infrared.
- **[camera-firmware]** On spotlight-assisted SKUs, the camera shall support configuring
  spotlight-assisted color mode as continuous or motion-triggered-only, rather than only an
  always-on behavior.
