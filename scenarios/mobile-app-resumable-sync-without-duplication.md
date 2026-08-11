---
feature_id: FEAT-102
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Resumable Sync Without Duplication

Covers the homeowner-facing side of FEAT-102: if a clip's sync is interrupted mid-transfer, it
resumes cleanly rather than showing up twice.

## Scenario: An upload is interrupted mid-transfer by a dropped connection

**Scenario ID:** SCN-375
**Feature ID:** FEAT-102

**Persona:** Priya's home internet briefly drops while an event clip is uploading.

1. Priya sees the event's sync state stall at "Uploading" during the drop, then resume
   automatically once connectivity returns — without her doing anything.
2. When it finishes, exactly one event appears in her timeline for that occurrence, not a
   duplicate entry from the interrupted attempt plus a second one from the resumed transfer.
3. The resumed upload picks up rather than restarting the whole clip from scratch, so it
   finishes quickly once reconnected rather than re-uploading data that already made it through.

**What the user expects:** a mid-upload network blip doesn't cost her a duplicate event in her
timeline or force a slow full re-upload — it just quietly picks back up and finishes.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display exactly one timeline entry per real-world event even
  when its clip's upload was interrupted and resumed, never a duplicate from the interrupted
  attempt.
- **[cloud-components]** The cloud sync service shall resume an interrupted upload from where it
  left off (not from scratch) and shall reconcile it against the same stable event ID, ensuring
  no duplicate cloud-side event is created.

## Scenario: Same clip appears to resume on two different network paths

**Scenario ID:** SCN-376
**Feature ID:** FEAT-102

**Persona:** Priya's camera briefly has both a flaky WiFi connection and a cellular-backup path
(if configured), and a single event's sync attempt gets retried over both in quick succession.

1. Even though the camera effectively attempts to sync the same event twice (once per path)
   because it couldn't confirm which succeeded, Priya still only ever sees one entry for that
   event in her timeline.
2. If both attempts happen to reach the cloud, the cloud recognizes them as the same event (via
   its stable ID) and only keeps one, rather than creating two.
3. Nothing about this is visible to Priya beyond the single, correct event — there's no manual
   cleanup or confusing duplicate for her to notice and report.

**What the user expects:** whatever retry logic happens behind the scenes, she should never be
the one who has to notice and deal with a duplicate event caused by it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall never display duplicate timeline entries for the same
  underlying event, regardless of how many sync attempts or paths were involved in getting it
  uploaded.
- **[cloud-components]** The cloud sync service shall deduplicate incoming event uploads by
  stable event ID, discarding a redundant successful upload of an event already recorded rather
  than creating a second cloud-side record.
