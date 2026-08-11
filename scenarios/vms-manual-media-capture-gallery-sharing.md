---
feature_id: FEAT-132
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Manual Media Capture Gallery & Sharing

Covers FEAT-132: manual snapshot/clip capture from live view, a browsable gallery with filters,
preview, delete, download, and share-link generation.

## Scenario: Operator captures a manual snapshot from live view

**Scenario ID:** SCN-499
**Feature ID:** FEAT-132

**Persona:** Marcus is watching a camera's live view and notices something worth capturing
right now, independent of any AI-flagged event.

1. Marcus clicks a "Capture Snapshot" control on the live-view player.
2. A still image is captured at that moment and saved into the site's media gallery, tagged
   with the camera, timestamp, and Marcus as the capturing operator.
3. Marcus receives a brief on-screen confirmation that the capture succeeded.

**What the user expects:** capturing a moment he personally noticed is a single click, and it's
saved somewhere he can find again later.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The live-view player shall provide a manual snapshot-capture control that saves a
  still image into the site's media gallery, tagged with camera, timestamp, and capturing
  operator.
- **[vms]** The VMS shall confirm a successful manual capture to the operator immediately.

## Scenario: Operator manually records a clip from live view

**Scenario ID:** SCN-500
**Feature ID:** FEAT-132

**Persona:** Marcus wants a short recorded clip of ongoing activity, not just a still frame.

1. Marcus clicks "Start Recording" on the live-view player; a visible recording indicator
   appears so it's clear capture is in progress.
2. Marcus clicks "Stop Recording"; the clip is saved to the gallery, tagged the same way as a
   snapshot (camera, timestamp range, capturing operator).
3. If Marcus navigates away without stopping, the recording stops automatically after a
   reasonable maximum duration rather than running indefinitely and consuming storage
   unbounded.

**What the user expects:** manual clip capture is as simple as start/stop, with a safeguard so
an accidentally-left-running capture doesn't silently eat storage.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The live-view player shall provide manual clip start/stop recording controls, with
  a visible in-progress indicator, saving the resulting clip to the gallery tagged with camera,
  time range, and capturing operator.
- **[vms]** A manual recording shall automatically stop after a defined maximum duration if not
  manually stopped first, to bound storage use.

## Scenario: Browsing, filtering, and managing the media gallery

**Scenario ID:** SCN-501
**Feature ID:** FEAT-132

**Persona:** Marcus wants to find a snapshot he captured last week among many manual captures
across the site.

1. Marcus opens the gallery and filters by camera, capturing operator, and date range to narrow
   down to the item he wants.
2. He previews the item inline, downloads a copy to his local machine, and deletes an
   unrelated, no-longer-needed capture — all from the same gallery view.
3. Deleting an item requires a confirmation step, given it's not recoverable afterward.

**What the user expects:** the gallery is a real asset-management surface, not just an
unsorted dump of captured files.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The media gallery shall support filtering by camera, capturing operator, and date
  range, with inline preview, download, and delete actions per item.
- **[vms]** Deleting a gallery item shall require an explicit confirmation before it is
  permanently removed.

## Scenario: Generating and later revoking a share link for a captured item

**Scenario ID:** SCN-502
**Feature ID:** FEAT-132

**Persona:** Marcus needs to share a captured clip with someone outside the VMS (e.g. a
property manager without an account).

1. Marcus generates a share link for the item from the gallery; the link works for the
   external recipient without requiring them to log into the VMS.
2. The share link is created with an expiration (or Marcus sets one), after which it stops
   working automatically.
3. Marcus can also revoke the link manually at any time before it expires, immediately
   invalidating it for anyone who still has it.

**What the user expects:** sharing outside the system is possible, but always time-bounded and
revocable — never an indefinitely-open link he loses control over.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The media gallery shall support generating a share link for a captured item that is
  accessible without VMS authentication, with a configurable expiration after which it
  automatically stops working.
- **[vms]** The VMS shall let an authorized operator manually revoke a share link before its
  expiration, immediately invalidating further access.
