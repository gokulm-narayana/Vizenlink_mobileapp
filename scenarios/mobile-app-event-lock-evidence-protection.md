---
feature_id: FEAT-041
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Event Lock / Evidence Protection

Covers the homeowner-facing side of FEAT-041: locking/protecting a specific priority-incident
recording from automatic retention-policy deletion or overwrite.

## Scenario: Homeowner locks a priority clip from deletion

**Scenario ID:** SCN-145
**Feature ID:** FEAT-041

**Persona:** Marcus has a clip of a package theft he wants to keep indefinitely, well past his
normal SD retention window.

1. Marcus opens the clip and taps "Lock" (or "Protect").
2. The app confirms the clip is now locked, marking it visibly (e.g. a lock icon) wherever it
   appears in his footage lists.
3. As his normal retention overwrite process later reaches this clip's age, the camera skips it
   instead of deleting it, per FEAT-037's retention-vs-lock interaction.
4. Marcus can unlock it later himself, at which point it becomes subject to normal retention
   again.

**What the user expects:** locking a clip is a real, durable guarantee that it survives normal
housekeeping — not just a label with no actual protective effect.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user lock/unlock an individual recording, and shall
  display a locked recording's status distinctly wherever it appears (playback, event lists,
  search results).
- **[camera-firmware]** The camera shall exclude any locked recording from retention-driven
  overwrite/deletion, and shall resume normal retention treatment once the recording is
  unlocked.

## Scenario: Attempting to lock a clip while storage is full

**Scenario ID:** SCN-146
**Feature ID:** FEAT-041

**Persona:** Priya tries to lock a clip at the moment her SD card is already full and every
byte of unprotected footage is needed for ongoing recording.

1. Priya taps "Lock" on the clip.
2. The camera applies the lock immediately — locking a clip doesn't require free space, since
   it protects existing footage rather than writing new data.
3. The app confirms the lock succeeded even though the storage-full condition (flagged
   separately per FEAT-038) is still active.

**What the user expects:** protecting a clip she already has works regardless of whatever
storage trouble the card is otherwise having.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall be able to apply a lock to an existing recording
  independent of current free-storage state, since locking does not require writing new data.
- **[mobile-app]** The app shall confirm a lock action succeeded independent of any concurrent
  storage-failure condition being displayed for that camera.
