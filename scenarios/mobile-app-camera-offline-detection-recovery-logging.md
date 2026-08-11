---
feature_id: FEAT-085
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md]
---

# Scenario: Mobile App — Camera Offline Detection & Recovery-Time Logging

Covers the homeowner-facing side of FEAT-085: the app detecting an offline camera and showing
how long it was down and when it recovered.

## Scenario: Camera goes offline overnight and Priya checks in the morning

**Scenario ID:** SCN-320
**Feature ID:** FEAT-085

**Persona:** Priya, a homeowner whose camera loses connectivity overnight due to a router
restart, and comes back on its own before she wakes up.

1. Priya missed any real-time alert because she was asleep, but opening the app in the morning
   she sees a past-event entry: "Camera was offline from 2:14 AM to 2:31 AM (17 min)."
2. The entry is timestamped in her local time and clearly separates "went offline" from "came
   back online" rather than a single ambiguous line.
3. She can tap the entry for more detail if she wants, but the headline duration is visible
   without digging.

**What the user expects:** even if she wasn't there to see it happen, the app keeps an accurate
record of exactly when and for how long her camera was unreachable.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall log each offline occurrence for a camera with its start
  timestamp, recovery timestamp, and computed duration, viewable in the camera's history even if
  no user was actively watching when it happened.
- **[camera-firmware]** The camera (or the cloud service tracking its heartbeat) shall record the
  timestamp of the last successful contact before an outage and the timestamp of the first
  successful contact after recovery, so an accurate offline duration can be computed.

## Scenario: Camera goes offline for an extended period and never fully recovers cleanly

**Scenario ID:** SCN-321
**Feature ID:** FEAT-085

**Persona:** Priya's camera loses power for two days while she's traveling, then comes back
online but takes several more reconnect attempts before it's stable.

1. Priya gets an offline alert when the outage crosses the notification threshold, and the app
   shows the offline period as "ongoing" (open-ended) rather than a fixed duration while it's
   still down.
2. When the camera starts reconnecting but drops again a few times before staying up, the app
   doesn't log this as several short, confusing separate outages — it recognizes the flapping
   period as part of one overall recovery and logs a single clean outage entry once the camera
   is genuinely stable again.
3. The final logged entry shows the true total offline duration and the timestamp of the
   confirmed, stable recovery.

**What the user expects:** a long outage with a flaky reconnect at the end still produces one
sensible, accurate record — not a wall of noisy micro-entries.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display an in-progress offline event as open-ended (no recovery
  time yet) until the camera is confirmed stable, rather than guessing a duration.
- **[camera-firmware]** The camera/cloud health tracking shall debounce a flapping
  reconnect-then-drop sequence during recovery and log a single outage record with the
  first-lost and confirmed-stable-recovery timestamps, rather than one record per brief
  reconnect attempt.
- **[cloud-components]** The cloud health service shall apply a minimum stability window before
  marking a reconnecting camera's outage as "recovered," to avoid prematurely closing the
  offline record on a flapping connection.
