---
feature_id: FEAT-214
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Push Notification Delivery Latency

Covers FEAT-214's user-perceptible manifestation: a homeowner's push notification for a
qualifying event arriving promptly, so an alert still feels actionable rather than stale.

## Scenario: A motion alert arrives while Priya is nearby

**Scenario ID:** SCN-666
**Feature ID:** FEAT-214

**Persona:** Priya is in her kitchen when a person is detected at her front door.

1. Priya's phone buzzes with a "Person detected at Front Door" notification within a few seconds
   of the actual detection — quickly enough that she can glance at the live feed and still see
   what's happening, not view an empty porch after the person has already left.
2. Tapping the notification takes her straight to that event/live view.

**What the user expects:** the alert arrives while it's still useful for a real-time reaction —
checking who's there, not just reviewing what already happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[cloud-components]** A qualifying event's push notification shall be delivered to the
  mobile-push relay within 5 seconds at p95 of event creation, excluding delay introduced by the
  external mobile push-notification provider where separately measured.
- **[mobile-app]** Tapping a push notification shall take the user directly to the corresponding
  event/live view rather than a generic app-open state.

## Scenario: Delivery is delayed by the external push provider, not VizenLink's own pipeline

**Scenario ID:** SCN-667
**Feature ID:** FEAT-214

**Persona:** Priya's notification arrives noticeably late one evening; the delay is later traced
to a slowdown at the external push-notification provider, not VizenLink's own systems.

1. From Priya's point of view, the notification is simply late — she isn't shown any internal
   breakdown of where the delay occurred.
2. Internally, VizenLink's own measurement distinguishes "we handed this off to the push provider
   within budget" from "the push provider took longer to deliver it," so a systemic provider
   slowdown doesn't get misattributed as a VizenLink pipeline regression, and vice versa.

**What the user expects (indirectly):** VizenLink's own responsiveness is measured and held to
its target honestly, rather than the metric being padded or blamed on a third party without
evidence.

> **Review:** ⏳ Pending

### Derived Requirements

- **[cloud-components]** The push-delivery latency measurement shall separately record the time
  from event creation to hand-off to the external push provider, distinct from the provider's
  own delivery time, so the two can be attributed independently.
