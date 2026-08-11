---
feature_id: FEAT-019
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — Mirror/Flip Orientation Control

Covers the fleet-operator-facing side of FEAT-019 (Mirror/Flip Orientation Control): correcting
mounting orientation issues across a site's cameras from the VMS, using standard ONVIF imaging
controls.

## Scenario: Installer corrects orientation for several mis-mounted cameras during commissioning

**Scenario ID:** SCN-057
**Feature ID:** FEAT-019

**Persona:** Dana finishes mounting a batch of cameras at a site and finds three of them were
installed with brackets that leave the image upside-down.

1. Dana opens each affected camera's Imaging Settings in the VMS and enables vertical flip.
2. The VMS confirms each change and each camera's thumbnail updates to right-side-up in the site
   grid.
3. She verifies from the grid view that no camera in the site is still showing an incorrect
   orientation before finishing commissioning.

**What the user expects:** orientation issues found during commissioning are quick, per-camera
software fixes handled from the same tool she's already using to set up the site.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS Imaging Settings panel shall expose horizontal/vertical flip controls per
  camera, usable independently or combined.
- **[camera-firmware]** The camera's ONVIF Imaging service shall accept a mirror/flip setting
  request and apply it to the live stream and recordings consistently with a request made via any
  other authorized client.

## Scenario: Flip setting fails to apply and the grid keeps showing the wrong orientation

**Scenario ID:** SCN-058
**Feature ID:** FEAT-019

**Persona:** Marcus tries to fix a camera's orientation from the VMS, but the request fails
silently due to a transient network issue.

1. Marcus enables vertical flip for the camera and confirms.
2. The VMS reports, after a timeout, that the change could not be confirmed, rather than showing
   the flip as applied while the camera's actual stream remains unchanged.
3. The grid thumbnail for that camera continues to show its actual (uncorrected) current
   orientation, matching what the camera is really outputting.

**What the user expects:** the VMS's displayed state always matches what the camera is actually
doing — never an optimistic UI state disconnected from reality.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall not update its displayed orientation state for a camera until the
  camera acknowledges the flip request; on failure it shall continue reflecting the camera's
  last-confirmed orientation.
