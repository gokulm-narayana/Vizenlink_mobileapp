---
feature_id: FEAT-133
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Real-Time Cross-User Event Status Sync

Covers the mobile-app side of FEAT-133: when one authorized user acts on an event, that status
updates in real time for every other user who can see the same event.

## Scenario: One household member confirms an event; another sees it update live

**Scenario ID:** SCN-503
**Feature ID:** FEAT-133

**Persona:** Priya and her partner both have the app open, both looking at the same event
notification about their front door.

1. Priya taps "Confirm" on the event first.
2. Within a few seconds, her partner's app — without any action on their part — updates that
   same event's status to show it's already been confirmed, and by Priya specifically.
3. The action buttons on the partner's screen update accordingly (e.g. "Confirm" no longer
   shown as an available action to take again, since it's already done).

**What the user expects:** household members sharing the same cameras never have to
coordinate manually to avoid duplicate work — the app keeps everyone in sync automatically.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall update an event's displayed status and available actions in
  real time when any authorized user acts on it, for every other user currently viewing that
  event.
- **[mobile-app]** An updated event status shall show which user performed the action, so
  other viewers know who already handled it.
- **[cloud-components]** The cloud service shall broadcast an event-status change to every
  connected client with access to that event promptly, rather than relying on each client to
  poll for updates.

## Scenario: Two members act on the same event within moments of each other

**Scenario ID:** SCN-504
**Feature ID:** FEAT-133

**Persona:** Priya taps "False Alert" at almost the same moment her partner taps "Confirm" on
the same event, each unaware the other is also looking at it.

1. The system resolves this to one final, consistent status (whichever action was recorded
   first) rather than leaving the event in a contradictory state.
2. The member whose action didn't take effect sees, moments later, that the event's status is
   already something else, along with who set it — so they understand the discrepancy rather
   than being confused about why their tap seemingly didn't work.

**What the user expects:** even near-simultaneous conflicting actions from different household
members never leave the event in an ambiguous or contradictory state.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall clearly indicate to a user whose action was superseded by
  another user's near-simultaneous action which status actually took effect and who set it,
  rather than leaving their own attempted action's outcome ambiguous.
- **[cloud-components]** The cloud service shall resolve near-simultaneous conflicting
  event-action requests to a single, well-defined final status, consistent with the equivalent
  VMS-side conflict resolution.

## Scenario: A household member was offline when another member actioned the event

**Scenario ID:** SCN-505
**Feature ID:** FEAT-133

**Persona:** Priya's partner confirmed an event while Priya's phone was out of signal range.

1. When Priya's phone regains connectivity and she opens the app (or the event, if already
   open), the event shows the already-confirmed status and who confirmed it — it does not show
   stale, still-actionable buttons from before she lost connectivity.
2. Priya does not receive a redundant notification prompting her to review an event someone
   else already resolved while she was offline, consistent with the notification-noise intent
   behind FEAT-121's grouping.

**What the user expects:** missing the moment an event was resolved doesn't leave her with
stale, confusing state or a redundant nudge to act on something already handled.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall refresh an event's current status from the server on
  reconnect/foreground rather than continuing to display a stale, already-superseded state from
  before the disconnection.
- **[cloud-components]** The notification-routing layer shall suppress a redundant action-
  prompting notification to a user for an event another authorized user has already resolved,
  even if that resolution happened while the first user was offline.
