---
feature_id: FEAT-177
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-health-monitoring.md]
---

# Scenario: VMS — Staged Firmware Rollout with Health Check & Version Inventory

Covers FEAT-177 as experienced by a fleet operator in the VMS: rolling a firmware update out to
a canary subset before the full fleet, automated post-update health checks, rollback on
failure, and a queryable version inventory across all managed cameras.

## Scenario: Staged rollout to a canary subset succeeds

**Scenario ID:** SCN-609
**Feature ID:** FEAT-177

**Persona:** Raj, a VMS fleet operator managing 40 cameras across three community sites, wants
to roll out a new firmware version without risking a simultaneous fleet-wide failure.

1. Raj opens the Firmware Rollout screen in VMS and selects the new firmware version staged for
   deployment.
2. Instead of pushing to all 40 cameras at once, he selects a canary subset (e.g. 10%, or a
   manually chosen group) and starts the rollout to that group only.
3. VMS shows each canary camera's update progress (downloading, applying, rebooting) and, once
   each comes back online, an automated health-check result — not just "online/offline."
4. After the canary group reports healthy through a defined observation window, VMS surfaces a
   "Promote to remaining fleet" action; Raj reviews the canary health summary and promotes.
5. The remaining cameras receive the same update in the same staged, health-checked manner.

**What the user expects:** he doesn't have to gamble the whole fleet on one update — a bad build
only affects the small canary slice, and the rest of the fleet is never touched until canary
health is actually confirmed.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator select a canary subset of the fleet for a firmware
  rollout rather than only supporting an all-or-nothing push to every camera at once.
- **[vms]** The VMS shall display each updated camera's automated post-update health-check
  result, distinct from and in addition to its post-reboot online/offline status.
- **[vms]** The VMS shall require an explicit operator action to promote a rollout from canary
  to full fleet, rather than auto-promoting once canary devices simply reboot successfully.
- **[camera-firmware]** The camera shall run a defined automated health check (boot success,
  video pipeline initialization, network reachability) immediately after applying an OTA update
  and report the result, rather than only reporting that it rebooted.

## Scenario: Canary health check fails and the rollout is blocked

**Scenario ID:** SCN-610
**Feature ID:** FEAT-177

**Persona:** Raj again; this time the staged firmware build has a defect that fails the
camera's health check on canary devices.

1. Raj starts a canary rollout of the same firmware version to a 3-camera subset.
2. One canary camera fails its automated post-update health check (e.g. the video pipeline
   doesn't come back up).
3. The affected camera automatically rolls back to its previous known-good firmware rather than
   being left stuck on a broken version.
4. VMS blocks the "Promote to remaining fleet" action and surfaces the failure prominently, so
   Raj cannot accidentally push the same broken build to the other 37 cameras.
5. Raj views the failure detail (which specific health check failed) to decide whether to retry
   after a fix or abandon the rollout.

**What the user expects:** a bad canary result stops the rollout cold and reverts the affected
camera automatically — it never silently gets promoted to the rest of the fleet.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall automatically roll back to its previous known-good
  firmware version when its post-update health check fails, rather than remaining on a failed
  update indefinitely.
- **[vms]** The VMS shall block promotion of a rollout to the remaining fleet whenever any
  canary device fails its health check.
- **[vms]** The VMS shall show which specific health check failed for a rolled-back camera, so
  the operator can diagnose the cause before retrying.

## Scenario: Fleet-wide version-inventory query finds stragglers

**Scenario ID:** SCN-611
**Feature ID:** FEAT-177

**Persona:** Raj wants to confirm which cameras, if any, are still on an old, unpatched firmware
version some time after a rollout was declared complete.

1. Raj opens the Version Inventory view in VMS.
2. It lists every managed camera with its currently running firmware version, last successful
   update date, and rollout group/status.
3. Raj filters for cameras still on a version older than the latest, surfacing stragglers (e.g.
   cameras that were offline during the rollout window).
4. He selects those cameras and queues them for an individual retry rollout.

**What the user expects:** one place to confirm the whole fleet is actually current, rather than
having to trust that a rollout job reporting "complete" really reached every camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall maintain a queryable, filterable version inventory (firmware version,
  last update date, rollout status) across every managed camera, refreshed on demand and after
  each rollout.
- **[camera-firmware]** The camera shall report its currently running firmware version and last
  update outcome as part of its status, so the VMS version inventory reflects camera-verified
  truth rather than an assumption from the rollout job.
