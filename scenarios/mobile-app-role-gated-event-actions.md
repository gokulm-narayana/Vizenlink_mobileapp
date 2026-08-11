---
feature_id: FEAT-117
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Role-Gated Event Actions

Covers the mobile-app side of FEAT-117: per-event action buttons (Confirm, Dismiss, False
Alert, Save, Share/Export, Escalate) shown according to the acting user's role.

## Scenario: Household owner sees and uses the full set of event actions

**Scenario ID:** SCN-425
**Feature ID:** FEAT-117

**Persona:** Priya, the account owner, opens an event and wants to mark it reviewed.

1. Priya sees the full set of action buttons on the event: Confirm, Dismiss, False Alert, Save,
   Share/Export.
2. She taps "Confirm" to acknowledge it as a real, reviewed event; the button updates to show
   the event is now confirmed, and the action is attributed to her.
3. She separately taps "Share" on another event to generate a shareable clip link for a
   neighbor.

**What the user expects:** as the owner, she has full control over every event, and each action
she takes is clearly recorded as done by her.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The event detail screen shall show Confirm, Dismiss, False Alert, Save, and
  Share/Export actions to a user whose role grants full event-management permission.
- **[mobile-app]** Taking an action on an event shall record which user performed it and update
  the event's visible status accordingly.
- **[cloud-components]** Event-action commands (confirm/dismiss/etc.) issued from the app shall
  be relayed to the account's shared event record so the action is durably stored, not just
  reflected locally on the acting device.

## Scenario: A household member with limited permission sees a reduced action set

**Scenario ID:** SCN-426
**Feature ID:** FEAT-117

**Persona:** Priya has invited her teenage child as a "Viewer" household member with restricted
permissions; the child opens the same event.

1. The child sees the event's snapshot, clip, and detail exactly as Priya would.
2. The action buttons available are limited to what a Viewer role permits (e.g. only
   "Dismiss"), with actions like "Escalate" or permanent deletion-adjacent actions not shown
   at all — not shown-but-disabled, simply absent.
3. If the child takes the one action available, it's attributed to their own account, distinct
   from an action Priya might take on the same event.

**What the user expects:** a restricted household member can still review what happened, but
can't take actions their role isn't meant to allow — and it isn't confusing clutter of
grayed-out buttons they can't use.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The event detail screen shall show only the action buttons the acting user's
  role permits, omitting unavailable actions entirely rather than showing them disabled.
- **[access-control]** Event-action permissions (Confirm, Dismiss, False Alert, Save,
  Share/Export, Escalate) shall be governed by the household's role/permission model, with each
  role's allowed action set explicitly defined.
- **[mobile-app]** Every event action shall record the specific household member who took it,
  distinct from any other member's actions on the same event.

## Scenario: An unauthorized action attempt is rejected server-side, not just hidden client-side

**Scenario ID:** SCN-427
**Feature ID:** FEAT-117

**Persona:** A restricted household member's app is running an out-of-date version that still
shows an action their current role no longer permits (e.g. their permission was recently
downgraded).

1. The member taps an action their role no longer allows.
2. The request is rejected, and the app shows a clear permission-denied message rather than
   silently succeeding or silently failing.
3. The event's status is unchanged by the rejected attempt.

**What the user expects:** permission enforcement doesn't rely solely on the app hiding
buttons correctly — an out-of-sync client can't bypass the household's actual permission rules.

> **Review:** ⏳ Pending

### Derived Requirements

- **[cloud-components]** Every event-action request shall be authorized against the acting
  user's current role at the time of the request, independent of what the requesting client's
  UI currently displays.
- **[mobile-app]** The app shall surface a clear permission-denied message when an action
  request is rejected for insufficient permission, and shall leave the event's displayed status
  unchanged.
