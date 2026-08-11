---
feature_id: FEAT-097
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Active Network Interface Indicator

Covers the homeowner-facing side of FEAT-097: showing whether the camera is on WiFi or Ethernet,
pairing WiFi with its RSSI (FEAT-096), and hiding that pairing on Ethernet.

## Scenario: Priya checks how her camera is connected

**Scenario ID:** SCN-359
**Feature ID:** FEAT-097

**Persona:** Priya, curious after reading about signal strength, checks her camera's connection
type.

1. Priya opens device details and sees a simple "Connected via: WiFi" line, with the WiFi signal
   strength indicator shown directly beneath it.
2. On a second camera that's wired via Ethernet, the same screen instead shows "Connected via:
   Ethernet," with no signal-strength row at all — it's not shown grayed-out or "0 bars," it's
   simply not there, since RSSI doesn't apply.
3. She understands immediately which of her cameras is more vulnerable to WiFi interference just
   from this one line, without having to infer it.

**What the user expects:** it's immediately obvious how each camera connects, and the display
doesn't confuse her with an irrelevant, meaningless "signal strength" field on a wired camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display the camera's active network interface (WiFi or
  Ethernet) in device details, and shall show the WiFi signal-strength indicator only when the
  active interface is WiFi.
- **[camera-firmware]** The camera shall report its currently active network interface type as
  part of its status/telemetry.

## Scenario: Camera fails over from WiFi to a wired connection (or vice versa)

**Scenario ID:** SCN-360
**Feature ID:** FEAT-097

**Persona:** Priya's camera is normally on WiFi, but she plugs in an Ethernet cable one day to
test a more stable connection, then unplugs it later.

1. As soon as the camera switches to using the Ethernet connection, the app's interface indicator
   updates from "WiFi" to "Ethernet" and the signal-strength row disappears, without Priya having
   to refresh manually.
2. When she later unplugs the cable and the camera falls back to WiFi, the indicator switches
   back and the signal-strength row reappears, showing a current reading rather than a stale one
   from before the switch.
3. The app doesn't show a confusing intermediate state (e.g. showing both or neither) during the
   brief handoff between interfaces.

**What the user expects:** the connection-type display always reflects what's actually active
right now, updating cleanly through a live interface change rather than showing stale or
conflicting information.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall update its network-interface indicator promptly upon receiving
  a change in the camera's active interface, without requiring a manual refresh, and shall
  refresh the WiFi signal-strength value fresh (not stale) upon switching back to WiFi.
- **[camera-firmware]** The camera shall report an interface-change event at the moment its
  active network interface changes, rather than only exposing the current interface as a value
  a client must poll for.
