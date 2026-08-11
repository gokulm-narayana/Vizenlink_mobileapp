---
feature_id: FEAT-162
status: draft
target_fr_docs: [FR-vms.md, FR-wifi-provisioning.md]
---

# Scenario: VMS — NVR Plug-and-Play Camera Discovery/Pairing

Covers FEAT-162: discovering NuraEye/native cameras on the local network via WS-Discovery and
adding them with one click, without manual IP entry.

## Scenario: Operator discovers a NuraEye camera on the LAN and adds it with a single click

**Scenario ID:** SCN-582
**Feature ID:** FEAT-162

**Persona:** Marcus, setting up a new NVR at a small office, adding cameras as they're
physically installed.

1. Marcus opens the VMS's "Add Camera" screen, and it automatically scans the local network for
   cameras, without him typing any IP addresses.
2. Within a few seconds, the newly installed NuraEye camera appears in a discovered-devices
   list, already identified by model and default name.
3. Marcus clicks "Add" next to it, and the VMS pairs and configures the camera automatically,
   with no manual IP entry, credentials, or extra steps required.
4. The camera immediately appears live in his camera list.

**What the user expects:** adding a NuraEye camera to the NVR should be as close to
zero-configuration as installing the camera itself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall automatically discover NuraEye/native cameras on the local network
  via WS-Discovery and present them in an "Add Camera" list.
- **[vms]** The VMS shall add a discovered native camera with a single confirming action,
  requiring no manual IP address or credential entry.

## Scenario: A discovered camera is already claimed by another NVR

**Scenario ID:** SCN-583
**Feature ID:** FEAT-162

**Persona:** Marcus, whose office recently repurposed a camera that was previously configured
on a different NVR at another location.

1. Marcus sees the camera in his discovery list and clicks "Add."
2. The VMS detects the camera is already paired/claimed by a different NVR and tells Marcus
   clearly, rather than silently taking it over or failing with a generic error.
3. Marcus is offered a path to release/re-claim the camera (e.g. if he confirms he's now the
   rightful owner) rather than being stuck.

**What the user expects:** a camera moving between deployments is a normal event, and the VMS
handles the conflict honestly instead of pretending the camera was free.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect when a discovered camera is already claimed by a different
  NVR/VMS instance and present that conflict explicitly, rather than silently re-pairing or
  failing generically.
- **[vms]** The VMS shall offer a guided release/re-claim path for a camera the operator
  confirms should now belong to this NVR.

## Scenario: The discovered camera goes offline mid-pairing

**Scenario ID:** SCN-584
**Feature ID:** FEAT-162

**Persona:** Marcus, adding a camera just as its network cable is bumped loose during the same
install visit.

1. Marcus clicks "Add" on the discovered camera, and pairing begins.
2. Partway through, the camera drops off the network (loose cable).
3. The VMS detects the failed pairing attempt and reports it plainly — "camera became
   unreachable during setup" — rather than leaving the camera in an ambiguous half-added state.
4. Once Marcus reseats the cable, the camera reappears in the discovery list and he can retry
   the add from scratch, with no leftover partial configuration to clean up.

**What the user expects:** a mid-setup network hiccup is recoverable — the VMS doesn't leave a
broken half-added camera behind.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect a pairing failure caused by the camera going unreachable
  mid-setup, report it explicitly, and leave no partial/orphaned camera entry behind.
- **[vms]** The VMS shall allow a clean retry of the add flow once the camera is reachable
  again.
</content>
