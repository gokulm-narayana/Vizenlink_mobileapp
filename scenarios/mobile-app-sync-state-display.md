---
feature_id: FEAT-101
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Sync State Display

Covers the homeowner-facing side of FEAT-101: showing each event's sync lifecycle state
(local-only, sync-pending, uploading, verified, failed, discarded) in the app.

## Scenario: Priya watches a new event move through its sync lifecycle

**Scenario ID:** SCN-371
**Feature ID:** FEAT-101

**Persona:** Priya, watching the app shortly after a motion event fires while she's away from
home (so it needs to sync over WAN).

1. The event first appears in her timeline marked "Uploading," with a small progress indicator,
   rather than looking identical to an already-synced event.
2. A few seconds later it updates to "Verified" once the clip's integrity has been confirmed
   (per FEAT-103), and the sync-state label disappears or turns into a subtle "synced" checkmark
   since it no longer needs her attention.
3. If she taps the event while it's still "Uploading," she can view the local snapshot
   immediately without waiting for the clip to finish uploading.

**What the user expects:** she isn't left wondering whether the event she's looking at is fully
saved and safe, or still in transit — the state is visible and updates as it actually
progresses.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display each event's current sync state (local-only,
  sync-pending, uploading, verified, failed, discarded) visibly in the event timeline, updating
  as the state progresses.
- **[mobile-app]** The app shall let the user view an event's already-available local content
  (e.g. snapshot) even while its clip is still uploading/syncing, rather than blocking access
  until sync fully completes.
- **[cloud-components]** The cloud sync service shall report each event's current sync-lifecycle
  state to the app as it progresses, including the verified/failed outcome.

## Scenario: An event's sync fails and Priya can see why

**Scenario ID:** SCN-372
**Feature ID:** FEAT-101

**Persona:** Priya has a network event whose clip upload keeps failing (e.g. corrupted local
storage segment).

1. After repeated retry attempts are exhausted, the event's sync-state label changes to
   "Failed" rather than getting stuck indefinitely on "Uploading."
2. Tapping the event shows a short explanation ("clip could not be verified after upload") and
   whatever local content (snapshot, metadata) is still available, rather than showing a
   dead-end blank entry.
3. If the underlying data is later confirmed unrecoverable, the state updates to "Discarded,"
   distinct from "Failed," so Priya can tell the difference between "still might resolve" and
   "this one's gone."

**What the user expects:** when something genuinely can't be synced, the app tells her clearly
and shows whatever partial information does survive, rather than leaving a permanently-spinning
or silently-vanishing event.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall transition an event's sync state to "Failed" after exhausting
  retry attempts, distinct from an indefinite "uploading" state, and shall show a plain-language
  reason.
- **[mobile-app]** The app shall distinguish a "Failed" (may still be retried/recovered) sync
  state from a final "Discarded" (confirmed unrecoverable) state, and shall retain whatever
  partial local content (snapshot, metadata) remains available for either.
