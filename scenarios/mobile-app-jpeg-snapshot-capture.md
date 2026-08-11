---
feature_id: FEAT-014
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — JPEG Snapshot Capture

Covers the homeowner-facing side of FEAT-014 (JPEG Snapshot Capture): capturing a single still
image of the current camera view from the app, for authenticated users.

## Scenario: Capturing a snapshot to share in a message

**Scenario ID:** SCN-042
**Feature ID:** FEAT-014

**Persona:** Priya is watching live view and wants to quickly share a still image of a delivery
truck outside with a family member via text.

1. Priya taps the snapshot/still-capture button while watching live view.
2. Within a moment, the app captures a still image of the current view and saves it to her
   phone's gallery (or an in-app clip library), ready to share.
3. The captured image reflects what was actually on screen at the moment she tapped, not a
   noticeably later or earlier frame.

**What the user expects:** a quick tap gives her a shareable still image of exactly what she was
just looking at.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a snapshot capture control during live view, saving a
  JPEG still of the current frame to the user's device (or in-app library) as an authenticated
  request to the camera.
- **[camera-firmware]** The camera shall serve a JPEG snapshot of its current view to an
  authenticated client on request, reflecting a frame close to the time of the request rather
  than a stale cached image.

## Scenario: Snapshot request fails while the camera is unreachable

**Scenario ID:** SCN-043
**Feature ID:** FEAT-014

**Persona:** Priya tries to capture a snapshot while the camera has lost connectivity.

1. Priya taps the snapshot button.
2. The app reports, after a short timeout, that the snapshot couldn't be captured, rather than
   silently failing or saving a blank/placeholder image.
3. She can retry once the camera is reachable again.

**What the user expects:** a failed snapshot attempt is obvious, not a silent no-op or a broken
saved image she only discovers later.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show an explicit error when a snapshot request fails or times
  out, rather than silently discarding the request or saving an invalid image.
