---
feature_id: FEAT-020
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — Image Rotation / Corridor Format

Covers the fleet-operator-facing side of FEAT-020 (Image Rotation / Corridor Format): setting
portrait/corridor rotation per camera from the VMS, and displaying rotated cameras correctly
alongside normally-oriented ones in a multi-camera grid.

## Scenario: Installer sets corridor rotation for a stairwell camera

**Scenario ID:** SCN-061
**Feature ID:** FEAT-020

**Persona:** Dana is commissioning a camera covering a narrow office stairwell and wants it in
portrait/corridor format to capture the full stair run.

1. Dana opens the camera's Imaging Settings in the VMS and sets rotation to 90°.
2. The VMS confirms the change and displays this camera's tile in the site grid using the correct
   portrait aspect ratio, sized appropriately alongside the other, normally-oriented camera tiles.

**What the user expects:** a rotated camera's tile looks right in the grid immediately, not
squeezed into a landscape-shaped tile that misrepresents the actual image.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose a 90°/270° rotation control per camera in the Imaging Settings
  panel, and render that camera's tile in any multi-camera grid using the corresponding portrait
  aspect ratio.
- **[camera-firmware]** The camera shall report its currently configured rotation as part of its
  stream metadata so clients (VMS, app) can size their display correctly without guessing.

## Scenario: Mixed orientations in one grid don't break the layout

**Scenario ID:** SCN-062
**Feature ID:** FEAT-020

**Persona:** Marcus monitors a site with both normal landscape cameras and a couple of
corridor-format portrait cameras in the same multi-camera grid.

1. Marcus opens the site's grid view.
2. Portrait cameras display correctly in their own aspect ratio without distorting/stretching to
   match the landscape tiles around them, and the grid layout accommodates the mix sensibly.

**What the user expects:** a mixed-orientation site doesn't produce a broken or distorted grid
layout.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS's multi-camera grid layout shall accommodate a mix of landscape and portrait
  (rotated) camera tiles without stretching or distorting either to match the other.
