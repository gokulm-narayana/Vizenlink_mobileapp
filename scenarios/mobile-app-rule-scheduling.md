---
feature_id: FEAT-067
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md]
---

# Scenario: Mobile App — Rule Scheduling

Covers the homeowner-facing side of FEAT-067: restricting when a rule is active by schedule,
weekday, holiday calendar, or a temporary exception.

## Scenario: Homeowner restricts a driveway rule to overnight hours

**Scenario ID:** SCN-234
**Feature ID:** FEAT-067

**Persona:** Priya, who only wants her driveway-vehicle rule active overnight, since daytime
vehicle activity (her own car, deliveries) is expected and not alert-worthy.

1. Priya opens the driveway rule's schedule settings and sets an active window of 10 PM–6 AM,
   every day.
2. She saves, and the app shows the rule's card in her rule list with a schedule indicator
   (e.g. "Active 10 PM–6 AM").
3. A car pulling in at 2 PM produces no alert; the same car arriving at 11 PM does.

**What the user expects:** she can restrict exactly when a rule is "live" without needing a
separate rule for day vs. night, and can see at a glance from the rule list when each rule is
actually active.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an authorized user set an active time window (start/end
  time, applicable days) on any rule, and shall visibly indicate that schedule on the rule's
  summary/list view.
- **[camera-firmware]** The camera shall evaluate a rule's trigger condition only while the
  current time falls within that rule's configured active schedule, suppressing evaluation
  entirely outside that window.

## Scenario: Temporary exception during a vacation

**Scenario ID:** SCN-235
**Feature ID:** FEAT-067

**Persona:** Priya, going on a week-long vacation and wanting her normally overnight-only
driveway rule to run all day for that week, without permanently changing its regular schedule.

1. Priya opens the rule and adds a temporary exception: "Active all day" for a specific date
   range covering her trip.
2. The app confirms the exception and shows it distinctly from the rule's regular recurring
   schedule (e.g. "Temporary override: Jul 1–Jul 8, All day").
3. During that week, the rule behaves as fully active regardless of time of day.
4. After the date range passes, the rule automatically reverts to its normal overnight-only
   schedule with no action needed from Priya.

**What the user expects:** a one-off change for a trip doesn't require editing (and remembering
to revert) the rule's permanent schedule — it's a temporary layer that expires on its own.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user add a temporary date-range exception to a rule's
  schedule, distinct from and displayed separately from its recurring schedule, without
  requiring the recurring schedule to be edited or restored afterward.
- **[camera-firmware]** The camera shall apply an active temporary schedule exception in place
  of the rule's regular recurring schedule for the duration of the exception, and shall
  automatically resume the regular schedule once the exception's date range has passed.

## Scenario: Detection begins right at a schedule boundary

**Scenario ID:** SCN-236
**Feature ID:** FEAT-067

**Persona:** Priya, whose overnight rule is scheduled 10 PM–6 AM, and a car happens to enter the
driveway at exactly 9:59–10:01 PM, straddling the boundary.

1. The vehicle enters the zone just before the schedule's start and is still present as the
   schedule becomes active.
2. The rule does not fire for the portion of the presence before 10 PM, but does evaluate and
   can fire based on the object's continued presence/behavior once the schedule window opens.
3. Priya isn't confused by a rule that either fires prematurely before its window starts or
   misses an event that's genuinely still ongoing once the window opens.

**What the user expects:** the schedule boundary behaves predictably — nothing before the
window counts, but anything still relevant once the window opens is evaluated normally, without
a dead zone right at the transition.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall re-evaluate an already-tracked object's rule
  conditions at the moment a rule's schedule becomes active, rather than only evaluating newly
  starting detections after the schedule boundary — so an object present at the boundary isn't
  missed.
- **[camera-firmware]** The camera shall not raise a rule-triggered alert for activity that
  occurred entirely before the rule's scheduled window opened, even if the object is still
  present once the window opens and the alert would otherwise seem to originate "late."
