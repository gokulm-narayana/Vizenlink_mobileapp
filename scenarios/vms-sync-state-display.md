---
feature_id: FEAT-101
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: VMS — Sync State Display

Covers the fleet-operator-facing side of FEAT-101: seeing sync lifecycle state across many
cameras' events, useful for verifying evidence integrity at scale.

## Scenario: Operator confirms an incident's evidence is fully verified before sharing it

**Scenario ID:** SCN-373
**Feature ID:** FEAT-101

**Persona:** Dana needs to hand off video evidence from an incident to building security within
the hour.

1. Dana opens the relevant event in the VMS and checks its sync state before sharing it — it
   reads "Verified," confirming the clip's integrity has been checked and it's safe to treat as
   the authoritative copy.
2. Had it instead read "Uploading" or "Failed," the VMS would make clear she shouldn't treat that
   copy as final/authoritative yet, avoiding her handing off unverified evidence.
3. She proceeds with the handoff, confident in the clip's state.

**What the user expects:** the sync state gives her an explicit integrity signal she can rely on
before treating any piece of evidence as final, rather than assuming anything visible in the VMS
is automatically trustworthy.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display each event's sync-lifecycle state prominently enough that an
  operator can confirm "Verified" status before treating a clip as authoritative evidence.
- **[vms]** The VMS shall visually warn against treating a non-"Verified" clip (uploading,
  failed, discarded) as finalized evidence.

## Scenario: Operator monitors sync-state distribution across the fleet to spot a systemic problem

**Scenario ID:** SCN-374
**Feature ID:** FEAT-101

**Persona:** Dana notices an unusually high proportion of events sitting in "Failed" state across
several cameras at once.

1. The VMS's fleet-wide sync-state summary shows the count of events currently in each state
   (local-only, pending, uploading, verified, failed, discarded) across the whole site, and Dana
   spots the Failed count is much higher than normal.
2. She drills into the failed events and finds they cluster on cameras sharing the same recent
   firmware version, suggesting a systemic sync bug rather than isolated storage failures.
3. She escalates with this fleet-wide pattern as supporting evidence, rather than only having
   noticed one isolated failed event.

**What the user expects:** aggregate visibility into sync-state distribution across the fleet
lets her catch a systemic sync problem early, instead of only ever seeing failures one event at
a time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-wide summary of event counts per sync-lifecycle state,
  to support identifying an abnormal spike in any one state.
- **[vms]** The VMS shall let an operator drill from an elevated "Failed" count into the specific
  affected events/cameras, to help correlate a systemic pattern (e.g. shared firmware version).
