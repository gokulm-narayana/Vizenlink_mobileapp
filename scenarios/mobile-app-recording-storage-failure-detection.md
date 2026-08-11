---
feature_id: FEAT-038
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Recording & Storage Failure Detection

Covers the homeowner-facing side of FEAT-038: surfacing storage/recording failure conditions
(full, unavailable, read-only, write failure, file-system error, recording-service failure) as a
critical, visible health state rather than failing silently.

## Scenario: SD card full detected and surfaced to the homeowner

**Scenario ID:** SCN-133
**Feature ID:** FEAT-038

**Persona:** Marcus's SD card retention overwrite mechanism itself fails (e.g. a file-system
error prevents the oldest file from being deleted), so the card fills up and can't self-correct.

1. The camera detects it can no longer write new footage because the card is full and overwrite
   isn't succeeding.
2. Marcus receives a push notification flagging this as a critical storage issue, distinct from
   an ordinary informational message.
3. Opening the app, he sees a persistent critical health banner on the camera's status screen,
   not just a one-time notification he could miss.
4. The banner explains the specific condition (e.g. "SD card full — recording stopped") rather
   than a generic "storage issue" message.

**What the user expects:** if his camera stops actually protecting him, he finds out
immediately and clearly, not by noticing weeks later that there's no footage from that day.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall send a push notification and display a persistent critical
  health banner when the camera reports a storage/recording failure, distinct from routine
  informational alerts.
- **[mobile-app]** The app shall display the specific failure condition (full, unavailable,
  read-only, write failure, file-system error, recording-service failure) rather than a generic
  message.
- **[camera-firmware]** The camera shall detect and classify storage/recording failure
  conditions distinctly (full / unavailable / read-only / write failure / file-system error /
  recording-service failure) and report the specific condition to connected clients.

## Scenario: SD card removed mid-recording

**Scenario ID:** SCN-134
**Feature ID:** FEAT-038

**Persona:** Priya's SD card is physically removed (e.g. by a curious child, or vibration
working it loose) while the camera is actively recording.

1. The camera detects the card became unavailable mid-write.
2. Priya gets a critical notification specifically identifying that the card was removed/became
   unavailable, distinguishing this from a full-card condition.
3. The app's status screen continues showing this as an active critical condition until the
   card is reinserted (or local storage is disabled) and detected again.

**What the user expects:** losing the physical card is treated as seriously as any other
storage failure, with a message that actually matches what happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall detect an SD card becoming physically unavailable
  mid-operation and classify it distinctly from a "full" condition.
- **[mobile-app]** The app shall keep a storage-failure condition displayed as active until the
  camera reports it resolved, rather than clearing it after the initial notification is
  dismissed.
