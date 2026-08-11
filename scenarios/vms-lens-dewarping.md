---
feature_id: FEAT-012
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Lens Dewarping / Corrected View

Covers the fleet-operator-facing side of FEAT-012 (Lens Dewarping): setting a fisheye camera's
default view mode from the VMS, and using multi-region dewarped views for wide-coverage
monitoring across a site.

## Scenario: Installer sets a fisheye camera's default view mode during commissioning

**Scenario ID:** SCN-040
**Feature ID:** FEAT-012

**Persona:** Dana, an installer, is commissioning a fisheye camera mounted in a community
courtyard and wants the VMS's default display for this camera to be the corrected view rather
than raw fisheye, since most operators will find that easier to read.

1. Dana opens the camera's view settings in the VMS and finds the dewarping option, shown because
   this lens/SKU has a validated calibration.
2. She sets the default view mode to "Corrected" for this camera.
3. The VMS confirms the setting, and this camera's tile in the grid now defaults to the corrected
   view for any operator who opens it, without each operator needing to set it individually.

**What the user expects:** a sensible per-camera default she sets once at commissioning carries
through for whoever operates the VMS day to day.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow an installer/admin to set a camera's default view mode (original
  vs. dewarped) for cameras with a validated dewarping calibration, applied for all operators
  viewing that camera unless they override it in their own session.
- **[camera-firmware]** The camera shall expose its dewarping calibration validity so the VMS can
  decide whether to offer the corrected-view default for a given unit.

## Scenario: Operator switches between multiple dewarped regions on one fisheye feed

**Scenario ID:** SCN-041
**Feature ID:** FEAT-012

**Persona:** Marcus is monitoring a ceiling-mounted fisheye camera covering an entire community
room and needs to focus on one corner where an incident was reported, rather than the whole
dewarped panorama.

1. Marcus switches that camera's tile to corrected view.
2. He selects a specific region of the dewarped image to focus on (e.g. one quadrant of the room)
   rather than only the full-width corrected panorama.
3. He can switch back to the full panorama or to another region without leaving this camera's
   view.

**What the user expects:** on a wide fisheye feed, he can narrow focus to the part of the room he
cares about rather than only ever seeing the whole corrected scene at once.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator select and switch between distinct sub-regions of a
  dewarped fisheye view, in addition to the full corrected panorama, for cameras that support
  multi-region dewarping.
