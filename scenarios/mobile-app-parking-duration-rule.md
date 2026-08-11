---
feature_id: FEAT-072
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Stopped-Vehicle/Parking-Duration Rules

Covers the homeowner-facing side of FEAT-072: alerting when a vehicle remains stopped/parked in
a configured area longer than a threshold.

## Scenario: Unfamiliar car parked in the driveway past the threshold

**Scenario ID:** SCN-255
**Feature ID:** FEAT-072

**Persona:** Marcus, who wants to know if a car sits in his driveway for an unusually long time
(e.g. someone left it there, or a stranger is casing the house).

1. Marcus configures a parking-duration rule on his driveway zone with a 30-minute threshold.
2. An unfamiliar car pulls in and stays parked continuously.
3. At the 30-minute mark, Marcus gets a "Vehicle parked" alert with the elapsed duration shown,
   distinct from the original arrival alert he already got when it first pulled in.

**What the user expects:** he gets a second, distinct signal specifically about the vehicle
overstaying, not just the original "a car arrived" notification repeated.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure a parking/stopped-duration threshold on a
  vehicle-class rule, and shall present a resulting alert as a distinct "vehicle parked/stopped"
  event with the elapsed duration, separate from the original arrival alert.
- **[camera-firmware]** The camera shall track a vehicle's continuous stopped duration within a
  zone and raise the parking-duration event only once that duration exceeds the configured
  threshold, without duplicating the entry alert already raised on arrival.

## Scenario: Car repositions slightly but is still the same stopped event

**Scenario ID:** SCN-256
**Feature ID:** FEAT-072

**Persona:** Marcus, whose parked car's driver opens the door, shifts position slightly to grab
something, and re-parks in essentially the same spot — all within the driveway zone.

1. The vehicle's tracked position shifts slightly (a few feet) but never actually leaves the
   zone or resumes real driving motion.
2. The camera treats this as the same continuous stopped event rather than resetting the
   duration timer to zero because of the minor repositioning.
3. The parking-duration alert still fires at the correct total elapsed time, unaffected by the
   minor shuffle.

**What the user expects:** small in-place movement (a door opening, someone getting back in and
adjusting position) doesn't reset the clock on what's clearly still the same parked vehicle.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall treat minor positional movement of a stopped vehicle
  within the same zone (below a reasonable displacement/motion threshold) as continuation of
  the same stopped event, not a reset, so the duration timer reflects genuine total parked time.
