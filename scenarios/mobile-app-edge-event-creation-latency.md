---
feature_id: FEAT-213
status: draft
target_fr_docs: [FR-camera-firmware.md]
---

# Scenario: Mobile App — Edge Event Creation Latency (perceived promptness)

Covers FEAT-213's user-perceptible manifestation: a qualifying detection on the camera should
show up as a created event essentially right away when the user checks the timeline, even
though the underlying target (event record created within 2 seconds at p95) is a backend
measurement, not something the app renders a number for.

## Scenario: Checking the timeline right after something happens

**Scenario ID:** SCN-664
**Feature ID:** FEAT-213

**Persona:** Priya hears her doorbell and immediately opens the app to check who's there.

1. Priya opens the Events timeline for her front-door camera within a few seconds of the
   detection.
2. The corresponding event (e.g. "Person detected") is already there, with a timestamp matching
   when it actually happened — she doesn't have to refresh, wait, or wonder if it's still
   "processing."

**What the user expects:** the app never feels like it's lagging behind reality — by the time
she thinks to check, the event has already been recorded.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall create an event record for a qualifying detection
  within 2 seconds at p95, under validated scene conditions, measured from the moment the
  detection condition is met.
- **[mobile-app]** The app shall reflect a newly created event in the timeline without requiring
  a manual refresh, once the event exists.

## Scenario: The 2-second target is missed under a demanding scene

**Scenario ID:** SCN-665
**Feature ID:** FEAT-213

**Persona:** Priya's camera is processing a scene with unusually heavy activity (e.g. a busy
street), pushing detection processing past the normal latency budget.

1. The event still eventually appears in Priya's timeline with its correct actual-occurrence
   timestamp, just later than the 2-second target — it is not silently dropped or shown with a
   wrong (delayed) timestamp to hide the lag.
2. Priya has no visible indication of the specific delay (this is an internal SLA, not a
   user-facing metric), but she never experiences a missing event because of it.

**What the user expects:** even under load, "slow" degrades to "a bit later than usual," never
to "the event never showed up at all."

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** Under scene conditions where the 2-second p95 target cannot be met, the
  camera shall still create the event record with its correct actual-detection timestamp rather
  than dropping the event or reporting a fabricated on-time timestamp.
