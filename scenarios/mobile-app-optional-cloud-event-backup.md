---
feature_id: FEAT-043
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Optional Cloud Event Backup

Covers the homeowner-facing side of FEAT-043: opting selected events into cloud backup, layered
on top of local recording rather than replacing it.

## Scenario: Enabling cloud backup for selected event types

**Scenario ID:** SCN-149
**Feature ID:** FEAT-043

**Persona:** Marcus wants his high-priority events (e.g. person detected at the door) backed up
to the cloud in case something happens to the camera or its SD card, without paying to back up
every routine motion clip.

1. Marcus opens cloud backup settings and enables it, then selects which event types/severities
   should be backed up (e.g. "Person" and "Package" but not "Motion — general").
2. The app confirms the selection was applied.
3. Going forward, only events matching the selected types get uploaded to the cloud; all events
   continue to record locally exactly as before, regardless of the cloud selection.
4. Marcus can see, per event in his history, whether it was backed up to the cloud or exists
   only locally.

**What the user expects:** cloud backup is an added safety net for the events he cares most
about, not an all-or-nothing switch, and it never comes at the cost of his local recording.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user enable cloud event backup and select which event
  types/severities are included, independent of local recording, which continues unaffected.
- **[mobile-app]** The app shall indicate, per event in the user's history, whether it is backed
  up to the cloud or exists only locally.
- **[cloud-components]** The cloud backup service shall upload only events matching the user's
  selected types/severities, leaving all other events local-only.
- **[camera-firmware]** The camera shall continue local event recording unchanged regardless of
  which events are also selected for cloud backup.

## Scenario: Cloud backup upload fails or is interrupted

**Scenario ID:** SCN-150
**Feature ID:** FEAT-043

**Persona:** Priya's camera loses internet connectivity partway through uploading a backed-up
event.

1. The camera/service detects the interrupted upload and retries once connectivity returns,
   rather than treating the partial upload as complete.
2. Until the retry succeeds, the app shows that specific event as "backup pending," not as
   successfully backed up.
3. The event's local copy is entirely unaffected by the backup failure — it remains fully
   available locally the whole time.

**What the user expects:** a flaky connection never loses her the event, and the app is honest
about backup status rather than falsely claiming a clip is safely in the cloud.

> **Review:** ⏳ Pending

### Derived Requirements

- **[cloud-components]** The cloud backup upload path shall retry an interrupted upload rather
  than treating a partial transfer as complete, and shall not report success until the full
  event is confirmed uploaded.
- **[mobile-app]** The app shall display an event's cloud backup status as "pending" (not
  backed up) while its upload has not yet succeeded.

## Scenario: Cloud storage quota reached

**Scenario ID:** SCN-151
**Feature ID:** FEAT-043

**Persona:** Marcus's cloud backup plan has a storage quota, and it fills up during an unusually
active week.

1. As the quota is approached, the app warns Marcus that cloud backup is nearing its limit.
2. Once the quota is reached, new events selected for backup are not silently dropped — the app
   clearly shows that cloud backup has paused due to the quota, distinct from an upload failure.
3. Marcus's local recording is entirely unaffected; only the cloud copy is paused until he frees
   up quota (e.g. by deleting old cloud backups) or upgrades his plan.

**What the user expects:** hitting a cloud storage limit is a clearly communicated, recoverable
situation, never a silent loss of new backups or any impact on local footage.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall warn the user as cloud backup storage quota is approached, and
  shall clearly distinguish a quota-paused state from an upload failure once the quota is
  reached.
- **[cloud-components]** The cloud backup service shall pause new uploads (without data loss to
  local recording) once a user's storage quota is reached, resuming automatically once quota is
  freed or increased.
