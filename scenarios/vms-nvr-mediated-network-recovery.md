---
feature_id: FEAT-168
status: draft
target_fr_docs: [FR-vms.md, FR-wifi-provisioning.md]
---

# Scenario: VMS — NVR-Mediated Network Recovery

Covers FEAT-168: for wired/multi-camera sites, network recovery routes through the NVR rather
than each camera individually re-provisioning over BLE/Soft-AP.

## Scenario: Wired multi-camera site recovers network via the NVR

**Scenario ID:** SCN-599
**Feature ID:** FEAT-168

**Persona:** Farid, whose office site's network briefly goes down (e.g. router reboot)
affecting a wired NVR and multiple cameras.

1. The site's network drops, and all cameras' connections to the NVR drop simultaneously.
2. Once the network is restored, the NVR reconnects first and then coordinates reconnecting
   each camera through its existing wired/NVR-managed provisioning, rather than each camera
   independently trying to re-provision itself over BLE or Soft-AP.
3. Farid sees, from the VMS, a normal "reconnecting..." status per camera followed by them all
   coming back online in short order — no individual per-camera setup steps required from him.

**What the user expects:** a shared network hiccup at a multi-camera wired site recovers as one
coordinated event through the NVR, not as ten separate per-camera recovery flows.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall coordinate network recovery for its managed wired cameras through
  the NVR's existing connection/provisioning path, rather than requiring each camera to
  independently re-provision over BLE/Soft-AP.
- **[vms]** The VMS shall show per-camera reconnection status during a coordinated network
  recovery event.

## Scenario: A camera fails to rejoin through the NVR path and needs an admin nudge before falling back

**Scenario ID:** SCN-600
**Feature ID:** FEAT-168

**Persona:** Farid, whose network has otherwise recovered, but one camera doesn't reconnect
through the normal NVR-mediated path after several minutes.

1. Farid notices one camera still shows as offline in the VMS well after the rest of the site
   recovered.
2. The VMS offers a "retry NVR-mediated reconnect" action for that specific camera before
   suggesting anything more drastic.
3. Only if that retry also fails does the VMS suggest the camera may need individual
   BLE/Soft-AP recovery as a fallback, rather than jumping straight to that heavier path.

**What the user expects:** recovery always tries the lighter, NVR-coordinated path first for a
wired multi-camera site, reserving individual per-camera recovery for when that genuinely
doesn't work.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall offer a targeted NVR-mediated reconnect retry for a single camera
  that failed to rejoin automatically, before presenting individual BLE/Soft-AP recovery as a
  fallback option.
</content>
