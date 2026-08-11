---
feature_id: FEAT-225
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Full Camera Privacy Mode / Physical Shutter

Covers FEAT-225: a user-facing control that fully disables all video/audio capture and
recording — not just masking regions — via a software toggle, or a physical lens shutter on
hardware SKUs that support it.

## Scenario: Enabling software privacy mode

**Scenario ID:** SCN-683
**Feature ID:** FEAT-225

**Persona:** Priya is having a private conversation in her living room and wants her indoor
camera fully off, not just its feed hidden from the app.

1. Priya opens the camera's controls and taps "Privacy Mode."
2. The app confirms privacy mode is active with an unmistakable indicator (not just the live
   view going blank, which could be mistaken for a connection issue) — e.g. a persistent "Privacy
   Mode: ON" state on the camera's card throughout the app.
3. While active, the camera captures no video or audio at all — not even for AI processing or
   background recording — and generates no motion/detection events.

**What the user expects:** privacy mode genuinely stops all sensing, and the app makes it obvious
this is deliberately on, not indistinguishable from the camera being broken or offline.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide an explicit Privacy Mode toggle per camera, and shall
  show a persistent, unambiguous "Privacy Mode: ON" indicator distinct from an offline/error
  state whenever it's active.
- **[camera-firmware]** While privacy mode is active, the camera shall stop all video and audio
  capture entirely, including for on-device AI processing, and shall generate no detection/
  motion events.

## Scenario: Turning privacy mode back off

**Scenario ID:** SCN-684
**Feature ID:** FEAT-225

**Persona:** Priya, done with her private conversation, wants normal monitoring resumed.

1. Priya taps "Privacy Mode" again to turn it off.
2. The camera resumes capture and normal detection promptly, and the app's indicator reverts to
   normal status once the camera confirms it's actually capturing again — not the instant Priya
   taps the toggle, since that would risk showing "back on" before capture has actually resumed.

**What the user expects:** turning protection off is just as clear and just as deliberate as
turning it on, with the app only claiming normal operation once it's actually true.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall resume normal video/audio capture and detection promptly
  upon privacy mode being disabled.
- **[mobile-app]** The app shall only clear the "Privacy Mode: ON" indicator once the camera
  confirms capture has actually resumed, not immediately upon the user tapping the toggle.

## Scenario: A physical shutter SKU closes its lens instead

**Scenario ID:** SCN-685
**Feature ID:** FEAT-225

**Persona:** Vikram owns a camera model with a physical lens shutter and prefers the hardware
guarantee over a software-only toggle.

1. Vikram taps Privacy Mode on his shutter-equipped camera; the app sends the command, and the
   physical shutter mechanically closes over the lens.
2. The app confirms shutter-closed status only once the camera reports the shutter has actually
   moved into place (a hardware-confirmed state, not just "command sent").
3. Audio capture is also disabled at the same time as the visual shutter closes, since a closed
   lens alone wouldn't stop microphone capture.

**What the user expects:** on hardware that has a physical shutter, privacy mode gives him a
verifiable mechanical guarantee, not just a software promise — and it's confirmed as actually
closed, not merely commanded to close.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** On a camera with a physical lens shutter, enabling Privacy Mode shall
  physically close the shutter and disable audio capture together, and the camera shall report
  shutter-closed status only once the mechanism confirms it is actually closed (not merely
  commanded).
- **[mobile-app]** The app shall distinguish "shutter command sent" from "shutter confirmed
  closed" in its displayed privacy-mode status for a shutter-equipped camera.

## Scenario: Privacy mode is enabled remotely while the household is away

**Scenario ID:** SCN-686
**Feature ID:** FEAT-225

**Persona:** Priya's family member, at home, wants the camera off temporarily; Priya, away, is
notified.

1. When any authorized user enables privacy mode, every other user with access to that camera
   sees the same "Privacy Mode: ON" status reflected in their own app, and receives a
   notification that privacy mode was enabled (and by whom, if multiple accounts share the
   camera).
2. No user is left seeing a stale "recording normally" status for a camera that's actually in
   privacy mode.

**What the user expects:** privacy mode's effect is consistent for everyone with access to the
camera — no one is misled into thinking the camera is capturing when it isn't, or vice versa.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Privacy Mode status shall be synchronized across every user/app instance with
  access to that camera, with a notification to other authorized users when it's toggled by
  someone else.
- **[cloud-components]** Privacy Mode state changes shall be relayed promptly to all connected
  clients sharing access to that camera, so no client displays stale capture status.
