---
feature_id: FEAT-031
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Camera-Side Recording Modes

Covers the homeowner-facing side of FEAT-031: choosing and configuring how the camera records
to its own local (SD) storage — continuous, time-scheduled, or event-triggered — from the
mobile app.

## Scenario: Switching to continuous recording

**Scenario ID:** SCN-109
**Feature ID:** FEAT-031

**Persona:** Marcus, a homeowner who wants his driveway camera to record around the clock
regardless of activity.

1. Marcus opens the camera's recording settings in the app and selects "Continuous" as the
   local recording mode.
2. The app confirms the change was applied and shows "Continuous" as the active mode.
3. The camera begins writing continuous footage to its SD card, overwriting the oldest footage
   as the card fills, per whatever retention policy is configured.
4. From the same screen, Marcus can see roughly how far back his continuous footage currently
   reaches.

**What the user expects:** once he picks Continuous, the camera just records everything with no
gaps he has to think about, and he can tell how much history he actually has.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user select a local recording mode (Continuous /
  Scheduled / Event-Triggered) for camera-side SD recording from a dedicated settings screen.
- **[mobile-app]** The app shall not show a recording-mode change as applied until the camera
  acknowledges it, and shall show the currently active mode distinctly from a
  pending/unconfirmed one.
- **[mobile-app]** The app shall display an estimate of how far back continuous footage
  currently reaches on the same screen used to select the mode.
- **[camera-firmware]** The camera shall support a continuous local recording mode that writes
  to SD storage without gaps, subject to the configured retention policy.

## Scenario: Setting up a time-scheduled recording window

**Scenario ID:** SCN-110
**Feature ID:** FEAT-031

**Persona:** Priya wants her camera to record locally only during work hours, when the house is
empty, to conserve SD card life and make later review faster.

1. Priya selects "Scheduled" as the local recording mode and opens the schedule editor.
2. She defines one or more day-of-week + time-range windows (e.g. weekdays 9am–5pm).
3. The app confirms the schedule was applied and shows it back to her in a readable summary.
4. During a defined window, the camera records locally; outside it, the camera does not write
   local footage, though live viewing remains available regardless of the schedule.
5. If Priya enters two windows that overlap or contradict each other (e.g. an end time before a
   start time), the app flags the conflict and asks her to fix it before saving, rather than
   silently accepting an ambiguous schedule.

**What the user expects:** recording follows the hours she actually cares about, and the app
catches an obviously broken schedule before it reaches the camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a schedule editor for one or more day-of-week +
  time-range recording windows, and shall display the saved schedule back as a readable summary.
- **[mobile-app]** The app shall validate a schedule for internal conflicts (overlapping or
  inverted windows) client-side before submitting it, and shall block save with a clear message
  until resolved.
- **[camera-firmware]** The camera shall record locally only during configured schedule windows
  when in Scheduled mode, while continuing to serve live view regardless of the schedule.

## Scenario: Enabling event-triggered recording with no trigger source configured

**Scenario ID:** SCN-111
**Feature ID:** FEAT-031

**Persona:** Dana, a new user, enables "Event-Triggered" local recording mode before setting up
any motion/AI detection zones.

1. Dana selects "Event-Triggered" as the local recording mode.
2. The app applies the mode but immediately shows a warning that no detection zones or triggers
   are currently configured, so the camera will not actually record anything in this state.
3. The warning links directly to the detection/zone setup screen so Dana can fix it in the same
   flow rather than discovering the gap later when she finds no footage exists.

**What the user expects:** the app doesn't let her walk away thinking event recording is active
when it would silently do nothing.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall detect when Event-Triggered local recording mode is selected
  with no detection zones/triggers configured, and shall surface an explicit warning rather than
  silently accepting a mode that will never actually record.
- **[mobile-app]** The warning shall link directly to detection/zone configuration so the gap
  can be resolved in the same flow.
- **[camera-firmware]** The camera shall report, on request, whether it currently has at least
  one active trigger source configured for event-triggered recording, so a client can detect
  this gap.

## Scenario: Changing recording mode while a recording is in progress

**Scenario ID:** SCN-112
**Feature ID:** FEAT-031

**Persona:** Marcus decides mid-afternoon to switch his camera from Continuous to Scheduled
mode while it is actively writing a continuous recording segment.

1. Marcus changes the mode and confirms.
2. The camera finalizes the file currently being written before applying the new mode, rather
   than truncating or corrupting it.
3. The app confirms the new mode is active only once the camera reports the switch completed
   cleanly.
4. Existing recorded footage from the prior mode remains intact and playable; only new
   recording behavior going forward follows the new mode.

**What the user expects:** changing his mind about recording mode never costs him footage he
already has, and the switch takes effect cleanly rather than leaving the camera in a
half-applied state.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall finalize any in-progress recording segment cleanly
  before applying a new local recording mode, without truncating or corrupting the file being
  closed.
- **[camera-firmware]** The camera shall leave previously recorded footage untouched when the
  local recording mode changes — only future recording behavior is affected.
- **[mobile-app]** The app shall confirm a recording-mode change as applied only after the
  camera reports the switch completed, not merely after the request was sent.
