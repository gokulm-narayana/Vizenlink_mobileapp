---
feature_id: FEAT-005
status: decomposed
target_fr_docs: [FR-vms.md, FR-onvif-stack.md]
---

# Scenario: VMS — Day/Night Mode

Covers the fleet-operator-facing side of FEAT-005 (Day/Night Switching & IR Night Vision): the
same Auto/Day/Night mode capability, controlled from the VMS's imaging/settings surface rather
than the mobile app, for an operator managing multiple cameras across a site.

## Scenario: Operator sets a camera to manual Night mode from the Imaging panel

**Scenario ID:** SCN-006
**Feature ID:** FEAT-005

**Persona:** Marcus, a security operator monitoring a small office site through the VMS, notices
one camera's daytime image is washed out in a shaded loading-dock area and wants to force
infrared capture there permanently rather than rely on Auto.

1. Marcus opens that camera's Imaging Settings panel in the VMS and finds the Day/Night mode
   control alongside the other image-tuning settings (brightness, contrast, etc.).
2. He switches the mode from "Auto" to "Night."
3. The VMS applies the change and the camera's live thumbnail/stream in the grid updates to the
   infrared image within a few seconds.
4. The panel now shows "Night" as the current mode for that camera, distinguishing it from other
   cameras on the site still left on Auto.

**What the user expects:** he can override day/night behavior per-camera from the same place he
already tunes other image quality settings, without needing a separate tool.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[vms]** The VMS Imaging Settings panel shall expose a Day/Night mode control
  (Auto/Day/Night) alongside existing image-tuning controls for the selected camera.
- **[vms]** The VMS shall reflect each camera's current day/night mode distinctly per-camera in
  any multi-camera view (grid, camera list), so an operator can tell at a glance which cameras
  are on Auto vs. manually overridden.
- **[camera-firmware]** The camera shall accept a Day/Night/Auto mode command issued via the
  VMS's ONVIF Imaging control path and apply it identically to a mode command issued through any
  other authorized client.

## Scenario: Mode change fails to confirm

**Scenario ID:** SCN-007
**Feature ID:** FEAT-005

**Persona:** Marcus tries to change a camera's mode from the VMS, but the camera is momentarily
unreachable (e.g. a network blip on that segment).

1. Marcus selects "Night" for the camera in the Imaging Settings panel.
2. The VMS attempts to apply the setting and, after a timeout, reports that the change could not
   be confirmed rather than showing it as applied.
3. The panel continues to display the camera's last known mode.
4. Marcus can retry the change once the camera is reachable again, and can see from the site's
   camera-status view that this camera is currently unreachable, explaining the failure.

**What the user expects:** the VMS never shows a setting as successfully changed when it
couldn't actually confirm the camera applied it — a false "success" would be worse than an
honest failure for someone managing a whole site's worth of cameras.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[vms]** The VMS shall not mark a Day/Night mode change as applied until the camera
  acknowledges it; on failure or timeout it shall surface an explicit error tied to that camera.
- **[camera-firmware]** The camera's ONVIF Imaging service shall return a fault/error response
  (rather than a silent no-op) when a mode-change request cannot be applied.

## Scenario: Reviewing day/night mode across a multi-camera site

**Scenario ID:** SCN-008
**Feature ID:** FEAT-005

**Persona:** Marcus wants to audit, across all cameras at a community site, which ones are left
on Auto and which have been manually overridden — for instance to check whether a technician's
temporary Night override from a prior ticket was ever reverted.

1. Marcus opens the site's multi-camera view in the VMS.
2. For each camera, he can see its current day/night mode (Auto, Day, or Night) without opening
   each camera's individual Imaging Settings panel one at a time.
3. He spots one camera still stuck on a manual "Night" override from a past visit and reverts it
   to Auto directly from this overview.

**What the user expects:** he doesn't have to click into every single camera to know whether
any of them have a manual override left on that should have been cleared.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-level view showing each camera's current day/night
  mode without requiring the operator to open each camera's individual settings panel.
- **[vms]** The VMS shall allow reverting a camera's mode to Auto directly from this fleet-level
  view, not only from the per-camera Imaging Settings panel.
