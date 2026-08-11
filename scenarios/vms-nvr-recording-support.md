---
feature_id: FEAT-034
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — NVR Recording Support

Covers the fleet-operator-facing side of FEAT-034: continuous NVR recording that is mandatory
on PoE/community SKUs and optional (user-toggleable) on home SKUs added to a VMS.

## Scenario: Mandatory continuous recording on a PoE/community-SKU camera

**Scenario ID:** SCN-120
**Feature ID:** FEAT-034

**Persona:** Marcus, operating a community VMS, adds a new PoE camera to a shared-property site.

1. Marcus adds the camera to the VMS. Because it's a PoE/community SKU, the VMS enrolls it with
   continuous NVR recording already on, with no toggle to turn it off.
2. Marcus looks for a recording on/off control for this camera and finds only mode selection
   (Continuous/Scheduled/Event-Triggered per FEAT-032), not an outright disable option.
3. If Marcus attempts an action that would effectively disable recording (e.g. via an API or a
   bulk action meant for home-SKU cameras), the VMS rejects it with an explanation that this
   SKU class requires recording.

**What the user expects:** on a community site, he can't accidentally turn off recording on a
camera that's supposed to always be recording — the system won't let that mistake happen.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall enroll a PoE/community-SKU camera with NVR recording mandatory,
  offering only recording-mode selection (per FEAT-032) and no control to disable recording
  outright.
- **[vms]** The VMS shall reject any request (including bulk actions) that would disable NVR
  recording on a camera whose SKU class mandates it, with an explanit reason.
- **[camera-firmware]** The camera shall report its SKU class (or an equivalent
  recording-mandatory flag) to the VMS at enrollment so the correct recording policy is applied
  automatically.

## Scenario: Optional recording toggle on a home-SKU camera

**Scenario ID:** SCN-121
**Feature ID:** FEAT-034

**Persona:** Priya adds her home-SKU camera to a VMS instance she also uses to manage a couple
of community cameras for a neighbor.

1. Priya adds the home-SKU camera. The VMS enrolls it with NVR recording available but off by
   default.
2. She finds an explicit on/off control for NVR recording specific to this camera, distinct from
   the mandatory-recording community cameras in the same VMS instance.
3. She turns NVR recording on for it and configures a mode as usual.

**What the user expects:** the VMS treats her home camera's recording as genuinely optional, and
doesn't force community-SKU rules onto a camera that doesn't need them.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide an explicit NVR recording on/off control for home-SKU
  cameras, defaulting to off, distinct from the mandatory-recording treatment of PoE/community
  SKUs.
- **[vms]** The VMS shall visually distinguish, in any multi-camera view, cameras with mandatory
  recording from cameras with optional recording currently turned off.

## Scenario: NVR storage exhausted while mandatory recording continues

**Scenario ID:** SCN-122
**Feature ID:** FEAT-034

**Persona:** Marcus's community site NVR storage volume approaches full while several
mandatory-recording PoE cameras are still actively writing.

1. As storage fills, the VMS begins overwriting the oldest footage per the configured retention
   policy (see FEAT-037) rather than stopping recording outright, since recording is mandatory
   for these cameras.
2. The VMS surfaces a clear storage-pressure warning on the fleet health view (see FEAT-038) so
   Marcus knows the effective retention window is shrinking, even though recording itself never
   silently stops.
3. If overwrite itself becomes impossible (e.g. a hardware fault), the VMS treats it as a
   critical failure condition rather than continuing to claim recording is healthy.

**What the user expects:** mandatory recording keeps running as promised under normal storage
pressure, but he's warned before it becomes a real problem, and told immediately if it ever
actually breaks.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** For a camera with mandatory NVR recording, the VMS shall continue recording under
  storage pressure by overwriting per the configured retention policy rather than stopping
  recording, while surfacing a storage-pressure warning distinct from a hard failure.
- **[vms]** The VMS shall treat an NVR storage fault that prevents mandatory recording from
  continuing as a critical health condition, not a silent recording stoppage.
