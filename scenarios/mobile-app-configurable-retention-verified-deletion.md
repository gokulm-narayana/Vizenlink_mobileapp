---
feature_id: FEAT-190
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Configurable Retention with Verified Deletion

Covers FEAT-190's homeowner side: configuring how long recordings/events are kept, and being
able to trust that a deletion (manual or retention-triggered) actually removed the data rather
than just hiding it from the app's own view.

## Scenario: Setting a custom retention period

**Scenario ID:** SCN-628
**Feature ID:** FEAT-190

**Persona:** Priya wants to keep less footage than the default to save cloud storage cost.

1. Priya opens Settings → Storage & Retention for her camera and sees the current retention
   period (e.g. 30 days).
2. She changes it to 7 days from a set of supported options.
3. The app confirms the change was applied and shows when it takes effect (e.g. existing footage
   older than 7 days is scheduled for deletion on the next cycle, not deleted immediately mid-day
   in a jarring way).

**What the user expects:** she controls how long her footage sticks around, with a clear
understanding of when the new setting starts actually removing older footage.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure the recording/event retention period from
  a set of supported values, distinct per camera.
- **[mobile-app]** The app shall clearly state when a newly-shortened retention period will
  begin actually removing existing footage older than the new limit.
- **[cloud-components]** The cloud storage backend shall apply the confirmed retention period to
  scheduled deletion jobs for that camera's stored footage/events.

## Scenario: Manually deleting a recording and confirming it's actually gone

**Scenario ID:** SCN-629
**Feature ID:** FEAT-190

**Persona:** Priya wants to permanently delete a specific recorded clip she accidentally shared
context she'd rather not keep archived.

1. Priya finds the clip in her recordings list and taps Delete, confirming the action (footage
   deletion is not easily reversible, so the app asks for confirmation).
2. The app shows a "Deleting…" state and then a confirmation that deletion completed — not
   merely removing the item from the list instantly and assuming the backend caught up.
3. If Priya searches or exports around that time range afterward, the deleted clip does not
   reappear from any archive/backup copy still holding it.

**What the user expects:** "delete" means actually gone — not hidden from the app's UI while
secretly retained somewhere in a backup she's unaware of.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall require explicit confirmation for manual footage deletion and
  show a distinct "deletion confirmed" state only once the backend confirms removal, rather than
  optimistically removing the item from the UI immediately.
- **[cloud-components]** A manual or retention-triggered deletion shall remove the underlying
  footage from primary storage and any backup/replica copies within a defined window, rather
  than leaving it recoverable from a copy the user isn't shown.

## Scenario: Verifying a retention-triggered automatic deletion actually ran

**Scenario ID:** SCN-630
**Feature ID:** FEAT-190

**Persona:** Priya, curious after reading about the retention setting, wants to confirm old
footage is really being purged on schedule, not just aging out of the visible list.

1. Priya opens a "Deletion history" or "Storage" screen showing recent automatic deletions
   (e.g. "142 clips older than 7 days deleted on [date]").
2. This log is a factual record of completed deletions, not merely a count of items no longer
   shown in the recordings list.

**What the user expects:** she can independently verify retention-based deletion is actually
happening, not take it on faith that "I don't see it anymore" means "it's gone."

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a deletion history/log showing completed
  retention-triggered deletions (count, date), distinct from and verifiable against actual
  backend removal, not just UI list-filtering.
- **[cloud-components]** The retention-deletion job shall record a verifiable completion log
  entry for each deletion batch it runs, which the app's deletion history displays.
