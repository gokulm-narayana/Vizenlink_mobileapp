---
feature_id: FEAT-088
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Device Health Telemetry

Covers the homeowner-facing side of FEAT-088: uptime, reboot count/pattern, firmware/model
version, and last-successful-recording timestamp shown for a single camera.

## Scenario: Priya checks her camera's basic device health

**Scenario ID:** SCN-332
**Feature ID:** FEAT-088

**Persona:** Priya, a homeowner curious whether her camera is behaving normally, opens its device
info screen.

1. Priya taps into "Device Info" for her camera and sees straightforward fields: current uptime
   ("14 days"), firmware version, camera model, and the timestamp of its last successful
   recording.
2. Everything reads normally, giving her quiet confidence the camera is functioning as expected
   without needing to interpret anything technical.
3. She notices the last-successful-recording timestamp is recent (a few minutes ago), confirming
   recording is actively working right now, not just "the camera is online."

**What the user expects:** a simple, readable summary of her camera's basic vital signs, without
needing any technical background to understand it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display, per camera, current uptime, firmware version, camera
  model, and timestamp of last successful recording, in a dedicated device-info view.
- **[camera-firmware]** The camera shall track and report its current uptime, firmware version,
  model identifier, and the timestamp of its most recent successfully completed recording
  segment.

## Scenario: A reboot-loop pattern shows up in Priya's device health

**Scenario ID:** SCN-333
**Feature ID:** FEAT-088

**Persona:** Priya's camera has developed a fault causing it to reboot every 20 minutes, though
each individual reboot is quick enough that she never notices a live outage.

1. Priya's device-info screen shows a reboot count that's grown unusually high over the last
   few hours, and the app calls this out explicitly ("6 reboots in the last 2 hours — unusual
   pattern") rather than just listing a raw counter she'd have to notice was abnormal herself.
2. Because each reboot is brief, no separate offline alert fired for any single one — but the app
   still surfaces the aggregate pattern as a health concern in its own right.
3. Priya is prompted to consider a factory reset or contacting support, since a frequent
   reboot pattern usually indicates an underlying fault even when the camera looks "up" most of
   the time.

**What the user expects:** the app doesn't just show her a raw number and leave her to notice a
problem — it recognizes an abnormal reboot pattern as a health issue on its own, even though no
single reboot was long enough to trigger an offline alert.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall flag an abnormal reboot-frequency pattern (not just a raw
  count) as its own health condition, distinct from and even in the absence of any triggered
  offline alert, since brief individual reboots may not otherwise cross the offline-alert
  threshold.
- **[camera-firmware]** The camera shall track its own reboot count and timestamps across a
  rolling window and report the pattern (not just a lifetime total) so a reboot-loop condition
  can be distinguished from an occasional, unremarkable reboot.
