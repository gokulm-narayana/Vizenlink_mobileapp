---
feature_id: FEAT-164
status: draft
target_fr_docs: [FR-mobile-app.md, FR-wifi-provisioning.md]
---

# Scenario: Mobile App — Post-Mount Installation Commissioning Checklist

Covers FEAT-164: guides the installer through a checklist verifying image quality, focus,
mounting angle, night-view usability, system time, active recording, storage health, network
connectivity, firmware version, and configured AI zones, before marking installation complete.

## Scenario: Installer completes the full commissioning checklist after mounting a camera

**Scenario ID:** SCN-588
**Feature ID:** FEAT-164

**Persona:** Diego, a professional installer, finishing physical installation of a new camera
at a customer's home.

1. Diego opens the app's "Commissioning" flow for the newly mounted camera.
2. The checklist walks him through each item in order: image quality, focus, mounting angle,
   night-view usability, system time, active recording, storage health, network connectivity,
   firmware version, and configured AI zones.
3. For each item, the app shows a live check or a simple pass/fail confirmation (e.g. it
   live-previews the image for Diego to visually confirm framing/focus, and automatically
   checks system time/firmware/storage/network status).
4. Once every item passes, Diego marks the installation complete, and the checklist's results
   are saved as a record of a verified commissioning.

**What the user expects:** he has one guided, complete checklist that catches an install issue
before he leaves the site, rather than relying on memory or a paper form.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a guided commissioning checklist covering image
  quality, focus, mounting angle, night-view usability, system time, active recording, storage
  health, network connectivity, firmware version, and configured AI zones.
- **[mobile-app]** The app shall record the completed checklist's results as part of the
  camera's commissioning history once every item passes.

## Scenario: A checklist item fails and blocks completion

**Scenario ID:** SCN-589
**Feature ID:** FEAT-164

**Persona:** Diego, whose checklist run flags the camera's local storage as degraded.

1. Diego reaches the storage-health item, and the app reports it as failed (e.g. the microSD
   card is near end-of-life or not detected properly).
2. The app doesn't let Diego mark the overall installation "complete" while this item is
   failing — it clearly shows which item(s) still need attention.
3. Diego swaps the storage card, reruns just that check, and it passes; only then can he
   complete the checklist.

**What the user expects:** a genuine problem found during commissioning can't be silently
skipped past — it has to actually be resolved before the install counts as done.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall block marking commissioning complete while any checklist item
  is in a failed state, and shall clearly indicate which item(s) are outstanding.
- **[mobile-app]** The app shall allow re-running an individual failed checklist item after a
  fix, without having to restart the entire checklist from the beginning.

## Scenario: Installer's progress is saved if the checklist is interrupted

**Scenario ID:** SCN-590
**Feature ID:** FEAT-164

**Persona:** Diego, called away mid-checklist by another job, needing to return later to finish
this same camera's commissioning.

1. Diego has completed several checklist items (image quality, focus, mounting angle) when he
   has to leave.
2. He closes the app, and later reopens the commissioning flow for the same camera.
3. The checklist resumes exactly where he left off, with the already-completed items still
   marked done, rather than forcing him to start over.

**What the user expects:** an interruption during a multi-step site visit doesn't cost him
redone work.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall persist commissioning checklist progress per-camera across app
  sessions, so an interrupted checklist resumes from where it was left rather than restarting.
</content>
