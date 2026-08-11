---
feature_id: FEAT-051
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — SD Card Format Action

Covers FEAT-051: a user/installer-triggered action to format/initialize the camera's microSD
card, as a basic recovery path for a new or corrupted card.

## Scenario: Homeowner formats a brand-new SD card

**Scenario ID:** SCN-175
**Feature ID:** FEAT-051

**Persona:** Marcus inserts a brand-new SD card into his camera for the first time.

1. The app detects an unformatted (or incompatible file-system) card and offers to format it,
   or Marcus can trigger formatting manually from storage settings.
2. Before formatting, the app clearly warns that this erases all data currently on the card and
   requires explicit confirmation.
3. Once confirmed, the camera formats the card and the app confirms success, after which local
   recording can begin normally.

**What the user expects:** getting a new card working is a guided, low-friction step, with a
clear warning before anything destructive happens.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall detect an unformatted/incompatible SD card and offer a format
  action, in addition to letting the user trigger formatting manually from storage settings.
- **[mobile-app]** The app shall warn that formatting erases all data on the card and require
  explicit confirmation before proceeding.
- **[camera-firmware]** The camera shall support formatting/initializing an inserted SD card on
  explicit client request and report success/failure of the operation.

## Scenario: Formatting a corrupted card recovers local recording

**Scenario ID:** SCN-176
**Feature ID:** FEAT-051

**Persona:** Priya's camera reports a file-system error on her SD card (per FEAT-038), and she
wants a straightforward recovery path rather than needing to replace the physical card.

1. From the storage-failure banner, Priya finds a "Format Card" action offered as a suggested
   recovery step for this specific failure type.
2. She confirms the format after the same data-loss warning.
3. Once formatting completes successfully, the storage-failure condition clears and local
   recording resumes normally.

**What the user expects:** a corrupted card doesn't mean an immediate trip to buy a new one —
formatting is presented as the first thing to try.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a "Format Card" action directly from a file-system-error
  storage-failure state, as a suggested recovery step.
- **[camera-firmware]** The camera shall clear an active storage-failure condition and resume
  normal local recording once a format operation completes successfully.

## Scenario: Attempting to format while actively recording

**Scenario ID:** SCN-177
**Feature ID:** FEAT-051

**Persona:** Marcus triggers a format action while the camera is in the middle of an active
recording session.

1. The app warns Marcus that formatting will stop current recording and erase existing footage,
   requiring confirmation specific to this in-progress-recording case.
2. Once confirmed, the camera safely stops the active recording (finalizing or discarding it
   cleanly, not leaving a corrupted partial file) before formatting begins.
3. The app confirms once formatting completes and shows that local recording is not yet active
   again until the user resumes it or the camera automatically restarts per its configured
   recording mode.

**What the user expects:** formatting mid-recording is handled safely rather than corrupting
whatever the camera happened to be doing at that moment.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall warn specifically that an in-progress recording will be stopped
  and erased when a format action is triggered during active recording, and require
  confirmation.
- **[camera-firmware]** The camera shall cleanly stop any in-progress recording before beginning
  a format operation, avoiding a corrupted partial file, and shall resume recording afterward per
  its configured recording mode.
