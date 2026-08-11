---
feature_id: FEAT-029
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Speaker/Mic Volume Control

Covers the fleet-operator-facing side of FEAT-029 (Speaker/Mic Volume Control): tuning speaker
output and microphone gain per camera from the VMS, useful for standardizing audio behavior across
a site's cameras.

## Scenario: Installer standardizes speaker volume across a site's cameras

**Scenario ID:** SCN-087
**Feature ID:** FEAT-029

**Persona:** Dana is commissioning several cameras at a community site and wants their prerecorded
warning messages to all be audible at a consistent, adequate volume rather than each installer
default varying by camera model.

1. Dana opens each camera's audio settings in the VMS and sets speaker volume to a consistent
   target level, or applies the same value across multiple cameras of the same model at once.
2. The VMS confirms each camera's applied volume, and she test-plays the warning message on one
   camera to verify it's audible at the intended distance.

**What the user expects:** consistent audio behavior across a site's cameras is something she can
set up efficiently rather than tuning each camera in isolation with no way to compare.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide per-camera speaker volume and microphone gain controls, with the
  ability to apply the same value across multiple selected cameras at once.
- **[camera-firmware]** The camera shall accept speaker volume and microphone gain configuration
  through the VMS's authorized control path identically to a setting applied via the mobile app.

## Scenario: Operator lowers microphone gain on a camera picking up too much site noise

**Scenario ID:** SCN-088
**Feature ID:** FEAT-029

**Persona:** Marcus notices that a camera near a community site's HVAC unit captures audio
dominated by mechanical noise, making its recordings and two-way talk sessions hard to use.

1. Marcus opens that camera's audio settings in the VMS and lowers its microphone gain.
2. The VMS confirms the change, and he verifies via a short live-view check that the audio is
   noticeably clearer.
3. Other cameras at the site, not affected by this noise source, keep their own independently-set
   gain levels.

**What the user expects:** he can fix an audio problem specific to one camera's environment
without it affecting any other camera's settings.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall apply microphone gain changes on a strictly per-camera basis, with no
  effect on any other camera's independently-configured gain.
