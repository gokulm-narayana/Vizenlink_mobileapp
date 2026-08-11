---
feature_id: FEAT-038
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Recording & Storage Failure Detection

Covers the fleet-operator-facing side of FEAT-038: surfacing NVR/VMS-side storage and
recording-service failures as a critical, fleet-visible health state.

## Scenario: NVR storage volume failure surfaced on the fleet health dashboard

**Scenario ID:** SCN-135
**Feature ID:** FEAT-038

**Persona:** Marcus manages a community site whose NVR storage volume develops a read-only fault
(e.g. a failing disk).

1. The VMS detects it can no longer write new recordings to the affected storage volume.
2. The fleet health dashboard shows a critical, unmissable entry for the affected site/volume,
   distinct from ordinary camera-offline or connectivity warnings.
3. The dashboard identifies which cameras are affected (i.e. whose recording now depends on the
   failed volume) so Marcus knows the scope of the impact immediately, not just that "something"
   is wrong.

**What the user expects:** a storage-hardware problem doesn't quietly turn into a gap in
evidence weeks later — he's told immediately, and told exactly what's affected.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect NVR storage write failures (full, unavailable, read-only,
  file-system error) and surface them as a critical entry on the fleet health dashboard,
  distinct from connectivity-only warnings.
- **[vms]** The VMS shall identify, for a storage failure, every camera whose recording is
  currently affected by it.

## Scenario: Recording-service failure on one camera in a multi-camera site

**Scenario ID:** SCN-136
**Feature ID:** FEAT-038

**Persona:** Priya's site has healthy storage overall, but the NVR's recording process for one
specific camera crashes or hangs while the rest of the site keeps recording fine.

1. The VMS detects that one camera has stopped receiving new recorded segments despite the
   camera itself being online and the shared storage volume being healthy.
2. The VMS flags this as a recording-service failure scoped to that single camera, not a
   site-wide storage issue, so Priya isn't misled into checking the wrong thing.
3. Priya can see, from the health dashboard, exactly when recording for that camera last
   succeeded.

**What the user expects:** the VMS tells him precisely which layer failed — camera, storage, or
recording service — so troubleshooting doesn't start in the wrong place.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall distinguish a per-camera recording-service failure from a storage-wide
  failure, flagging each condition separately on the health dashboard.
- **[vms]** The VMS shall display the last successful recording timestamp for a camera flagged
  with a recording-service failure.
