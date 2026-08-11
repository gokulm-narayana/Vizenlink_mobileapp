---
feature_id: FEAT-126
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Event Incident Case-Management

Covers FEAT-126: operator-facing case-management fields on an event for community/office
deployments — annotations, incident status, assignee, and operator notes.

## Scenario: Operator opens an incident case and adds context

**Scenario ID:** SCN-473
**Feature ID:** FEAT-126

**Persona:** Marcus reviews a flagged event that looks like it may need follow-up (an unfamiliar
person lingering near a side entrance after hours).

1. Marcus opens the event and, beyond the ordinary Confirm/Dismiss actions, sets its incident
   status to "Investigating" and adds a free-text note describing what he observed.
2. The event now displays its incident status and note wherever it appears in the event
   list/timeline, not just on its own detail page.
3. Other operators viewing the same event see Marcus's note and status, so the incident's
   context isn't locked inside his own session.

**What the user expects:** turning a flagged event into a tracked incident is a first-class,
persistent action other team members can see and build on.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator set an incident status (e.g. Open, Investigating,
  Resolved) and add free-text notes on an event, independent of the event's Confirm/Dismiss/
  False Alert review action.
- **[vms]** An event's incident status and notes shall be visible to every operator with access
  to that event, not scoped to the session of whoever set them.

## Scenario: Assigning an incident to a specific operator

**Scenario ID:** SCN-474
**Feature ID:** FEAT-126

**Persona:** Diane, the site administrator, wants a specific operator to own following up on
the incident from SCN-473.

1. Diane opens the incident and assigns it to that operator by name.
2. The assigned operator sees the incident appear in a personal "assigned to me" view, and
   receives an indication (e.g. a badge count) that they have an open assignment.
3. Reassigning the incident to someone else updates the assignee visibly, with the change and
   who made it recorded.

**What the user expects:** incidents can be routed to a specific responsible person, not just
left open for whoever happens to look.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an authorized operator assign an incident to a specific team
  member, surfaced to that member as a distinct "assigned to me" view.
- **[vms]** Reassigning an incident shall record who made the change and when, alongside the
  new assignee.

## Scenario: Resolving an incident with a closing note

**Scenario ID:** SCN-475
**Feature ID:** FEAT-126

**Persona:** The assigned operator from SCN-474 finishes investigating and determines it was a
resident's authorized guest.

1. The operator sets the incident status to "Resolved" and is prompted (or at least invited) to
   add a closing note summarizing the outcome.
2. The event's incident case becomes read-mostly at that point — its status/assignee history is
   preserved, but the resolved state is clearly the final one in the record.
3. The resolved incident remains fully visible in event history/search, distinguishable from
   still-open incidents by its status.

**What the user expects:** closing out an incident leaves a clear, permanent record of what
happened and how it was resolved, not just a status flip with no explanation.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** Setting an incident's status to "Resolved" shall support an accompanying closing
  note, and the incident's status/assignee/note history shall remain visible after resolution.
- **[vms]** Resolved incidents shall remain searchable/filterable distinctly from open/
  investigating incidents in the event list.

## Scenario: Reopening a resolved incident after new information surfaces

**Scenario ID:** SCN-476
**Feature ID:** FEAT-126

**Persona:** A week after the incident from SCN-475 was resolved, a similar event recurs and
Diane suspects it may be related, prompting her to reopen the original case.

1. Diane reopens the resolved incident, which returns it to an active status (e.g.
   "Investigating") rather than requiring a brand-new incident to be created from scratch.
2. The reopen action, and the original resolution note, are both preserved in the incident's
   history — nothing about the prior resolution is overwritten or lost.
3. The reassigned/reopened incident again surfaces in relevant operators' active-incident views.

**What the user expects:** a closed case isn't a dead end — it can be revived without losing
its prior history when it turns out to still matter.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an authorized operator reopen a previously-resolved incident,
  returning it to an active status without discarding its prior status/note/assignee history.
- **[vms]** Reopening an incident shall append to its history rather than overwrite the record
  of its earlier resolution, and shall cause it to reappear in relevant operators' active-
  incident views.
