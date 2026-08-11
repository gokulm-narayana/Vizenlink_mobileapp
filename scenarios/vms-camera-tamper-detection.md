---
feature_id: FEAT-083
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Camera Tamper Detection (Blocked View & View Movement)

Covers the fleet-operator-facing side of FEAT-083: how a blocked-view or view-movement tamper
alert surfaces in the VMS across a multi-camera deployment.

## Scenario: Tamper alert surfaces distinctly in a multi-camera alert feed

**Scenario ID:** SCN-312
**Feature ID:** FEAT-083

**Persona:** Dana, a site operator managing 30 cameras across an office building, monitoring the
shared VMS alert feed.

1. One camera's view is suddenly blocked. Within moments, that camera's tile in the VMS grid
   shows a tamper-attention badge, and the alert feed logs a "Tamper — View Blocked" entry with
   the camera name and location.
2. The entry is visually distinguished (color/icon) from ordinary motion/detection alerts so
   Dana can tell at a glance it needs different handling.
3. Dana clicks into the entry and sees the last usable frame before the blockage plus the
   current (blocked) frame, so she can judge severity without leaving her desk.
4. She dispatches someone to physically check the camera and, once resolved, the tile reverts to
   normal in the grid.

**What the user expects:** across dozens of cameras, a tamper condition on any single one stands
out clearly in the feed and grid, rather than getting lost among routine activity alerts.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall render a tamper condition (blocked view or view movement) as a
  distinctly styled badge on the affected camera's grid tile and as a distinctly categorized
  entry in the shared alert feed, separate from motion/detection alerts.
- **[vms]** The VMS shall show the last known-good frame alongside the current frame for an
  active tamper alert, to support rapid remote triage.
- **[camera-firmware]** The camera shall include its last usable pre-tamper frame reference
  alongside the tamper event so a remote viewer can assess severity without a live feed.

## Scenario: View-movement alert during a legitimate maintenance reposition

**Scenario ID:** SCN-313
**Feature ID:** FEAT-083

**Persona:** Dana's maintenance contractor is on-site adjusting a camera's mounting bracket as
part of scheduled work, which the VMS reads as a significant framing change.

1. The VMS raises a "View Moved" tamper alert for that camera while the contractor is actively
   adjusting it.
2. Because Dana knows maintenance is scheduled, she acknowledges the alert from the VMS and
   marks it as expected/authorized rather than dismissing it as noise.
3. Once the contractor finishes and the new framing is stable, Dana triggers a re-baseline of
   that camera's reference view from the VMS so future comparisons use the corrected position.
4. The maintenance acknowledgment and the reference-view update are both recorded against that
   camera's history, distinguishing this from an unexplained/unauthorized movement.

**What the user expects:** planned maintenance that changes a camera's framing doesn't get
treated identically to an unauthorized tamper event once she's acknowledged it, and the system
doesn't keep re-alerting on the same, now-intentional, framing.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator acknowledge a view-movement alert as
  authorized/expected (e.g. maintenance) and shall record that acknowledgment distinctly from an
  unresolved or unauthorized tamper event in the camera's history.
- **[vms]** The VMS shall provide a control to trigger re-capture of a camera's reference view
  after an acknowledged, intentional reposition, so subsequent comparisons use the new framing.
- **[camera-firmware]** The camera shall accept a reference-view re-baseline command from an
  authorized VMS operator and stop comparing against the stale reference immediately upon
  receiving it.
