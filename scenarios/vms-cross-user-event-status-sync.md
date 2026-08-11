---
feature_id: FEAT-133
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Real-Time Cross-User Event Status Sync

Covers the VMS side of FEAT-133: when one operator acts on an event, every other operator
viewing the same site sees the update in real time, avoiding duplicated or conflicting work
across a shift team.

## Scenario: An operator's action is reflected live on every other operator's screen

**Scenario ID:** SCN-506
**Feature ID:** FEAT-133

**Persona:** Marcus and a second operator are both monitoring the same site's alert feed during
a shift handoff overlap.

1. Marcus confirms a flagged event.
2. The other operator's alert feed and event list update that event's status and available
   actions within a few seconds, without a manual refresh, and shows Marcus as the one who
   acted.
3. The event also disappears from any "unreviewed" filtered view the other operator may have
   had open, since it's no longer unreviewed.

**What the user expects:** a shared operations team never duplicates review effort because the
system silently keeps everyone's view in sync.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall update an event's status, available actions, and acting-user
  attribution in real time across every operator session viewing that site, without requiring
  manual refresh.
- **[vms]** A filtered view (e.g. "Unreviewed") shall re-evaluate and remove/add events live as
  their status changes for other operators, not just for the operator who made the change.

## Scenario: A brief sync delay is visibly reconciled rather than left inconsistent

**Scenario ID:** SCN-507
**Feature ID:** FEAT-133

**Persona:** A second operator's VMS session briefly loses its real-time connection (e.g. a
network blip) right as Marcus acts on an event.

1. The second operator's session reconnects shortly after and reconciles its event list against
   the server's current state, correcting any event whose status changed while disconnected,
   rather than continuing to show a stale view indefinitely.
2. The VMS indicates briefly (e.g. a small "reconnecting/syncing" indicator) when its real-time
   connection is degraded, so the operator knows not to fully trust the currently displayed
   state during that window.

**What the user expects:** a temporary connectivity hiccup for one operator never leaves their
view permanently out of sync with reality.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect loss of its real-time update connection and display a visible
  degraded-sync indicator, reconciling its full event state against the server immediately upon
  reconnection.
- **[vms]** Reconnection reconciliation shall correct any event status that changed during the
  disconnection window, rather than only applying updates that occur after reconnection.

## Scenario: Escalating an event suppresses a redundant escalation from another operator

**Scenario ID:** SCN-508
**Feature ID:** FEAT-133

**Persona:** Marcus escalates a high-severity event to the on-call supervisor at nearly the same
moment a second operator, also reviewing it, was about to do the same.

1. The second operator's screen updates to show the event is already escalated, by Marcus, with
   a timestamp, before they complete their own escalation action.
2. The system does not send the on-call supervisor two separate, redundant escalation
   notifications for the same event.

**What the user expects:** overlapping operator attention on the same urgent event doesn't
translate into duplicate downstream alerts to whoever gets escalated to.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall prevent a duplicate escalation action on an event already escalated by
  another operator, surfacing the existing escalation's details instead of creating a second
  one.
- **[cloud-components]** The escalation-notification path shall deduplicate against an
  already-escalated event so a downstream recipient (e.g. an on-call supervisor) receives one
  notification per event, not one per operator who attempted to escalate it.
