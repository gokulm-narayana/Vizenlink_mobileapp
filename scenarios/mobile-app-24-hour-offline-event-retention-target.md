---
feature_id: FEAT-108
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — 24-Hour Offline Event Retention Target

Covers the homeowner-facing side of FEAT-108: surfacing the engineering target of retaining at
least 24 hours of event metadata during a WAN outage, as a plain spec the user can rely on.

## Scenario: A day-long outage stays comfortably within the 24-hour retention target

**Scenario ID:** SCN-395
**Feature ID:** FEAT-108

**Persona:** Priya's home is without internet for about 18 hours during a regional ISP outage.

1. When connectivity returns, all of the events from that 18-hour window sync in fully, none
   dropped — comfortably within the camera's 24-hour retention target under her typical event
   rate.
2. Priya can find this target stated in the app's help/spec content ("buffers at least 24 hours
   of typical activity offline"), so she isn't surprised her data survived — it's exactly what
   was promised.
3. No dropped-event disclosure appears, since the outage didn't approach the documented limit.

**What the user expects:** an outage within the documented retention window behaves exactly as
promised — nothing lost, matching the stated spec rather than being a lucky coincidence.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall state the camera's offline event-retention target (at least 24
  hours under typical/qualified activity levels) in discoverable help/spec content, consistent
  with FEAT-104's queue-full policy disclosure.
- **[camera-firmware]** The camera shall retain at least 24 hours of event metadata during a WAN
  outage under the defined qualified event-rate test profile, before any eviction becomes
  necessary.

## Scenario: An outage exceeds 24 hours, and Priya understands why some loss occurred

**Scenario ID:** SCN-396
**Feature ID:** FEAT-108

**Persona:** Priya's outage lasts 30 hours, beyond the documented 24-hour target, during an
unusually active period at her house.

1. Once restored, Priya's app discloses (per FEAT-104/106) that some lower-priority events from
   later in the outage were dropped, since the outage exceeded the documented 24-hour target.
2. Because she'd previously seen the stated 24-hour target, this isn't a surprising broken
   promise — it's a known, disclosed limit being reached under an above-target outage duration.
3. The app doesn't claim the target was violated when it was simply exceeded by outage duration
   beyond what was ever promised.

**What the user expects:** when an outage genuinely exceeds the documented retention target, the
resulting loss is explainable and consistent with what she was told to expect, not confusing or
contradictory.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app's dropped-event disclosure (FEAT-106) shall, when applicable, note
  that the outage exceeded the documented 24-hour retention target, so the user can connect the
  loss to the previously-stated limit rather than perceiving it as an unexplained failure.
