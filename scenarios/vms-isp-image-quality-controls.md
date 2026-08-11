---
feature_id: FEAT-017
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — ISP Image-Quality Controls

Covers the fleet-operator-facing side of FEAT-017 (ISP Image-Quality Controls): installer/admin
tuning of brightness, contrast, saturation, sharpness, white-balance mode, and manual exposure per
camera from the VMS Imaging panel.

## Scenario: Installer tunes exposure and white balance for an indoor/outdoor transition camera

**Scenario ID:** SCN-052
**Feature ID:** FEAT-017

**Persona:** Dana is commissioning a camera positioned to see both an indoor lobby and a bright
outdoor doorway in the same frame, and the default auto white-balance shifts distractingly as
lighting changes.

1. Dana opens the camera's Imaging Settings in the VMS and switches white balance from Auto to a
   manual/fixed setting appropriate for the lobby's lighting.
2. She also sets manual exposure to avoid the auto-exposure hunting between the bright doorway and
   dim lobby.
3. The VMS confirms both changes and the live thumbnail stabilizes without the shifting she saw
   before.

**What the user expects:** deep image tuning is available as itemized, professional-grade
controls for exactly the situations where auto settings misbehave.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS Imaging Settings panel shall expose brightness, contrast, saturation,
  sharpness, white-balance mode (including a manual/fixed option), and manual exposure as
  individually adjustable controls per camera.
- **[camera-firmware]** The camera shall support a manual (non-auto) white-balance and exposure
  mode with explicit values, applied without disrupting the ongoing video stream.

## Scenario: Bulk-applying an image-quality profile to identical camera models

**Scenario ID:** SCN-053
**Feature ID:** FEAT-017

**Persona:** Marcus has a dozen identical camera models installed under similar lighting across a
site and wants them all tuned the same way rather than repeating manual adjustment per camera.

1. Marcus tunes one camera's image-quality settings until it looks right.
2. He applies that same settings profile to the other cameras of the same model from a
   bulk-apply option, rather than re-entering each value per camera.
3. The VMS confirms which cameras received the profile successfully and flags any that failed to
   apply (e.g. an offline unit).

**What the user expects:** tuning a repeated hardware setup once and rolling it out to the rest is
far faster than manually repeating identical adjustments camera by camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow copying one camera's ISP image-quality settings as a profile
  applied in bulk to a selected set of other cameras, reporting per-camera success/failure rather
  than an all-or-nothing result.

## Scenario: Reverting an installer's tuning back to camera factory defaults remotely

**Scenario ID:** SCN-054
**Feature ID:** FEAT-017

**Persona:** Marcus discovers a camera's image looks wrong after a past installer visit and wants
to reset it to a known baseline without an on-site truck roll.

1. Marcus opens the camera's Imaging Settings and selects "Reset to Factory Defaults."
2. The VMS confirms the camera returned all ISP image-quality values to factory defaults, and the
   live thumbnail reflects the reset.

**What the user expects:** he can always recover from an unknown or bad prior configuration
remotely, without needing anyone to physically visit the camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a remote "Reset to Factory Defaults" action for a camera's ISP
  image-quality settings, confirmed once the camera applies it.
