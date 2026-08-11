---
feature_id: FEAT-011
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Digital Zoom (Live & Playback)

Covers the fleet-operator-facing side of FEAT-011 (Digital Zoom): zooming into a camera's live or
recorded feed from the VMS during monitoring or incident review, clearly labeled as digital.

## Scenario: Operator zooms in on a live feed during an active incident

**Scenario ID:** SCN-036
**Feature ID:** FEAT-011

**Persona:** Marcus is watching a camera's live feed in the VMS when he notices unusual activity
near a gate and wants a closer look without leaving the grid view.

1. Marcus zooms into that camera's tile using the VMS's zoom control.
2. The image enlarges around the area of interest, labeled as digital zoom, while the other
   cameras in the grid remain at normal view.
3. He zooms back out once he's seen what he needed.

**What the user expects:** he can zoom into any one camera's feed for a closer look during active
monitoring without disrupting the rest of the grid or being misled about zoom being optical.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support digital zoom on an individual camera's live tile within a
  multi-camera grid, without affecting the view of other cameras in the same grid.
- **[vms]** The VMS shall label a zoomed camera tile as using digital zoom.

## Scenario: Operator zooms into archived footage during incident review

**Scenario ID:** SCN-037
**Feature ID:** FEAT-011

**Persona:** Marcus is reviewing archived footage from a specific camera to identify a vehicle's
license plate after an incident.

1. Marcus opens the recorded clip in the VMS's playback view and zooms in on the plate area.
2. The zoomed view stays active as he scrubs forward/backward through the clip, rather than
   resetting to full view on every scrub.
3. He exports or screenshots the zoomed frame for the incident report.

**What the user expects:** zoom persists sensibly through playback navigation instead of forcing
him to re-zoom after every scrub.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support digital zoom during recorded playback, retaining the zoomed
  region across scrubbing/seeking within the same clip rather than resetting on every seek.
- **[vms]** The VMS shall allow exporting or capturing the currently zoomed frame for incident
  documentation.
