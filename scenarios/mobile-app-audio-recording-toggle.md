---
feature_id: FEAT-022
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Audio Recording Toggle & Indicator

Covers the homeowner-facing side of FEAT-022 (Audio Recording Toggle & Indicator): independently
turning audio recording on/off from video recording, with a clear indicator of current state.

## Scenario: Homeowner enables audio recording on a home camera

**Scenario ID:** SCN-063
**Feature ID:** FEAT-022

**Persona:** Priya wants her front-door camera to capture audio along with video so she can hear
what a visitor says at the door, and her deployment defaults to audio off.

1. Priya opens the camera's recording settings and finds an audio recording toggle, separate from
   video recording (which is already on).
2. She turns audio recording on.
3. A clear indicator (e.g. a microphone icon) appears in live view and on recordings showing audio
   is being captured.
4. New recordings from this point include audio; video continues recording exactly as before.

**What the user expects:** turning on audio is a distinct, deliberate choice from video recording,
and it's always visually obvious whether audio is currently being captured.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide an audio recording toggle independent of the video
  recording control, and shall display a persistent indicator (e.g. icon) in live view whenever
  audio recording is active.
- **[camera-firmware]** The camera shall support enabling/disabling audio recording independently
  of video recording, without interrupting the video recording stream when audio is toggled.

## Scenario: Audio recording defaults to off in a community deployment

**Scenario ID:** SCN-064
**Feature ID:** FEAT-022

**Persona:** Marcus's community site has cameras installed under this deployment's stricter
audio-consent policy, and a resident opens the app for one of these cameras for the first time.

1. The resident opens the camera's recording settings and sees audio recording is off by default,
   distinct from video recording which is on.
2. If they attempt to turn audio on, the app either allows it only if they're authorized to change
   this setting for a community-managed camera, or clearly explains that audio is governed by
   site policy and not user-toggleable here.

**What the user expects:** in a deployment where audio has a stricter consent requirement, she
isn't casually able to flip on audio recording as if it carried the same expectations as a private
home camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall default audio recording to off for cameras belonging to a
  deployment type (e.g. community/office) whose policy requires it, distinct from the default for
  private home deployments.
- **[camera-firmware]** The camera shall enforce a deployment-policy-driven default and
  permission gate for audio recording, distinguishing a community/office deployment's stricter
  default from a home deployment's default.
