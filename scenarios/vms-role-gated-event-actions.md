---
feature_id: FEAT-117
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Role-Gated Event Actions

Covers the VMS side of FEAT-117: per-event action buttons gated by operator role in a
multi-operator fleet-management context.

## Scenario: Site administrator has the full action set including Escalate

**Scenario ID:** SCN-428
**Feature ID:** FEAT-117

**Persona:** Diane, a site administrator, reviews a flagged event during a security incident.

1. Diane sees Confirm, Dismiss, False Alert, Save, Share/Export, and Escalate on the event.
2. She taps Escalate; the event is marked escalated and (per the case-management/notification
   features) routed to whoever the escalation policy designates.
3. The event's status updates to show it's escalated and who escalated it.

**What the user expects:** an administrator can drive an event through its full lifecycle,
including raising it beyond routine review.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The event detail view shall show Confirm, Dismiss, False Alert, Save, Share/Export,
  and Escalate to operators whose role grants full event-management permission.
- **[vms]** Escalating an event shall record who escalated it and update its visible status to
  reflect the escalation.
- **[access-control]** The VMS role model shall define which roles may perform each event
  action, with Escalate reserved for roles explicitly granted that permission (e.g. admin/
  supervisor), distinct from ordinary operator review actions.

## Scenario: A read-only viewer role sees events with no action buttons

**Scenario ID:** SCN-429
**Feature ID:** FEAT-117

**Persona:** A community-board member has been granted a read-only "Viewer" account to monitor
activity without being able to alter event status.

1. The viewer opens an event and sees the full detail (snapshot, clip, confidence, rule
   context) exactly as an operator would.
2. No action buttons are shown at all — the viewer cannot Confirm, Dismiss, or take any other
   action, and the UI doesn't present grayed-out controls implying they almost could.

**What the user expects:** a viewer role can observe everything but genuinely cannot alter
anything, and the UI doesn't tease actions that are never actually available to them.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The event detail view shall omit all action controls entirely for a role with
  read-only permission, rather than displaying them disabled.
- **[access-control]** The VMS role model shall support a read-only role with full event
  visibility but no event-action permission at all.

## Scenario: Two operators attempt conflicting actions on the same event

**Scenario ID:** SCN-430
**Feature ID:** FEAT-117

**Persona:** Marcus and a second operator, working the same shift, both open the same flagged
event at nearly the same time.

1. Marcus taps "False Alert" a moment before the other operator taps "Confirm" on the same
   event.
2. The system applies whichever action is recorded first and rejects (or clearly flags as
   superseded) the second, conflicting action, rather than leaving the event in an ambiguous
   double-actioned state.
3. Both operators see the event's final, single resolved status, with an indication that
   another operator already acted on it.

**What the user expects:** the system prevents an event from ending up in a contradictory
state when two operators act on it almost simultaneously.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall resolve near-simultaneous conflicting event actions from different
  operators to a single, well-defined final status rather than allowing contradictory states
  (e.g. both "Confirmed" and "False Alert") to persist.
- **[vms]** When an operator's action attempt is superseded by another operator's near-
  simultaneous action, the VMS shall inform the superseded operator which action actually took
  effect and by whom.
