---
feature_id: FEAT-215
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Local (LAN) Live-View Startup Latency

Covers FEAT-215's user-perceptible manifestation: tapping into live view over a healthy home
WiFi network should feel near-instant, not like waiting for a stream to buffer.

## Scenario: Opening live view at home on a healthy WiFi connection

**Scenario ID:** SCN-668
**Feature ID:** FEAT-215

**Persona:** Priya is at home, connected to her own WiFi, and taps her front-door camera's
thumbnail to check live view.

1. Priya taps the camera thumbnail.
2. The first live frame appears within about 2 seconds — quickly enough that it doesn't feel
   like a loading screen, more like flipping to a channel.

**What the user expects:** live view "just opens," without a distinct wait that makes her
wonder if something's wrong.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display the first live-view frame within 2 seconds at p95 when
  connecting to a camera over a healthy local network.
- **[camera-firmware]** The camera's local substream shall be ready to serve a new viewer
  connection promptly enough (no on-demand pipeline cold-start delay) to meet the app's
  2-second p95 first-frame target under normal conditions.

## Scenario: The target is missed due to degraded local network conditions

**Scenario ID:** SCN-669
**Feature ID:** FEAT-215

**Persona:** Priya's home WiFi is congested (e.g. several devices streaming at once) when she
opens live view.

1. Live view takes noticeably longer than 2 seconds to show its first frame; the app shows a
   loading indicator during this time rather than a blank or frozen screen that looks broken.
2. If it takes long enough, the app tells her plainly that the connection is slow, rather than
   leaving her staring at an indefinite spinner with no explanation.

**What the user expects:** a slow local network produces an honest "this is taking a while,
here's a spinner" experience, not a silent failure or a misleadingly instant-looking freeze
frame.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show an active loading indicator while live view is connecting,
  and shall surface a plain "connection is slow" message if first-frame delivery exceeds a
  defined threshold well beyond the normal target, rather than leaving an indefinite unexplained
  wait.
