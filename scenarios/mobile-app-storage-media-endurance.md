---
feature_id: FEAT-224
status: draft
target_fr_docs: [FR-camera-firmware.md, FR-mobile-app.md]
---

# Scenario: Mobile App — Storage Media Endurance Target Under Continuous Recording

Covers FEAT-224's user-perceptible manifestation: the app steering a homeowner toward a
surveillance-rated microSD card, and warning them meaningfully as their card approaches its
expected wear-out point, rather than silently failing after months of unattended 24/7 recording.

## Scenario: Guided toward a surveillance-rated card during setup

**Scenario ID:** SCN-681
**Feature ID:** FEAT-224

**Persona:** Priya is setting up local SD recording for a new camera and hasn't bought a card
yet.

1. When Priya reaches the local-storage setup step, the app shows guidance recommending a
   surveillance-rated microSD card (e.g. WD Purple, Samsung PRO Endurance) rather than any
   generic high-capacity card, explaining briefly why (continuous 24/7 writing wears out a
   standard consumer card faster).
2. If Priya inserts a card the camera can identify as a non-endurance-rated consumer card, the
   app shows a mild warning that it may wear out sooner than expected under continuous
   recording, without blocking her from using it if she chooses to anyway.

**What the user expects:** the app tells her upfront how to avoid an entirely avoidable future
failure, rather than letting her find out the hard way that her card died after six months.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show surveillance-rated microSD card guidance during local-
  storage setup, before the user selects/inserts a card.
- **[camera-firmware]** The camera shall attempt to identify whether an inserted card is a known
  surveillance/endurance-rated model where determinable, and report this to the app for the
  non-blocking warning shown when it is not.

## Scenario: A card approaches its expected wear-out point

**Scenario ID:** SCN-682
**Feature ID:** FEAT-224

**Persona:** Priya's card has been recording continuously for well over a year and is nearing its
expected write-endurance lifetime.

1. The app shows a "Storage health" indicator for the card (not just free/used space) reflecting
   estimated wear, and proactively warns Priya once it's approaching end-of-life, well before
   an actual failure, so she has time to replace it.
2. If the card does eventually fail, the app clearly reports the failure and its likely cause
   (worn-out storage media) rather than a generic, unexplained recording error.

**What the user expects:** a warning ahead of time so she can replace the card on her own
schedule, not an unexplained recording gap discovered only after checking footage she needed and
finding it missing.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall estimate its microSD card's wear/remaining endurance
  under its actual continuous-recording write pattern and report a proactive warning before
  expected failure, distinct from simple free-space reporting.
- **[mobile-app]** The app shall show a storage-health indicator reflecting estimated media
  wear, and shall clearly attribute a storage-related recording failure to worn-out media when
  that is the likely cause.
