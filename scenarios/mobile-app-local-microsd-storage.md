---
feature_id: FEAT-033
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Local microSD Storage

Covers the homeowner-facing side of FEAT-033: enabling/disabling camera-side microSD storage as
a user-facing toggle, independent of whether the hardware is actually present or a card is
actually inserted.

## Scenario: Enabling local SD recording with a card present

**Scenario ID:** SCN-117
**Feature ID:** FEAT-033

**Persona:** Marcus has a camera SKU that includes an SD card slot and has just inserted a new
card.

1. Marcus opens the camera's storage settings and sees the local SD storage toggle currently
   off.
2. He turns it on.
3. The app confirms the card was detected, shows its capacity, and confirms local recording is
   now active.
4. Marcus can also see the card's current used/free space from this same screen.

**What the user expects:** turning the toggle on and having a valid card inserted is all it
takes — no separate setup step is needed.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a local SD storage enable/disable toggle, independent
  of and separate from any card-detection state, on the camera's storage settings screen.
- **[mobile-app]** The app shall display the SD card's detected capacity and current used/free
  space once local storage is enabled and a card is present.
- **[camera-firmware]** The camera shall report SD card presence, capacity, and free space to a
  requesting client so it can be surfaced in the app.

## Scenario: Enabling the toggle with no SD card physically present

**Scenario ID:** SCN-118
**Feature ID:** FEAT-033

**Persona:** Priya buys a camera SKU that supports an SD card but hasn't purchased or inserted
one yet, and turns the local storage toggle on anyway.

1. Priya enables the local SD storage toggle.
2. The app accepts the setting (the toggle is a user preference, independent of hardware state)
   but immediately shows a clear "No SD card detected" status alongside it, rather than
   pretending local recording is active.
3. Once Priya later inserts a card, the camera detects it and the app updates the status to
   show local recording is now actually running, with no further action needed from her.

**What the user expects:** the toggle reflects what she wants, and the app is honest about
whether that's actually happening right now versus just configured to happen.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall distinguish the local-storage *enabled* preference from the
  *actual* recording state, showing a clear "no card detected" status when the toggle is on but
  no card is present.
- **[camera-firmware]** The camera shall begin local recording automatically upon detecting a
  valid SD card if local storage is already enabled, without requiring the user to re-toggle
  the setting.

## Scenario: Disabling local storage on a camera with existing footage

**Scenario ID:** SCN-119
**Feature ID:** FEAT-033

**Persona:** Dana decides to rely solely on cloud/NVR recording and wants to turn off local SD
recording on her camera, which currently has footage on the card.

1. Dana turns the local SD storage toggle off.
2. Before applying it, the app warns her that this stops local recording going forward and that
   any footage relying solely on the card (not yet backed up elsewhere) will no longer be added
   to, asking her to confirm.
3. Once confirmed, the camera stops writing new local footage but does not erase existing
   footage already on the card — that stays available until removed or overwritten later per
   retention rules if re-enabled.

**What the user expects:** disabling local storage is a deliberate, warned-about action, and it
doesn't destroy footage she already has just because she turned the toggle off.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall warn the user, before applying it, that disabling local SD
  storage stops future local recording, and shall require explicit confirmation.
- **[camera-firmware]** The camera shall stop writing new local recordings when local storage is
  disabled, without erasing existing footage already stored on the card.
