---
feature_id: FEAT-124
status: draft
target_fr_docs: [FR-wifi-provisioning.md]
---

# Scenario: WiFi-Provisioning Portal — Network Recovery Without Data/Ownership Loss

Covers the WiFi-provisioning-portal side of FEAT-124: the on-device AP-mode/BLE setup portal
used when recovering an existing, already-owned camera's network connection.

## Scenario: User re-provisions a camera's WiFi through its own setup portal

**Scenario ID:** SCN-464
**Feature ID:** FEAT-124

**Persona:** Priya's camera has fallen back into its local setup-AP mode because it can't reach
the (changed) home WiFi; she connects to it directly to reconfigure.

1. Priya connects her phone to the camera's own temporary setup network and opens its
   provisioning portal page.
2. The portal presents itself as reconfiguring an existing camera (showing the camera's known
   identity/serial) rather than a blank first-time setup wizard.
3. Priya enters the new WiFi network name and password; the camera applies them and attempts
   to join the new network.
4. On successful reconnection, the camera resumes normal operation with its ownership pairing,
   recorded local clips, and all configuration exactly as before.

**What the user expects:** the setup portal recognizes this is a known camera being
reconnected, not a stranger device being provisioned from zero.

> **Review:** ⏳ Pending

### Derived Requirements

- **[wifi-provisioning]** The provisioning portal shall detect and display that it is
  reconfiguring network settings for an already-provisioned, owned camera, distinguishing this
  from first-time setup.
- **[wifi-provisioning]** The portal shall apply only new network credentials during a recovery
  re-provision, leaving ownership pairing, recorded clips, and all other on-device
  configuration untouched.
- **[camera-firmware]** The camera shall fall back to its local setup-AP/BLE portal mode when it
  cannot join its previously configured WiFi network, without erasing its existing ownership
  state or stored recordings in the process.

## Scenario: New WiFi credentials are entered incorrectly

**Scenario ID:** SCN-465
**Feature ID:** FEAT-124

**Persona:** Priya mistypes the new WiFi password during the recovery flow.

1. The camera attempts to join the new network, fails, and falls back to its setup-AP portal
   mode again rather than getting stuck in a failed, unreachable state.
2. The portal reports the connection failure plainly (e.g. "couldn't join — check the
   password") so Priya knows to retry rather than assuming the camera is broken.
3. Priya retries with the correct password, and the camera connects successfully; nothing about
   the earlier failed attempt affected recordings or ownership.

**What the user expects:** a typo during recovery is a minor, obviously-recoverable mistake,
not something that leaves the camera in an unclear or damaged state.

> **Review:** ⏳ Pending

### Derived Requirements

- **[wifi-provisioning]** The camera shall fall back to setup-AP portal mode automatically if
  newly-provided WiFi credentials fail to connect, and the portal shall report the specific
  failure to the user rather than leaving the attempt unresolved.
- **[wifi-provisioning]** A failed credential-update attempt shall have no effect on the
  camera's stored recordings or ownership/pairing state.

## Scenario: Power is lost mid-provisioning during recovery

**Scenario ID:** SCN-466
**Feature ID:** FEAT-124

**Persona:** The camera loses power (e.g. a brief outage) at the exact moment Priya submits new
WiFi credentials through the portal.

1. On regaining power, the camera boots back into either its prior working network
   configuration or, failing that, its setup-AP portal mode — never a corrupted, undefined
   configuration state.
2. Local recordings stored before the interruption remain intact and playable; ownership
   pairing is unaffected.
3. Priya can resume the recovery flow from the beginning without any special unbricking steps.

**What the user expects:** even the worst-case timing (power loss mid-write) can't destroy her
recordings or her ownership of the device.

> **Review:** ⏳ Pending

### Derived Requirements

- **[wifi-provisioning]** Network-credential updates shall be written such that a power loss
  mid-write leaves the camera in a well-defined state (prior working config or setup-AP mode),
  never a corrupted or unbootable one.
- **[camera-firmware]** Local recording storage and ownership/pairing state shall be stored
  independently of network-configuration writes, so a failure in one cannot corrupt or erase
  the other.
