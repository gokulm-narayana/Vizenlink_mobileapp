---
feature_id: FEAT-002
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Mobile Live-View Substream

Covers the homeowner-facing side of FEAT-002 (Mobile Live-View Substream): the app's live view
automatically using a lower-resolution stream sized for phone screens and mobile bandwidth,
instead of the camera's full main stream.

## Scenario: Opening live view over cellular data

**Scenario ID:** SCN-009
**Feature ID:** FEAT-002

**Persona:** Priya, a homeowner, opens the mobile app to check on her porch while out running
errands, connected over cellular data rather than home WiFi.

1. Priya taps into live view for her camera.
2. The video starts playing within a couple of seconds, sized appropriately for her phone screen
   rather than pulling the camera's full high-resolution feed.
3. The stream stays smooth and responsive as she pans around the app, without stuttering or
   repeatedly buffering.
4. Nothing in the experience makes her feel like she's watching a "reduced" or "lite" version —
   it just looks like a normal, quick-loading live view.

**What the user expects:** live view opens fast and stays smooth on her phone's data connection,
without her having to know or care that a separate, lighter stream is what makes that possible.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall request the camera's mobile-optimized substream (not the main
  high-resolution stream) when opening live view, so start-up time and bandwidth use are sized
  for a phone screen and mobile network conditions.
- **[camera-firmware]** The camera shall expose an independently-configurable, lower-resolution
  second video stream suitable for mobile viewing, encoded and running continuously alongside
  the main stream rather than being generated on demand.
- **[cloud-components]** When the app is connected over WAN, the substream shall be delivered
  through the existing cloud video-relay path rather than requiring a direct LAN connection to
  the camera.

## Scenario: Network conditions degrade mid-session

**Scenario ID:** SCN-010
**Feature ID:** FEAT-002

**Persona:** Priya is watching live view on the substream when she walks into a part of her house
with weak WiFi signal.

1. As her connection quality drops, the live view doesn't simply freeze or disconnect outright.
2. The app shows a brief "reconnecting" or "buffering" indication rather than silently going
   blank.
3. Once her connection recovers, live view resumes automatically without her needing to close and
   reopen the camera.

**What the user expects:** a rough patch in her network degrades gracefully — a visible pause,
not a silent freeze she can't tell apart from the app being broken.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show an explicit "reconnecting" or "buffering" state when the
  live-view substream stalls or drops, rather than leaving the last frame frozen with no
  indication anything is wrong.
- **[mobile-app]** The app shall automatically resume live view on the substream once connectivity
  recovers, without requiring the user to manually reopen the camera.
- **[camera-firmware]** The camera shall keep the mobile substream available for reconnection
  without requiring a full session/handshake restart when a client's connection is only briefly
  interrupted.

## Scenario: Substream unavailable and the app falls back to a clear error, not the main stream silently

**Scenario ID:** SCN-011
**Feature ID:** FEAT-002

**Persona:** Priya opens live view on a camera whose installer has disabled the mobile substream
(e.g. mid-reconfiguration), or where the substream has failed to start on the camera.

1. Priya taps into live view as normal.
2. Rather than silently pulling the full main stream (which would use far more of her data and
   battery than she expects from the app) or showing a blank screen, the app tells her plainly
   that the lightweight live view isn't currently available.
3. She's given the option to retry, and, if she chooses to, view the main stream instead with a
   clear indication that this uses significantly more data.

**What the user expects:** the app never quietly substitutes a much heavier stream without telling
her, and never leaves her staring at a blank screen with no explanation.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall detect when the mobile substream is unavailable and present an
  explicit message rather than silently falling back to the main stream or showing a blank view.
- **[mobile-app]** If the user chooses to fall back to the main stream when the substream is
  unavailable, the app shall clearly label that this stream uses more data/bandwidth than the
  normal mobile live view.
- **[camera-firmware]** The camera shall report substream availability/health as a distinct status
  from overall camera online status, so a client can distinguish "camera offline" from "substream
  specifically unavailable."
