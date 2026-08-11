---
feature_id: FEAT-007
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md]
---

# Scenario: VMS — Installer/Admin Video Quality Profile Controls

Covers FEAT-007 (Installer/Admin Video Quality Profile Controls): deep, installer/admin-only
tuning of stream bitrate, frame rate, GOP, resolution, and quality profile — deliberately not
exposed to homeowners in the mobile app, since incorrect values here can degrade recording
quality, storage usage, or bandwidth for an entire site.

## Scenario: Installer tunes a camera's main-stream profile during commissioning

**Scenario ID:** SCN-018
**Feature ID:** FEAT-007

**Persona:** Dana, an installer commissioning a new camera at a client site with a limited
upstream bandwidth budget, needs to bring the main recording stream's bitrate down from its
factory default without sacrificing the resolution the client is paying for.

1. Dana opens the camera's advanced video-quality settings in the VMS, accessible only to
   installer/admin-level accounts.
2. She adjusts the target bitrate, frame rate, and GOP length as separate, individually-tunable
   fields — not a single bundled "quality" slider.
3. She applies the change and the VMS confirms the new profile is active, showing the resulting
   values (not just what she requested, in case the camera clamped or rounded them).
4. She verifies the change by opening live view for the camera and confirming recording continues
   without interruption.

**What the user expects:** she has real, itemized control over each encoding parameter that
determines bandwidth and storage footprint, not just a coarse quality preset.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose separate, itemized controls for stream bitrate, frame rate, GOP
  length, resolution, and quality profile, restricted to installer/admin-level accounts, distinct
  from any basic/coarse quality option shown to lower-privilege users.
- **[vms]** The VMS shall display the camera's actually-applied values after a profile change
  (which may differ from the requested values if the camera clamps them to supported bounds),
  not merely echo back what was requested.
- **[camera-firmware]** The camera shall accept independently-settable bitrate, frame rate, GOP
  length, and resolution parameters per stream, applying a change without dropping the stream or
  interrupting an in-progress recording.

## Scenario: Requested profile exceeds the camera's supported bounds

**Scenario ID:** SCN-019
**Feature ID:** FEAT-007

**Persona:** Dana attempts to set a bitrate and resolution combination that exceeds what this
camera model's encoder can sustain.

1. Dana enters values beyond the camera's supported range for the requested resolution.
2. Rather than silently accepting and clamping the request without telling her, the VMS reports
   that the requested combination isn't supported and shows the camera's actual valid range for
   that resolution.
3. Dana adjusts her inputs within the reported bounds and reapplies successfully.

**What the user expects:** an admin-level tool that lets her push values right up to the hardware
limit still tells her clearly when she's stepped past it, instead of quietly substituting a
different value than what she asked for.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall validate a requested video-quality profile against the camera's reported
  supported bounds before applying it, and if out of bounds, report the specific rejected
  field(s) and the valid range rather than silently clamping.
- **[camera-firmware]** The camera shall reject (with a specific error) a video-quality profile
  request that exceeds its encoder's supported bounds for the requested resolution, rather than
  silently clamping to the nearest supported value.

## Scenario: A non-admin account cannot reach these controls

**Scenario ID:** SCN-020
**Feature ID:** FEAT-007

**Persona:** A community-site staff member with a standard VMS viewer account, not an installer or
admin role, is exploring the VMS's settings menus.

1. The staff member does not see the advanced video-quality profile controls anywhere in their
   accessible settings.
2. If they somehow reach a direct link to that settings screen (e.g. a bookmarked URL), the VMS
   denies access rather than showing the controls read-only or silently allowing changes.

**What the user expects:** deep encoding controls that can affect an entire site's bandwidth and
storage stay restricted to the roles authorized to change them, with no accidental exposure.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall restrict access to video-quality profile controls (bitrate, frame rate,
  GOP, resolution, quality profile) to installer/admin-level roles, denying both UI access and
  the underlying request for any lower-privilege account.
