---
feature_id: FEAT-115
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Deep-Link to Live View from Card/Event

Covers the VMS side of FEAT-115: clicking a camera's dashboard card or an event's detail view
jumps straight into that camera's live view (no push-notification channel exists in the VMS).

## Scenario: Operator clicks a camera card and lands directly in live view

**Scenario ID:** SCN-418
**Feature ID:** FEAT-115

**Persona:** Marcus is scanning the fleet dashboard and wants to check one camera's current feed.

1. Marcus clicks a camera's card on the dashboard grid.
2. The VMS opens that camera's live view directly — no intermediate "camera details" page he
   has to click through first.
3. Live video begins streaming automatically.

**What the user expects:** one click from the dashboard gets him watching, not browsing menus.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** Clicking a camera card on the dashboard shall navigate directly to that camera's
  live view, with streaming starting automatically.
- **[vms]** The live-view page reached this way shall retain a visible path back to the
  dashboard (e.g. breadcrumb or back control).

## Scenario: Operator jumps from an event's detail view to live monitoring

**Scenario ID:** SCN-419
**Feature ID:** FEAT-115

**Persona:** Marcus is reviewing a flagged event from earlier and wants to see if the same area
is still active right now.

1. From the event detail view, Marcus clicks a "View Live" control tied to that event's camera.
2. The VMS opens that camera's live view in the current tab or a new one, per the operator's
   existing navigation pattern, without losing his place in the event review.
3. If Marcus later returns to the event list, his filter/scroll position from before is still
   intact.

**What the user expects:** checking live status from an event doesn't cost him his place in
whatever review workflow he was in.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The event detail view shall offer a "View Live" control that deep-links to the
  event's camera live view, without discarding the operator's current event-list filter/scroll
  state.
- **[vms]** Returning from a deep-linked live view to the event list shall restore the
  operator's prior filter and scroll position rather than resetting to a default view.
