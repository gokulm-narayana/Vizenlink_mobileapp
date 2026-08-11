---
feature_id: FEAT-029
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Speaker/Mic Volume Control

Covers the homeowner-facing side of FEAT-029 (Speaker/Mic Volume Control): adjusting the camera's
speaker output volume and microphone input gain from the app, independent of the phone's own
volume controls.

## Scenario: Turning up speaker volume so a warning message is clearly audible outside

**Scenario ID:** SCN-085
**Feature ID:** FEAT-029

**Persona:** Priya finds that the prerecorded warning message and her own voice during two-way
talk sound too quiet outside from her driveway camera's speaker.

1. Priya opens the camera's audio settings in the app and finds a speaker volume slider, separate
   from her phone's own volume/media controls.
2. She raises it.
3. The next time she uses two-way talk or a warning plays, it's noticeably louder from the
   camera's actual speaker.
4. The setting persists across sessions.

**What the user expects:** she can make the camera itself sound louder to people near it, not just
control the volume of what she hears on her own phone.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a speaker output volume control for the camera, distinct
  from the listening device's own local volume, and persist the setting.
- **[camera-firmware]** The camera shall apply a configured speaker output volume to two-way talk
  audio and prerecorded warning playback, persisting the setting across reboots.

## Scenario: Reducing microphone gain to cut out background wind noise

**Scenario ID:** SCN-086
**Feature ID:** FEAT-029

**Persona:** Priya's camera is mounted somewhere exposed to wind, and its captured audio (both in
recordings and during two-way talk) is dominated by wind noise, drowning out actual voices.

1. Priya opens the camera's audio settings and finds a microphone gain control, separate from
   speaker volume.
2. She lowers the microphone gain.
3. Subsequent recordings and live audio are noticeably less dominated by wind noise, though also
   somewhat quieter overall for genuinely distant sounds.

**What the user expects:** she has a real, independent way to reduce how sensitive the camera's
microphone is, not just a fixed input she can't adjust.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a microphone input gain control for the camera,
  independent of the speaker output volume control.
- **[camera-firmware]** The camera shall apply a configured microphone gain level to both recorded
  audio and live/two-way-talk audio capture, persisting the setting across reboots.
