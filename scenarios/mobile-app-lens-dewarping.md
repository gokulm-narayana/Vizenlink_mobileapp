---
feature_id: FEAT-012
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Lens Dewarping / Corrected View

Covers the homeowner-facing side of FEAT-012 (Lens Dewarping): a view-mode toggle between the
camera's raw fisheye image and a perspective-corrected "dewarped" view, offered only on lens/SKU
combinations with validated calibration.

## Scenario: Switching to corrected view on a fisheye camera

**Scenario ID:** SCN-038
**Feature ID:** FEAT-012

**Persona:** Priya has a wide-angle fisheye camera covering her whole backyard and finds the raw
fisheye image's curved distortion hard to read at the edges.

1. Priya opens the camera's live view and finds a view-mode control offering "Original" (fisheye)
   and "Corrected" (dewarped) options.
2. She selects "Corrected."
3. The live view updates to a perspective-corrected image with straight lines looking straight,
   at some cost to total field of view shown at once.
4. The setting is remembered the next time she opens this camera.

**What the user expects:** she can view a natural-looking, undistorted image when she prefers it
over the full fisheye field of view, and the app remembers her preference.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a view-mode control (original fisheye vs. dewarped
  corrected view) for cameras that report a validated dewarping calibration, and shall not offer
  it for cameras that don't.
- **[mobile-app]** The app shall remember the user's selected view mode per camera across
  sessions.
- **[camera-firmware]** The camera shall apply lens dewarping correction based on its validated
  per-lens calibration profile, producing a corrected stream/view without requiring the app to
  perform its own correction.

## Scenario: Dewarped view unavailable on an uncalibrated lens/SKU combination

**Scenario ID:** SCN-039
**Feature ID:** FEAT-012

**Persona:** Priya has a fisheye camera model whose specific lens variant hasn't had a validated
dewarping calibration published.

1. Priya opens that camera's view-mode settings expecting the corrected option she has on her
   other fisheye camera.
2. Only the original fisheye view is offered — the corrected option isn't shown for this
   camera, rather than showing a corrected view that's actually poorly calibrated or distorted.

**What the user expects:** she's never given a "corrected" view that isn't actually validated to
look right — better to not offer it than to offer a subtly wrong one.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall only offer the dewarped view option for a camera that reports a
  validated dewarping calibration for its specific lens/SKU combination.
- **[camera-firmware]** The camera shall report a dewarping-capability flag tied to its
  specific validated lens calibration, distinct from a generic "this model supports a wide-angle
  lens" flag.
