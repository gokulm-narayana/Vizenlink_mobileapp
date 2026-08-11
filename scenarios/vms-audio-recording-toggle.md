---
feature_id: FEAT-022
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-access-control.md]
---

# Scenario: VMS — Audio Recording Toggle & Indicator

Covers the fleet-operator-facing side of FEAT-022 (Audio Recording Toggle & Indicator): setting
audio recording policy per camera or per site from the VMS, honoring stricter consent
requirements in community/office deployments.

## Scenario: Admin sets audio recording policy for a community site

**Scenario ID:** SCN-065
**Feature ID:** FEAT-022

**Persona:** Marcus, an admin, is configuring a new community site where local policy requires
audio recording to be off by default across all common-area cameras, enabled only where
specifically justified.

1. Marcus opens the site's recording policy settings in the VMS and confirms audio recording
   defaults to off for all cameras in this site.
2. For one camera at a manned entry gate where audio has been specifically approved, he enables
   audio recording for that camera only.
3. The VMS shows, per camera, whether audio recording is on or off, alongside video recording
   status, in the fleet view.

**What the user expects:** he can enforce a stricter site-wide audio policy while still making
narrow, deliberate per-camera exceptions where justified.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support a site-level default for audio recording (on/off) applied to new
  cameras at that site, with the ability to override it per camera.
- **[vms]** The VMS fleet view shall show audio recording status per camera distinctly from video
  recording status.
- **[camera-firmware]** The camera shall accept and enforce an audio recording on/off setting
  independent of its video recording state, consistent with a setting applied via the mobile app.

## Scenario: Auditing which cameras have audio recording enabled

**Scenario ID:** SCN-066
**Feature ID:** FEAT-022

**Persona:** Marcus needs to confirm, ahead of a legal/compliance review, exactly which cameras
at a site currently have audio recording enabled.

1. Marcus opens the fleet view and filters/sorts cameras by audio recording status.
2. He identifies every camera with audio currently on, cross-checks each against its documented
   justification, and disables audio on one camera where the justification no longer applies.

**What the user expects:** answering "which cameras record audio right now" is a quick fleet-wide
query, not a camera-by-camera manual check.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow filtering/sorting the fleet view by audio recording status, so an
  operator can identify all cameras with audio currently enabled without checking each
  individually.
