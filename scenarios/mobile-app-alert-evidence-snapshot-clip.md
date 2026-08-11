---
feature_id: FEAT-056
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Alert Evidence Snapshot & Clip Linkage

Covers the homeowner-facing side of FEAT-056: every alert-worthy event carrying a snapshot and a
linked clip, and how the app behaves when the clip isn't available yet or at all.

## Scenario: Homeowner opens an alert and immediately has snapshot and clip

**Scenario ID:** SCN-216
**Feature ID:** FEAT-056

**Persona:** Raj, a homeowner who gets a "Person detected" push notification while at work.

1. Raj taps the notification and the alert opens showing a snapshot of the moment of detection
   immediately — no waiting or spinner for the snapshot itself.
2. Below the snapshot, a "Watch clip" control is available and, when tapped, plays the short
   video clip covering the event.
3. Raj can review both without needing to separately navigate to a recordings/timeline screen —
   the alert itself is self-contained evidence.

**What the user expects:** every alert he gets always has a picture and a video he can pull up
right there, not just a text notification he has to go hunting to corroborate.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall capture and preserve a snapshot image at the moment of
  every alert-worthy detection event, tagged with a reference the alert pipeline can retrieve.
- **[cloud-components]** The alert published to the mobile app shall include a reference to both
  the snapshot and the associated clip, so the app can retrieve either without a separate
  lookup/search step.
- **[mobile-app]** The app shall display an alert's linked snapshot immediately on opening the
  alert, and shall offer a direct "watch clip" control from the same screen.

## Scenario: Clip is still uploading when the homeowner opens the alert

**Scenario ID:** SCN-217
**Feature ID:** FEAT-056

**Persona:** Raj, opening an alert within seconds of receiving the push notification, before the
camera has finished uploading the associated clip.

1. Raj taps the notification almost immediately. The snapshot displays right away (it's small
   and uploads fast).
2. The "Watch clip" control shows a clear "processing" / "not ready yet" state instead of either
   failing silently or showing a blank/broken player.
3. A minute later, Raj reopens the same alert and the clip now plays normally.

**What the user expects:** the app is honest about the clip not being ready yet rather than
either pretending it's there or leaving him wondering if something broke.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall distinguish "clip not yet available" from "clip failed" or
  "clip missing" in its UI, and shall retry fetching the clip reference rather than requiring
  the user to manually refresh the whole alert.
- **[cloud-components]** The clip-upload pipeline shall make the clip's availability state
  (pending/ready/failed) queryable by the alert reference, distinct from the alert's own
  existence, so the app can reflect accurate in-progress status.

## Scenario: Clip upload fails, but the snapshot is still preserved

**Scenario ID:** SCN-218
**Feature ID:** FEAT-056

**Persona:** Raj, whose camera briefly lost its WAN connection right after a detection event,
so the clip never made it to the cloud.

1. Raj opens the alert. The snapshot is present and displays normally — it was small enough to
   have already been delivered before the connection dropped.
2. The clip control shows a clear "clip unavailable" state rather than an indefinite spinner,
   once the pipeline gives up retrying.
3. Raj still has a snapshot as evidence of the event even though the clip never arrived, rather
   than losing the event's evidence entirely.

**What the user expects:** losing the clip to a network hiccup never means losing all evidence
of the event — the snapshot guarantee holds independently of the clip's fate.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall prioritize delivering the snapshot ahead of (and
  independently of) the clip, so a connectivity interruption that blocks the clip does not also
  block the snapshot.
- **[mobile-app]** The app shall present an alert with a permanently-failed clip as still having
  valid evidence (the snapshot), with a clear "clip unavailable" state, rather than treating the
  whole alert as broken or incomplete.
