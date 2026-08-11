---
feature_id: FEAT-019
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Mirror/Flip Orientation Control

Covers the homeowner-facing side of FEAT-019 (Mirror/Flip Orientation Control): correcting a
camera's image orientation from the app when it was mounted upside-down or mirrored.

## Scenario: Correcting an upside-down mounted camera

**Scenario ID:** SCN-055
**Feature ID:** FEAT-019

**Persona:** Priya's installer mounted a camera on a ceiling bracket that ended up rotating the
image upside-down, and she wants it right-side-up without asking for a remount.

1. Priya opens the camera's orientation settings in the app and finds a vertical flip option.
2. She enables it.
3. Her live view immediately flips right-side-up.
4. The setting persists across app sessions and camera reboots.

**What the user expects:** a mounting mistake doesn't require a physical remount — a software
toggle fixes it immediately.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide horizontal and vertical flip controls (independently
  or combined) for a camera's video orientation.
- **[camera-firmware]** The camera shall apply a mirror/flip transform to its video pipeline
  (affecting both live stream and recordings) and persist the setting across reboots.

## Scenario: Combined horizontal and vertical flip for a mirrored, upside-down mount

**Scenario ID:** SCN-056
**Feature ID:** FEAT-019

**Persona:** Priya has a camera mounted in a way that's both upside-down and mirrored (e.g.
attached via a mirrored bracket adapter).

1. Priya enables both horizontal and vertical flip together.
2. The live view corrects to a normal, upright, non-mirrored orientation reflecting both
   corrections applied at once, not just one overriding the other.

**What the user expects:** she can combine both flip axes when a mount requires it, and the
result is exactly what both corrections applied together should look like.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall allow horizontal and vertical flip to be enabled simultaneously,
  not mutually exclusively.
- **[camera-firmware]** The camera shall apply horizontal and vertical flip as independent,
  combinable transforms rather than one overriding the other.
