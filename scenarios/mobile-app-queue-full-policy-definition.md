---
feature_id: FEAT-104
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Queue-Full Policy Definition

Covers the homeowner-facing side of FEAT-104: honestly communicating what happens when the
offline event queue fills, rather than implying unlimited or zero-loss retention.

## Scenario: Priya learns her camera's offline retention isn't unlimited, up front

**Scenario ID:** SCN-383
**Feature ID:** FEAT-104

**Persona:** Priya, setting up her camera for the first time, reviewing its offline-behavior
settings.

1. During setup (or in a help/info screen she can find later), the app plainly states the
   camera's offline event queue has a defined capacity — e.g. "buffers events locally during an
   outage; lower-priority events may be dropped if an outage lasts an extended period" — instead
   of silently implying nothing is ever lost.
2. She isn't left to discover the limit only after an outage causes actual data loss and she
   complains.
3. If she wants, she can find this explained in plain terms, without needing to read a technical
   spec to understand the tradeoff.

**What the user expects:** the app sets accurate expectations about offline retention limits
before she ever needs to rely on them, rather than an implicit promise of infinite retention
that later turns out false.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall plainly disclose, in setup and/or a discoverable help section,
  that the offline event queue has a finite capacity and that lower-priority events may be
  dropped during an extended outage — never implying unlimited or guaranteed zero-loss
  retention.
- **[camera-firmware]** The camera shall enforce a defined, finite local event-queue capacity
  and a documented eviction behavior once full, rather than an undefined or unbounded buffer.

## Scenario: The queue actually fills during a real outage, and Priya is told what happened

**Scenario ID:** SCN-384
**Feature ID:** FEAT-104

**Persona:** Priya experiences an outage long enough that her camera's local queue genuinely
fills up.

1. Once connectivity is restored, the app doesn't just quietly backfill whatever survived — it
   tells her plainly that the queue reached capacity during the outage and that some events
   were dropped, consistent with the policy she was told about during setup.
2. She can see roughly how many/what kind of events were affected, per FEAT-106's dropped-event
   accounting, rather than just a vague disclaimer.
3. This matches what she was told to expect at setup — no surprise gap between the stated policy
   and what actually happened.

**What the user expects:** when the documented limit is actually hit, the consequence she was
warned about at setup is exactly what she experiences and is told about after the fact — no
mismatch between policy and reality.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall explicitly notify the user, after an outage during which the
  local queue reached capacity, that events were dropped and roughly how many/what kind, per
  FEAT-106's accounting.
- **[camera-firmware]** The camera shall record queue-full occurrences (start time, duration,
  approximate count of affected events) so this can be accurately reported to the user
  afterward.
