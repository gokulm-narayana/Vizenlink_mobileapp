---
feature_id: FEAT-015
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — On-Screen Display (OSD) Overlay

Covers the fleet-operator-facing side of FEAT-015 (OSD Overlay): installer/admin-configurable
text, timestamp, and logo overlay settings across a site's cameras from the VMS.

## Scenario: Installer configures a branded logo overlay across a site's cameras

**Scenario ID:** SCN-048
**Feature ID:** FEAT-015

**Persona:** Dana, an installer setting up a community site, needs every camera to display the
HOA's logo overlay in addition to timestamp and camera-name text, per the client's contract.

1. Dana opens the site's overlay settings in the VMS and uploads the logo image once.
2. She configures overlay position, timestamp format, and camera-name text for each camera, or
   applies the same template across multiple cameras at once rather than repeating the setup
   per camera.
3. The VMS confirms each camera's overlay is applied and shows a preview per camera before/after
   the change.

**What the user expects:** setting up a consistent branded overlay across many cameras is a
batch-friendly operation, not a manual repeat of the same steps per camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide installer/admin-level controls for OSD text, timestamp format,
  and logo overlay per camera, with the ability to apply the same overlay template to multiple
  cameras at once.
- **[vms]** The VMS shall show a preview of the overlay as configured before/after applying it to
  a camera.
- **[camera-firmware]** The camera shall accept a logo image and overlay position/format
  configuration and burn it into the video stream alongside text/timestamp overlays.

## Scenario: Overlay position conflicts with an active privacy mask

**Scenario ID:** SCN-049
**Feature ID:** FEAT-015

**Persona:** Marcus configures an OSD overlay position that happens to sit directly on top of a
region already covered by a privacy mask on that camera.

1. Marcus sets the overlay position and saves.
2. The VMS warns him that the chosen overlay position overlaps a configured privacy mask region,
   since a mask covering the overlay area would defeat the overlay's purpose (or vice versa).
3. He adjusts the overlay position to a clear area and confirms.

**What the user expects:** the VMS catches an obvious configuration conflict between two
independent camera settings rather than letting him silently create a broken result.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall warn when a configured OSD overlay position overlaps an existing privacy
  mask region on the same camera, rather than silently allowing the conflicting configuration.
