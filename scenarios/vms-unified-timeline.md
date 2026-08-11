---
feature_id: FEAT-118
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Unified Recording/Event Timeline

Covers the VMS side of FEAT-118, for an operator reviewing recorded footage and flagged events
across one or more cameras at a site.

## Scenario: Operator reviews a synchronized multi-camera timeline

**Scenario ID:** SCN-434
**Feature ID:** FEAT-118

**Persona:** Marcus investigates an incident that multiple cameras at one site may have
captured.

1. Marcus opens the site's timeline view with several cameras selected; each camera's
   continuous recording and event markers are shown on a shared, time-synchronized timeline.
2. Scrubbing the shared timeline moves all selected cameras' playback together, staying in
   sync, rather than each camera drifting independently.
3. Clicking an event marker on any one camera's row jumps every selected camera's playback to
   that same moment, so Marcus can see what every camera captured at that instant.

**What the user expects:** reconstructing an incident across multiple cameras means one
synchronized timeline, not manually aligning several separate players by eye.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The timeline view shall support selecting multiple cameras at a site and display
  their continuous recording and event markers on a shared, time-synchronized timeline.
- **[vms]** Scrubbing or jumping to an event marker on the shared timeline shall move every
  selected camera's playback to the same timestamp in unison.
- **[camera-firmware]** Each camera's recorded footage and event timestamps shall be
  time-synchronized to a common reference (e.g. NTP-disciplined clock) so multi-camera
  timeline alignment is accurate.

## Scenario: Timeline gap caused by storage rotation reaching its retention limit

**Scenario ID:** SCN-435
**Feature ID:** FEAT-118

**Persona:** Marcus scrubs back further than the site's configured retention window allows.

1. The timeline clearly ends or shows an explicit "beyond retention" boundary at the oldest
   available footage, rather than showing an ambiguous empty gap indistinguishable from an
   outage.
2. Marcus can see, distinctly, footage that's missing because of an outage (per the mobile-app
   scenario's gap case) versus footage that's simply aged out of retention.

**What the user expects:** he can tell the difference between "the camera was down" and "this
footage was already deleted by retention policy," since the two imply very different follow-up
actions.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The timeline shall render a distinct "beyond retention" boundary at the oldest
  retained footage, visually distinguishable from a recording-outage gap within the retained
  window.
- **[camera-firmware]** The camera/storage subsystem shall report its actual retention boundary
  (oldest available recorded timestamp) so the timeline can render it accurately rather than
  inferring it from where data happens to run out.

## Scenario: Reviewing a dense multi-camera event cluster during an active incident

**Scenario ID:** SCN-436
**Feature ID:** FEAT-118

**Persona:** Marcus is reviewing a site where several cameras each flagged multiple events
within the same short window during an active incident.

1. The shared timeline shows overlapping event markers across camera rows; Marcus zooms in to
   separate them, same as the single-camera zoom behavior, but now across every selected
   camera's row simultaneously.
2. Marcus can filter which cameras' rows are shown on the shared timeline without losing his
   current zoom/scrub position.

**What the user expects:** a busy multi-camera incident is just as navigable as a single
camera's timeline, not overwhelming because multiple rows are now involved.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** Zooming the shared timeline shall apply uniformly across every displayed camera
  row, keeping their event markers aligned and individually distinguishable.
- **[vms]** Adding or removing a camera from the shared timeline view shall preserve the
  current zoom level and scrub position rather than resetting the view.
