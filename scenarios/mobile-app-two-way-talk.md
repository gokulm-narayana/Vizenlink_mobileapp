---
feature_id: FEAT-023
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md, FR-nuraeye-service.md, FR-access-control.md]
---

# Scenario: Mobile App — Two-Way Talk

Covers the homeowner-facing side of FEAT-023 (Two-Way Talk): speaking to someone near the camera
through the app, permission-gated to authorized household members.

## Scenario: Talking to a delivery driver through the app

**Scenario ID:** SCN-067
**Feature ID:** FEAT-023

**Persona:** Priya sees a delivery driver on live view and wants to ask them to leave the package
by the side door.

1. Priya opens live view and taps the talk button.
2. The app asks for or already has microphone permission, then indicates she's now transmitting.
3. The driver hears her voice through the camera's speaker, and she can hear their response
   through the camera's microphone picked up in the video's audio.
4. She releases the talk control (or it auto-ends) and the interaction ends cleanly.

**What the user expects:** talking through the camera feels immediate and natural, with clear
feedback about when she is and isn't actually transmitting.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a two-way talk control from live view, requesting
  microphone permission if not already granted, and clearly indicating active transmission state.
- **[camera-firmware]** The camera shall play received audio through its speaker and capture
  microphone audio for return transmission while a two-way talk session is active, without
  interrupting ongoing video recording.
- **[cloud-components]** When the app is connected over WAN, two-way talk audio shall be relayed
  through the existing cloud/MQTT-signaled media path rather than requiring a direct LAN
  connection.

## Scenario: A viewer-only household account cannot initiate talk

**Scenario ID:** SCN-068
**Feature ID:** FEAT-023

**Persona:** Priya's teenage son, who has a viewer-only account on the household's camera, tries
to use two-way talk.

1. He opens live view and looks for the talk control.
2. It's either absent or clearly disabled for his account, since two-way talk is restricted to
   accounts with that permission.

**What the user expects:** talking through a camera at someone is a meaningfully privileged action
that stays restricted to authorized household members, not available to every viewer.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall restrict the two-way talk control to accounts explicitly
  authorized for it, hiding or disabling it for viewer-only accounts.
- **[camera-firmware]** The camera shall reject a two-way talk session request from a client that
  does not authenticate with talk permission, independent of whether the app's UI already hid the
  control.

## Scenario: Two concurrent viewers, only one can talk at a time

**Scenario ID:** SCN-069
**Feature ID:** FEAT-023

**Persona:** Priya and her spouse are both watching the same camera's live view from their own
phones when a visitor arrives, and both reach for the talk button at nearly the same moment.

1. Priya taps talk first and begins transmitting.
2. Her spouse's app shows that someone else is currently talking through this camera and that
   their own talk control is temporarily unavailable, rather than both audio streams colliding
   at the camera's speaker.
3. Once Priya releases talk, her spouse's talk control becomes available again.

**What the user expects:** two people don't end up talking over each other through the same
camera speaker — the app makes clear when someone else already has the floor.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall indicate when another authorized viewer currently holds an active
  two-way talk session on the same camera, and shall disable the local talk control until that
  session ends.
- **[camera-firmware]** The camera shall allow only one two-way talk session to transmit through
  its speaker at a time, rejecting or queuing a concurrent request rather than mixing simultaneous
  audio sources.
