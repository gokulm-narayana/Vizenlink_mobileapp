---
feature_id: FEAT-187
status: draft
target_fr_docs: [FR-vms.md, FR-security-lifecycle.md]
---

# Scenario: VMS — Security-Critical Update Prioritization Messaging

Covers FEAT-187's VMS side: a fleet operator managing many cameras needs to see, at a glance,
which cameras are running an update-eligible firmware that is security-critical versus routine,
so they can prioritize patching across the fleet.

## Scenario: Fleet dashboard surfaces security-critical exposure

**Scenario ID:** SCN-622
**Feature ID:** FEAT-187

**Persona:** Raj manages 40 cameras across three sites and opens the VMS dashboard after a
security-critical firmware release goes out.

1. The fleet dashboard shows a summary banner: "12 cameras need a critical security update" —
   distinct in color/icon from the routine "8 cameras have a feature update available" line.
2. Raj filters the camera list to just the critical-update-pending cameras.
3. Each listed camera shows the same critical labeling as the dashboard summary, so there's no
   ambiguity about which update category applies to which camera.

**What the user expects:** he can immediately see fleet-wide security exposure separately from
routine update backlog, rather than one undifferentiated "updates pending" count.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS fleet dashboard shall show a security-critical update count/summary
  distinct from a routine update count/summary, rather than one combined "updates available"
  figure.
- **[vms]** The VMS shall let an operator filter the camera list to cameras with a pending
  security-critical update specifically.

## Scenario: Bulk-prioritizing a critical rollout across the filtered set

**Scenario ID:** SCN-623
**Feature ID:** FEAT-187

**Persona:** Raj, having filtered to the 12 critical-update-pending cameras, wants to patch them
ahead of his routine rollout schedule.

1. Raj selects all 12 filtered cameras and starts a rollout scoped to just that set, using this
   Feature's staged-rollout mechanism (FEAT-177) rather than pushing all 12 simultaneously.
2. VMS's rollout summary retains the critical labeling throughout the rollout, distinguishing
   this from a routine scheduled rollout in any status view or history log.

**What the user expects:** the critical/routine distinction survives all the way through to the
rollout action itself, not just the initial notification — so he can prioritize his own
operational time correctly.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow bulk-selecting cameras filtered by pending security-critical
  update status to start a scoped rollout against just that set.
- **[vms]** The VMS's rollout status/history views shall retain the security-critical vs.
  routine distinction for a rollout job, not just at the initial notification stage.

## Scenario: A critical update is deferred past a defined SLA

**Scenario ID:** SCN-624
**Feature ID:** FEAT-187

**Persona:** Raj is busy and some critical-update-pending cameras remain unpatched well past
when they were first flagged.

1. VMS escalates cameras that remain on a security-critical-update-pending state past a defined
   threshold (e.g. moving them into a distinct "overdue — critical" list rather than leaving
   them indistinguishable from freshly-flagged ones).
2. This overdue state is visible on the main dashboard, not only inside the filtered list, so it
   can't be missed by not navigating there.

**What the user expects:** the system actively escalates neglected critical patches rather than
treating "flagged once" as sufficient forever.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall escalate a camera's security-critical-update-pending state to a
  distinct "overdue" status once it exceeds a defined threshold, and surface that overdue state
  on the main dashboard.
