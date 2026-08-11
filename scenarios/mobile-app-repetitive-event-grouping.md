---
feature_id: FEAT-121
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Repetitive Event Grouping for Notifications

Covers FEAT-121: collapsing a burst of repetitive events into a single grouped push
notification, while every underlying event stays individually accessible in the timeline.

## Scenario: A burst of repeated motion events collapses into one notification

**Scenario ID:** SCN-448
**Feature ID:** FEAT-121

**Persona:** Priya's backyard camera flags the same person moving around 20 times within two
minutes (e.g. someone doing yard work who keeps crossing the detection zone).

1. Instead of 20 separate push notifications arriving in rapid succession, Priya receives one
   grouped notification summarizing the burst (e.g. "20 activity events in the last 2 minutes —
   Backyard").
2. The grouped notification is delivered promptly after the burst is recognized as repetitive,
   not held back until some fixed long delay.

**What the user expects:** she isn't spammed with near-duplicate notifications for what is
clearly one continuous episode of activity.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app/notification layer shall detect a burst of similar events from the
  same camera within a short time window and deliver a single grouped notification summarizing
  the count, rather than one notification per event.
- **[cloud-components]** The notification-routing layer shall perform event-burst grouping
  before dispatching push notifications, so grouping happens once centrally rather than being
  reconstructed independently per device.

## Scenario: Tapping the grouped notification reveals every individual event

**Scenario ID:** SCN-449
**Feature ID:** FEAT-121

**Persona:** Priya taps the grouped notification from SCN-448 to see what actually happened.

1. Tapping the notification opens a view listing every one of the 20 underlying events
   individually, each still viewable with its own snapshot/clip/timestamp.
2. From there, Priya can also see all 20 events represented individually as markers on the
   camera's unified timeline (FEAT-118) — grouping only affects the notification, never the
   underlying event record.

**What the user expects:** grouping reduces notification noise without losing any of the
underlying detail — she can still drill into every individual moment if she wants to.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Tapping a grouped notification shall open a list of every individual event
  it summarized, each independently viewable.
- **[mobile-app]** Grouping shall affect notification delivery only — every underlying event
  shall remain individually present and accessible in the event list/timeline, never merged or
  discarded.

## Scenario: A burst mixes unrelated event types and severities

**Scenario ID:** SCN-450
**Feature ID:** FEAT-121

**Persona:** Priya's driveway camera flags several routine motion events and, in the middle of
the same burst window, one high-severity event (e.g. a person lingering near her car door).

1. The routine, similar-severity events in the burst are grouped together as usual.
2. The high-severity event is **not** folded into the grouped notification — it's delivered as
   its own distinct, immediate notification, so it isn't buried inside a summary Priya might
   deprioritize.

**What the user expects:** grouping only ever suppresses redundant noise — it never quietly
absorbs a genuinely important event into a low-priority summary.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Event-burst grouping shall only combine events of comparable type and
  severity; an event exceeding the group's severity level shall always be delivered as its own
  separate, immediate notification rather than folded into the group.
- **[cloud-components]** The notification-routing layer's grouping logic shall evaluate each
  event's severity against the rest of its candidate burst before deciding whether to group it,
  rather than grouping purely by time-window and camera.
