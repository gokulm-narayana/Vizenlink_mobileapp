---
feature_id: FEAT-002
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Mobile Live-View Substream

Covers the fleet-operator-facing side of FEAT-002 (Mobile Live-View Substream): configuring the
camera's lower-resolution second stream from the VMS, independent of the main recording/analysis
stream, and using it where a lighter stream benefits the VMS itself (e.g. large camera grids).

## Scenario: Operator configures the substream profile for a site's cameras

**Scenario ID:** SCN-012
**Feature ID:** FEAT-002

**Persona:** Marcus, a security operator, is onboarding a new community site with many cameras and
wants the mobile substream tuned lower than the installer default, since most residents view from
phones on cellular data.

1. Marcus opens a camera's stream settings in the VMS and finds the mobile substream configuration
   separate from the main stream's recording settings.
2. He lowers the substream's resolution/bitrate to reduce residents' typical mobile data usage.
3. The VMS confirms the change was applied and shows the substream's current settings alongside
   the main stream's, clearly labeled as the distinct mobile profile.
4. He repeats this across the site's cameras from the same panel without needing to configure each
   one through a separate tool.

**What the user expects:** the mobile substream is a first-class, separately tunable setting in
the same place he manages other per-camera stream settings, not something buried or inaccessible
from the VMS.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose the camera's mobile substream resolution/bitrate as a distinct,
  independently configurable setting from the main stream's settings, in the same per-camera
  stream configuration panel.
- **[vms]** The VMS shall confirm and display the substream's currently-applied settings after a
  change, distinct from the main stream's settings.
- **[camera-firmware]** The camera shall accept substream resolution/bitrate configuration
  independently of main-stream configuration, applying changes without disrupting the main
  stream's ongoing recording.

## Scenario: Substream configuration fails to apply to an unreachable camera

**Scenario ID:** SCN-013
**Feature ID:** FEAT-002

**Persona:** Marcus tries to lower a camera's substream bitrate from the VMS, but that camera has
temporarily dropped off the network.

1. Marcus changes the substream setting for the camera and confirms.
2. The VMS attempts to apply the change and, after a timeout, reports that it could not confirm
   the camera received the update rather than showing the new value as active.
3. The camera's entry in the site view shows it as currently unreachable, so Marcus understands
   why the change didn't apply.
4. Once the camera reconnects, Marcus can retry the change, or the VMS can offer to reapply it
   automatically now that the camera is back.

**What the user expects:** a configuration change never appears to have taken effect on a camera
the VMS couldn't actually reach.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall not display a substream configuration change as applied until the target
  camera acknowledges it; on timeout/failure it shall show an explicit per-camera error.
- **[vms]** The VMS shall visibly flag a camera as unreachable in the site view whenever a
  configuration attempt against it fails to confirm, rather than only showing a silent error on
  the settings panel.
