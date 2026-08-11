---
feature_id: FEAT-006
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — WDR / Backlight Handling

Covers the fleet-operator-facing side of FEAT-006 (WDR / Backlight Handling): setting WDR per
camera from the VMS's imaging panel, alongside other image-tuning controls.

## Scenario: Operator enables WDR for a gate camera from the Imaging panel

**Scenario ID:** SCN-016
**Feature ID:** FEAT-006

**Persona:** Marcus manages a community site and notices the entrance-gate camera's daytime feed
consistently loses detail on vehicles/faces against the bright sky behind them.

1. Marcus opens that camera's Imaging Settings panel in the VMS.
2. He finds and enables the WDR control alongside brightness/contrast and other image settings.
3. The VMS confirms the change and the camera's live thumbnail updates to show recovered detail
   in the previously blown-out background.
4. The panel shows WDR as "On" for that camera specifically, distinct from other cameras on the
   site.

**What the user expects:** WDR is just one more per-camera image-tuning control available where
he already manages the rest of a camera's image quality, with no separate tool required.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS Imaging Settings panel shall expose a WDR on/off control per camera, alongside
  existing image-tuning controls, for cameras that report WDR support.
- **[camera-firmware]** The camera shall accept a WDR on/off command through the same imaging
  control path used for other image-quality settings and apply it without restarting the video
  pipeline.

## Scenario: Auditing WDR settings across a multi-camera site

**Scenario ID:** SCN-017
**Feature ID:** FEAT-006

**Persona:** Marcus wants to check, across all entrance/gate-facing cameras at a site, which ones
have WDR enabled after a batch of new installs.

1. Marcus opens the site's multi-camera view.
2. He can see each camera's current WDR state without opening every individual Imaging Settings
   panel.
3. He finds two gate cameras where WDR was left off by the installer and enables it directly from
   this overview.

**What the user expects:** reviewing and fixing a setting across many cameras doesn't require
visiting each one individually.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-level view showing each camera's current WDR state
  (where supported) without requiring the operator to open each camera's individual settings.
- **[vms]** The VMS shall allow toggling WDR directly from this fleet-level view for cameras that
  support it.
