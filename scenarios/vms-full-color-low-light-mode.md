---
feature_id: FEAT-010
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — Full-Color Low-Light / Spotlight Color Mode

Covers the fleet-operator-facing side of FEAT-010: configuring each camera's night vision mode
(IR black-and-white vs. full-color) from the VMS Imaging panel, for sites with a mix of camera
SKUs.

## Scenario: Operator standardizes night vision mode across compatible cameras at a site

**Scenario ID:** SCN-032
**Feature ID:** FEAT-010

**Persona:** Marcus manages a site with a mix of camera models, some with full-color low-light
sensors and some IR-only, and wants all color-capable cameras set to color night vision for
easier identification during nighttime incident review.

1. Marcus opens the site's multi-camera view and identifies which cameras report support for
   color night vision.
2. For each capable camera, he sets its night vision mode to color from the Imaging Settings
   panel.
3. The VMS confirms each change and the affected cameras' live thumbnails update to color once
   it's dark, while IR-only cameras in the same view are unaffected and continue showing standard
   grayscale IR.

**What the user expects:** he can apply this setting selectively across a mixed-hardware fleet
without the VMS pretending every camera can do it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose a night vision mode control (IR black-and-white vs. full-color)
  per camera in the Imaging Settings panel, showing it only for cameras that report support for
  color night capture.
- **[vms]** The VMS shall clearly distinguish, in any multi-camera view, which cameras are
  currently on color vs. IR night vision.
- **[camera-firmware]** The camera shall report its current night vision mode and color-capability
  through the same imaging status channel used for other image settings, so the VMS can display
  it without a separate query.

## Scenario: Night vision mode change fails on an unreachable camera

**Scenario ID:** SCN-033
**Feature ID:** FEAT-010

**Persona:** Marcus tries to switch a camera to color night vision, but the camera is momentarily
offline.

1. Marcus selects color mode for the camera and confirms.
2. The VMS reports, after a timeout, that it could not confirm the change rather than showing
   color mode as active.
3. The camera's status in the site view shows it as unreachable, explaining the failure, and
   Marcus can retry once it reconnects.

**What the user expects:** the VMS never shows a night vision mode as applied to a camera it
couldn't actually reach.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall not mark a night vision mode change as applied until the camera
  acknowledges it; on timeout/failure it shall show an explicit per-camera error rather than an
  optimistic state.
