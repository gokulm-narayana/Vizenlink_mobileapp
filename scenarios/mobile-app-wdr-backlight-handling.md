---
feature_id: FEAT-006
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — WDR / Backlight Handling

Covers the homeowner-facing side of FEAT-006 (WDR / Backlight Handling): a simple on/off control
for wide dynamic range so a camera facing a bright entrance or gate produces a usable image
despite strong backlight.

## Scenario: Turning on WDR for a backlit entrance

**Scenario ID:** SCN-014
**Feature ID:** FEAT-006

**Persona:** Priya has a camera pointed at her front gate, facing east, and the morning sun washes
out anyone standing at the gate into a dark silhouette.

1. Priya opens the camera's image settings in the app and finds a WDR (wide dynamic range) toggle.
2. She turns it on.
3. Within a few seconds, her live view updates: the sky/background is no longer blown out and she
   can now make out details on a visitor's face at the gate instead of a silhouette.
4. The setting persists — it's still on the next time she opens the app.

**What the user expects:** a single, simple switch fixes the "person is just a dark shape against
bright sky" problem she's been living with, without her needing to understand what WDR means
technically.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall expose a WDR on/off toggle in the camera's image settings,
  labeled in plain language (e.g. "Backlight Compensation" or "Wide Dynamic Range"), on cameras
  whose sensor/ISP supports it.
- **[mobile-app]** The app shall reflect the camera's current WDR state accurately on next open,
  not just immediately after the change.
- **[camera-firmware]** The camera shall apply a WDR on/off setting to its ISP pipeline and persist
  it across reboots, reflecting the change in the live stream within a few seconds of being set.

## Scenario: WDR control hidden on a camera/sensor that doesn't support it

**Scenario ID:** SCN-015
**Feature ID:** FEAT-006

**Persona:** Priya has an older or lower-tier camera model whose sensor doesn't support WDR.

1. Priya opens that camera's image settings looking for the same WDR toggle she has on her other
   camera.
2. The app doesn't show a WDR toggle that silently does nothing when tapped — it's simply absent
   from that camera's settings, or shown but clearly marked as unsupported on this hardware.
3. Priya isn't confused about whether the setting "took" or not.

**What the user expects:** she's never shown a control that appears to work but has no actual
effect on the camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall hide (or clearly mark unsupported) the WDR toggle for any camera
  whose sensor/ISP does not support it, based on a capability reported by the camera rather than
  assuming all camera models support it.
- **[camera-firmware]** The camera shall report a WDR-support capability flag to clients
  reflecting the actual sensor/ISP's ability to perform WDR, so clients don't offer a
  non-functional control.
