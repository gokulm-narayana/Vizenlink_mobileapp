---
feature_id: FEAT-067
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md]
---

# Scenario: VMS — Rule Scheduling

Covers the fleet-operator side of FEAT-067: weekday/holiday-calendar scheduling across a
multi-camera site, and resolving schedule conflicts between overlapping rules.

## Scenario: Operator applies a weekday/weekend schedule with a holiday calendar

**Scenario ID:** SCN-237
**Feature ID:** FEAT-067

**Persona:** Dana, configuring a community clubhouse's after-hours rule that should behave
differently on weekdays vs. weekends, and also treat public holidays as weekend-like.

1. Dana opens the rule's schedule settings and sets separate active windows for weekdays vs.
   weekends.
2. She attaches a holiday calendar to the rule so that recognized holidays automatically use the
   weekend schedule instead of the weekday one.
3. On the next public holiday (a weekday by the regular calendar), the rule correctly applies
   the weekend schedule without Dana having to manually adjust anything that day.

**What the user expects:** she can set this up once and trust it to handle holidays correctly
going forward, rather than remembering to manually toggle the rule around every holiday.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator configure distinct active schedules per weekday
  group (e.g. weekday vs. weekend) on a single rule, and attach a holiday calendar that
  substitutes a specified schedule on recognized holiday dates.
- **[camera-firmware]** The camera shall evaluate a rule's active schedule using the correct
  weekday-group/holiday-substituted window for the current date, without requiring a client to
  push a schedule update on each holiday.

## Scenario: Conflicting schedules across two overlapping rules on the same zone

**Scenario ID:** SCN-238
**Feature ID:** FEAT-067

**Persona:** Dana, who has an after-hours rule and a separate daytime maintenance-vehicle rule
both referencing the same loading-dock zone, with schedules that turn out to overlap by an hour
due to a recent edit.

1. While editing one of the rules' schedules, the VMS detects that the new window now overlaps
   with another active rule referencing the same zone.
2. The VMS surfaces this as an informational warning (not a hard block, since overlapping rules
   on the same zone are sometimes intentional) naming both rules and the overlapping window.
3. Dana reviews and decides the overlap is fine in this case (both rules should legitimately be
   able to fire independently) and confirms the schedule as-is.

**What the user expects:** the VMS proactively tells her about a schedule overlap she might not
have noticed, but doesn't assume overlap is always a mistake and block her from an
intentional configuration.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect and warn an operator when a rule's schedule change creates a
  time overlap with another rule referencing the same zone/line, naming both affected rules,
  while still allowing the operator to confirm the overlapping configuration if intentional.
- **[camera-firmware]** The camera shall evaluate multiple rules referencing the same zone
  independently and concurrently, each against its own schedule, so an intentional overlap
  produces alerts from both rules rather than one silently suppressing the other.
