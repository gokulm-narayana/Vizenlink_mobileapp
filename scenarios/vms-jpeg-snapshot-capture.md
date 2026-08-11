---
feature_id: FEAT-014
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — JPEG Snapshot Capture

Covers the fleet-operator-facing side of FEAT-014 (JPEG Snapshot Capture): capturing still images
from any camera in the VMS, including for incident documentation and via ONVIF-compliant NVR
clients.

## Scenario: Operator captures a snapshot for an incident report

**Scenario ID:** SCN-044
**Feature ID:** FEAT-014

**Persona:** Marcus is documenting an incident and needs a still image of a specific camera's
current view to attach to a report.

1. Marcus opens that camera's live view in the VMS and clicks the snapshot control.
2. The VMS captures and saves a JPEG still, which he can immediately attach to the incident record
   he's building.
3. The snapshot reflects the current view at the moment he clicked, not a delayed or stale frame.

**What the user expects:** grabbing a still for documentation is a one-click action available
right from the live view he's already looking at.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a snapshot capture control from any camera's live view, saving
  the resulting JPEG in a way that can be attached to an incident record.
- **[camera-firmware]** The camera shall serve a JPEG snapshot to an authenticated ONVIF or VMS
  client request, consistent with the same underlying snapshot capability used by mobile-app
  requests.

## Scenario: Third-party ONVIF NVR pulls a snapshot directly from the camera

**Scenario ID:** SCN-045
**Feature ID:** FEAT-014

**Persona:** A third-party NVR (not the project's own VMS) at a customer site is configured to
poll each camera's snapshot periodically for its own thumbnail/health-check purposes.

1. The third-party NVR issues a standard ONVIF snapshot request to the camera.
2. The camera returns a valid JPEG snapshot the same way it would to the VMS, without requiring
   any project-specific extension.
3. The NVR's thumbnail/preview stays current without the camera treating this differently from
   any other authenticated snapshot client.

**What the user expects:** snapshot capture is a standards-compliant capability that works
correctly with any conformant ONVIF client, not just the project's own VMS or app.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera's ONVIF snapshot endpoint shall serve a valid JPEG still to any
  authenticated ONVIF-conformant client, independent of whether the request originates from the
  project's own VMS/app or a third-party NVR.
