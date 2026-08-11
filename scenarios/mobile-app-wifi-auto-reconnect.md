---
feature_id: FEAT-112
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — WiFi Auto-Reconnect

Covers the homeowner-facing side of FEAT-112: the camera automatically restoring its WiFi
connection and resuming normal operation after a router/WiFi outage, with no manual reboot or
re-provisioning.

## Scenario: Router reboot during a firmware update takes the camera's WiFi down briefly

**Scenario ID:** SCN-405
**Feature ID:** FEAT-112

**Persona:** Marcus's router restarts to apply its own firmware update, briefly dropping WiFi for
every device on his network, including the camera.

1. Marcus's camera shows "Offline" in the app during the router's brief downtime, same as any
   fully-offline condition (per FEAT-084/085).
2. Once the router comes back up and starts broadcasting WiFi again, the camera reconnects on
   its own within a short time — Marcus never has to touch the camera, its app settings, or
   re-run any setup/provisioning flow.
3. The app's status reverts to "Online" and the offline duration is logged (per FEAT-085) as a
   short, resolved outage.

**What the user expects:** a routine router restart shouldn't require him to do anything to get
his camera back — it should reconnect exactly as automatically as his phone or laptop would.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show a camera's WiFi-outage-and-recovery cycle using the
  standard offline/online status transitions (FEAT-084/085), requiring no distinct user-facing
  handling or manual step.
- **[camera-firmware]** The camera shall automatically detect a lost WiFi association and
  continuously attempt reconnection using its previously stored credentials, without requiring
  a manual reboot or re-entry into provisioning/setup mode.

## Scenario: WiFi credentials are still valid but the router changes channel/frequency band

**Scenario ID:** SCN-406
**Feature ID:** FEAT-112

**Persona:** Priya's router auto-switches to a different WiFi channel to avoid interference,
briefly dropping the camera's association even though the network name and password are
unchanged.

1. Priya's camera reconnects automatically once it rediscovers the network on its new channel,
   without her needing to re-provision it or re-enter her WiFi password.
2. The app shows a brief offline blip in history but nothing requiring her attention or action.
3. This is distinct from a scenario where the WiFi password itself actually changes (which would
   require the FEAT-124 re-provisioning flow instead) — here, since credentials are still valid,
   no user-facing re-setup is ever triggered.

**What the user expects:** as long as her WiFi credentials haven't actually changed, any
disruption to the connection — even one caused by the router's own automatic behavior — resolves
itself without her needing to do anything.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall never prompt the user to re-provision/re-enter WiFi credentials
  for a reconnect that succeeds using already-stored, still-valid credentials, distinguishing
  this from a credential-change scenario that genuinely requires re-provisioning.
- **[camera-firmware]** The camera shall retry WiFi association across standard channel/band
  changes using its stored credentials, without requiring any change to its provisioning state.
