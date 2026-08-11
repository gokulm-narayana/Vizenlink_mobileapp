---
feature_id: FEAT-105
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Severity-Based Eviction Priority

Covers the homeowner-facing side of FEAT-105: when the offline buffer is under pressure, higher-
severity evidence is protected ahead of routine events.

## Scenario: Person-detection event survives an outage that drops routine motion events

**Scenario ID:** SCN-387
**Feature ID:** FEAT-105

**Persona:** Marcus's camera fills its offline queue during a long outage, during which both a
person-detection event (someone walking up his driveway) and several routine motion-only events
(tree branches swaying) occur.

1. Once the outage resolves, Marcus's timeline shows the person-detection event fully preserved
   with its clip, while he learns (per FEAT-104/106) that some of the low-priority routine motion
   events from that window were dropped to make room.
2. He isn't left wondering whether his most important evidence made it — the app's disclosure
   makes clear what kind of events were protected versus dropped.
3. This matches what he'd expect: routine noise is expendable under pressure, meaningful
   security events are not.

**What the user expects:** if something has to be sacrificed when storage is under pressure, it
should be the routine noise, never the events that actually matter to his security.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall reflect, when reporting dropped events after an outage, that
  higher-severity events (e.g. person/vehicle detections) were prioritized for retention over
  lower-priority routine events (e.g. plain motion), so the user understands what kind of
  content was protected.
- **[camera-firmware]** The camera shall apply a severity-based eviction order in its local event
  queue under storage pressure, evicting lower-priority/routine events before higher-severity
  detections.

## Scenario: Queue fills entirely with high-severity events during an unusually active outage

**Scenario ID:** SCN-388
**Feature ID:** FEAT-105

**Persona:** Marcus's camera experiences an outage during an unusually active period (e.g. a
string of deliveries and visitors), generating more high-severity events than usual — enough
that even prioritized retention starts running out of room.

1. Once outage ends, Marcus's timeline shows all of the highest-severity events preserved, but
   the app is honest that even some higher-priority events had to be evicted once the queue was
   overwhelmed entirely — it doesn't falsely claim that "important events are never dropped" once
   genuinely at capacity.
2. The disclosure distinguishes this from the routine case: rather than a generic "some routine
   events were dropped" note, it makes clear the situation was more severe (even higher-priority
   content was affected).
3. Marcus understands the severity prioritization worked as designed, but wasn't a guarantee
   against all loss in an extreme case.

**What the user expects:** severity-based protection is understood as a best-effort priority
order, not an absolute guarantee — and the app is honest with him about which case actually
occurred.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall distinguish, in its dropped-event disclosure, between "only
  lower-priority events were dropped" and "the queue was overwhelmed and some higher-priority
  events were also affected," so the user isn't given a false sense that severity-priority is an
  absolute guarantee.
- **[camera-firmware]** The camera shall record, per dropped event, whether it was
  lower-priority or higher-priority at time of eviction, so this distinction can be reported
  accurately.
