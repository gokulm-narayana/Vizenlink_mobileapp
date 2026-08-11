---
feature_id: FEAT-046
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Multi-Camera Grid View (Live & Synchronized Playback)

Covers FEAT-046: viewing or reviewing multiple cameras at once on a shared grid, for both live
streams (up to 3×3/custom layout) and synchronized recorded playback (up to 16 cameras) —
VMS/NVR only, no camera-side equivalent.

## Scenario: Operator views a 3×3 live grid

**Scenario ID:** SCN-159
**Feature ID:** FEAT-046

**Persona:** Marcus monitors a small office site with nine cameras and wants to see them all at
once during his shift.

1. Marcus opens the site's live view and selects a 3×3 grid layout.
2. All nine camera feeds appear simultaneously, each labeled with its camera name.
3. Marcus can click any individual tile to expand it to full view, then return to the grid.

**What the user expects:** he can keep an eye on the whole site at a glance without flipping
between single-camera views one at a time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a configurable live grid layout (e.g. 3×3, custom) displaying
  multiple camera feeds simultaneously, each labeled with its camera name.
- **[vms]** The VMS shall allow expanding any grid tile to a full single-camera live view and
  returning to the grid without losing the other tiles' state.

## Scenario: Operator reviews synchronized playback across up to 16 cameras

**Scenario ID:** SCN-160
**Feature ID:** FEAT-046

**Persona:** Priya needs to review how an incident unfolded across a larger community site with
up to 16 cameras, all viewed together in sync.

1. Priya opens synchronized playback and selects the relevant 16 cameras (or fewer) for the
   incident's time window.
2. All selected cameras' playback timelines stay locked together — pausing, seeking, or
   changing speed on one applies to all of them at once.
3. Priya can step through the incident moment by moment, seeing every camera's view of the same
   instant simultaneously.

**What the user expects:** reconstructing an incident across many cameras means watching them
truly together, not manually keeping several separate playback windows in sync herself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support synchronized playback across up to 16 cameras simultaneously,
  with play/pause/seek/speed changes applied uniformly across all selected cameras.
- **[vms]** The VMS shall let an operator select which cameras (up to 16) participate in a
  synchronized playback session for a given time window.

## Scenario: One camera in the grid drops offline mid-view

**Scenario ID:** SCN-161
**Feature ID:** FEAT-046

**Persona:** Marcus is watching the live grid when one camera loses connectivity.

1. The affected tile clearly shows an offline/disconnected state (not a frozen last frame
   presented as if still live) rather than silently going blank with no explanation.
2. The rest of the grid continues updating normally — one camera's disconnection doesn't disrupt
   the others' live feeds.
3. The tile automatically resumes live video once the camera reconnects, without Marcus having
   to manually refresh that tile.

**What the user expects:** losing one camera doesn't compromise his view of everything else, and
he isn't misled into thinking a frozen frame is still live.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display an explicit offline/disconnected indicator on a grid tile
  whose camera loses connectivity, rather than a frozen last frame presented as live.
- **[vms]** The VMS shall continue updating other grid tiles normally when one camera
  disconnects, and shall automatically resume that tile's live feed on reconnection.

## Scenario: Custom layout with more cameras than can display at once

**Scenario ID:** SCN-162
**Feature ID:** FEAT-046

**Persona:** Priya's site has more cameras than fit in her chosen grid layout at once.

1. Priya selects a custom layout smaller than her total camera count.
2. The VMS shows the layout's cameras and provides an explicit way to page/cycle through the
   remaining cameras (e.g. next-page control or camera picker), rather than silently omitting
   cameras with no way to reach them.
3. Priya's chosen set of visible cameras and layout persists across sessions until she changes
   it.

**What the user expects:** having more cameras than fit on screen never means some just become
inaccessible from the grid view.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide explicit paging/cycling controls when a site has more cameras
  than the selected grid layout can display at once, rather than silently omitting cameras.
- **[vms]** The VMS shall persist an operator's chosen grid layout and camera selection across
  sessions.
