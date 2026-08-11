---
feature_id: FEAT-023
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-access-control.md]
---

# Scenario: VMS — Two-Way Talk

Covers the fleet-operator-facing side of FEAT-023 (Two-Way Talk): a monitoring-station operator
speaking through a community/office camera, permission-gated by VMS role.

## Scenario: Operator addresses someone loitering at a gate

**Scenario ID:** SCN-070
**Feature ID:** FEAT-023

**Persona:** Marcus, monitoring a community entrance camera, notices someone lingering near a
gate after hours and wants to speak to them directly.

1. Marcus opens that camera's live view in the VMS and activates two-way talk.
2. His voice plays through the camera's speaker, and he can hear the person's response through
   the camera's microphone audio.
3. The VMS logs that a talk session occurred on this camera, with operator identity and timestamp,
   as part of the site's activity record.

**What the user expects:** he can address someone in real time from the monitoring station, and
that action is auditable afterward as part of the site's operational log.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a two-way talk control from a camera's live view, restricted to
  operator accounts with talk permission.
- **[vms]** The VMS shall log each two-way talk session (camera, operator, start/end time) as part
  of the site's activity record.
- **[camera-firmware]** The camera shall support a two-way talk session initiated via the VMS's
  authorized request path identically to one initiated via the mobile app.

## Scenario: A read-only monitoring account cannot initiate talk

**Scenario ID:** SCN-071
**Feature ID:** FEAT-023

**Persona:** A junior staff member with a read-only VMS account is monitoring cameras and wants to
speak to someone but does not have talk permission.

1. They open a camera's live view and find the talk control disabled or absent.
2. If they attempt a direct request anyway, the VMS/camera denies it rather than silently allowing
   it.

**What the user expects:** talk permission is enforced by the VMS's role system just as
consistently as any other privileged action, not left to the UI alone to prevent.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall restrict two-way talk to roles explicitly granted talk permission, and
  reject the underlying request server-side even if a client attempts to bypass the UI.
