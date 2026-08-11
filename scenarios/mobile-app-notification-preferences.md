---
feature_id: FEAT-120
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Granular Notification Preferences

Covers the mobile-app primary side of FEAT-120: configuring push-notification delivery by
camera, rule, event type, schedule, severity, and user.

## Scenario: Configuring notifications for one camera and event type

**Scenario ID:** SCN-442
**Feature ID:** FEAT-120

**Persona:** Priya wants notifications only for person detections at her front door, not every
motion event from every camera.

1. Priya opens notification settings and, per camera, chooses which event types she wants
   pushed (e.g. Person = on, Vehicle = on, Motion = off) for the front-door camera.
2. She sets a minimum severity threshold so only medium-or-higher severity events notify her.
3. Saved preferences take effect immediately — a matching event after saving triggers a
   notification; a filtered-out event type does not.

**What the user expects:** she controls notification noise precisely, camera by camera and
event type by event type, not an all-or-nothing switch.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure notification delivery per camera, per
  event type/object class, and by minimum severity threshold.
- **[cloud-components]** The cloud notification-routing layer shall apply the user's current
  preferences at delivery time, so a preference change takes effect for the next matching event
  without requiring an app restart or reconnect.

## Scenario: No notification preferences configured yet (new user default)

**Scenario ID:** SCN-443
**Feature ID:** FEAT-120

**Persona:** Priya just finished setting up her first camera and hasn't touched notification
settings at all.

1. With no explicit preferences set, the app applies a sensible default (e.g. notify on all
   medium-and-above severity events for all cameras) rather than sending nothing or
   everything indiscriminately.
2. The notification settings screen makes clear these are defaults, not choices Priya
   explicitly made, inviting her to customize them.

**What the user expects:** out of the box, notifications are useful without configuration, but
it's obvious to her that she's seeing defaults she can still change.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall apply a documented default notification configuration for a
  camera/user with no explicit preferences set, rather than notifying on everything or nothing.
- **[mobile-app]** The notification settings screen shall visually indicate when displayed
  values are unmodified defaults versus user-customized settings.

## Scenario: Scheduling quiet hours for notifications

**Scenario ID:** SCN-444
**Feature ID:** FEAT-120

**Persona:** Priya doesn't want to be woken up by routine motion alerts overnight, but still
wants high-severity alerts to come through.

1. Priya sets a schedule (e.g. 11 PM–6 AM) during which only high-severity events notify her;
   lower-severity events during that window are still recorded and visible in the app, just
   not pushed.
2. Outside the scheduled window, her normal severity threshold applies again automatically.
3. If a genuinely high-severity event occurs during quiet hours, she still receives the
   notification despite the schedule.

**What the user expects:** quiet hours reduce noise without creating a blind spot for
genuinely important events.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure a schedule during which only events at or
  above a specified (typically higher) severity threshold trigger notifications, with normal
  thresholds resuming automatically outside the schedule.
- **[cloud-components]** The notification-routing layer shall evaluate the user's active
  schedule at the moment of each event to decide whether to deliver a push notification.

## Scenario: Different household members receive different notifications for the same camera

**Scenario ID:** SCN-445
**Feature ID:** FEAT-120

**Persona:** Priya wants only herself notified for the backyard camera's pet-related motion,
while her partner wants person-detection alerts from every camera.

1. Each household member configures their own notification preferences independently; one
   member's settings don't overwrite or constrain another's.
2. When a qualifying event occurs, only the members whose preferences match it receive a push
   notification — the same event can notify one member and not another.

**What the user expects:** notification preferences are personal to each account, not a single
shared household-wide setting.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Notification preferences shall be configured and stored per individual user
  account, not shared or overwritten across household members.
- **[cloud-components]** The notification-routing layer shall evaluate each qualifying event
  independently against every subscribed user's own preferences, delivering to only the users
  whose preferences match.
