---
feature_id: FEAT-122
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Data-Freshness Indicator

Covers the VMS side of FEAT-122: freshness indicators across a multi-camera dashboard and live
views for a fleet operator.

## Scenario: Operator distinguishes live, delayed, and offline feeds across the dashboard

**Scenario ID:** SCN-454
**Feature ID:** FEAT-122

**Persona:** Marcus scans the fleet dashboard, where different cameras are in different
connectivity states simultaneously.

1. Cameras streaming normally show a "Live" badge on their thumbnail; a camera whose feed is
   noticeably buffered/delayed (e.g. congested site network) shows "Delayed" instead.
2. An offline camera's thumbnail shows its last-known frame labeled with a timestamp, distinct
   from both Live and Delayed states.
3. Marcus can tell, per camera, exactly what kind of data he's looking at without opening each
   one individually.

**What the user expects:** across a whole fleet with mixed connectivity, each camera's tile
honestly represents its own current freshness state.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The dashboard shall display a per-camera freshness badge (Live, Delayed, Last
  Known, Unavailable) reflecting that camera's actual current data state.
- **[camera-firmware]** Each camera shall report enough timing/connectivity information (stream
  delay, last-successful-frame timestamp) for the VMS to derive accurate freshness state per
  camera.

## Scenario: A camera goes offline mid-review, live view degrades to last-known

**Scenario ID:** SCN-455
**Feature ID:** FEAT-122

**Persona:** Marcus is actively watching a camera's live view when it loses connectivity.

1. The live-view player detects the loss and switches its freshness indicator from "Live" to
   "Last Known," freezing on the final received frame with its capture timestamp shown.
2. The VMS periodically retries reconnecting in the background; if it reconnects, the indicator
   returns to "Live" automatically without Marcus needing to refresh the page.

**What the user expects:** a live session going stale is reflected immediately and honestly,
and recovers on its own once connectivity returns.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The live-view player shall detect a stream interruption and switch its freshness
  indicator to "Last Known" with the last frame's timestamp, rather than continuing to display
  a "Live" badge on a frozen frame.
- **[vms]** The live-view player shall automatically attempt reconnection and restore the
  "Live" indicator once the stream resumes, without requiring a manual page refresh.
