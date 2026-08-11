---
feature_id: FEAT-163
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Third-Party ONVIF Camera Discovery with Explicit Authorization

Covers FEAT-163: non-NuraEye ONVIF cameras also appear in the WS-Discovery scan, but adding one
requires the operator to manually enter its ONVIF username/password — no auto-pairing.

## Scenario: Operator adds a third-party ONVIF camera by entering its credentials

**Scenario ID:** SCN-585
**Feature ID:** FEAT-163

**Persona:** Marcus, adding an existing third-party ONVIF PTZ camera alongside his NuraEye
cameras during the same office setup.

1. During the same network scan, a non-NuraEye ONVIF camera also appears in the
   discovered-devices list, but visually marked as a "Third-party ONVIF device" distinct from
   the auto-pairing NuraEye entries.
2. Marcus clicks "Add" on it, and instead of pairing automatically, the VMS prompts him to
   manually enter the camera's ONVIF username and password.
3. He enters the correct credentials, and the VMS successfully connects and adds the camera,
   now available alongside his other cameras.

**What the user expects:** he can bring in cameras he already owns from other brands, but the
VMS is upfront that this needs his manual authorization since it isn't a NuraEye device it can
trust to auto-pair.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall include non-NuraEye ONVIF cameras in the WS-Discovery scan results,
  visually distinguished from auto-pairing native cameras.
- **[vms]** The VMS shall require manual ONVIF username/password entry to add a third-party
  ONVIF camera, never auto-pairing it the way a native camera is auto-paired.

## Scenario: Wrong credentials are entered for a third-party camera

**Scenario ID:** SCN-586
**Feature ID:** FEAT-163

**Persona:** Marcus, mistyping the third-party camera's admin password.

1. Marcus enters an incorrect password for the discovered third-party camera.
2. The VMS attempts the ONVIF connection and reports an explicit authentication failure,
   rather than a generic "camera unreachable" error that would wrongly suggest a network
   problem.
3. Marcus corrects the password and retries, successfully adding the camera on the second
   attempt.

**What the user expects:** a wrong password is reported as exactly that, so he doesn't waste
time troubleshooting the network instead of just re-checking his credentials.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall report an explicit authentication failure (distinct from a
  network/unreachable error) when a third-party ONVIF camera rejects the entered credentials.
- **[vms]** The VMS shall allow retrying credential entry for the same discovered camera
  without restarting the whole discovery/add flow.

## Scenario: A third-party camera only partially supports the needed ONVIF profile

**Scenario ID:** SCN-587
**Feature ID:** FEAT-163

**Persona:** Marcus, adding an older third-party camera that supports basic ONVIF Profile S
(live streaming) but not the newer Profile T features the VMS prefers.

1. Marcus adds the camera successfully with valid credentials.
2. The VMS detects the camera's ONVIF service only supports a limited profile set, and
   communicates this clearly (e.g. "Live view supported; advanced motion/event features not
   supported by this device") rather than silently exposing controls for capabilities the
   camera can't actually do.
3. Marcus can still use the camera for what it does support, without the VMS pretending it has
   full feature parity with a native camera.

**What the user expects:** bringing in an older or limited third-party camera doesn't produce
a confusing set of controls that quietly fail — the VMS tells him upfront what will and won't
work.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect a third-party ONVIF camera's actual supported profile/feature
  set at add-time and communicate any limitations plainly, rather than exposing controls for
  unsupported capabilities.
</content>
