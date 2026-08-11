---
feature_id: FEAT-128
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Daily Security Digest

Covers the mobile-app side of FEAT-128: a daily summary of verified/relevant activity and any
health issues across the user's cameras.

## Scenario: Receiving the daily digest summarizing the day's activity

**Scenario ID:** SCN-482
**Feature ID:** FEAT-128

**Persona:** Priya receives her daily digest notification each morning summarizing the previous
24 hours across all her cameras.

1. The digest summarizes confirmed/relevant activity (e.g. "3 deliveries, 1 unfamiliar visitor
   reviewed") rather than every raw motion trigger, and separately calls out any camera health
   issues from the same period.
2. Tapping the digest opens a summary screen linking directly into each referenced event or
   health issue for further review.
3. The digest arrives at a consistent, predictable time each day.

**What the user expects:** a quick daily catch-up that highlights what actually mattered,
without her having to scroll through the full raw event list herself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall generate and deliver a daily digest summarizing confirmed/
  relevant activity and any camera health issues from the prior 24 hours, at a consistent daily
  time.
- **[mobile-app]** The digest shall link directly to each referenced event or health issue so
  the user can review the underlying detail in one tap.
- **[cloud-components]** The digest content shall be assembled from the account's actual event
  and health-status history for the period, not a client-side approximation.

## Scenario: A quiet day with nothing notable to report

**Scenario ID:** SCN-483
**Feature ID:** FEAT-128

**Persona:** Priya's cameras recorded no confirmed activity worth mentioning and reported no
health issues over the past day.

1. The digest still arrives on schedule but states plainly that there was nothing notable
   (e.g. "All quiet — no notable activity, all cameras healthy") rather than being skipped
   silently or padded with routine motion noise just to have content.

**What the user expects:** the absence of the digest is never something she has to wonder
about — a quiet day still gets a reassuring, honest "nothing to report."

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The daily digest shall be delivered even when there is no notable activity
  or health issue to report, explicitly stating that the day was quiet rather than being
  skipped or padded with routine noise.

## Scenario: Configuring or opting out of the daily digest

**Scenario ID:** SCN-484
**Feature ID:** FEAT-128

**Persona:** Priya wants the digest delivered at a different time, and her partner doesn't want
it at all.

1. Priya changes her preferred digest delivery time in settings; the next digest arrives at the
   new time.
2. Her partner, on their own account, opts out of the digest entirely; they simply stop
   receiving it while Priya continues to receive hers, since digest preferences are per-user
   like other notification preferences (FEAT-120).

**What the user expects:** the digest is a configurable, individually-controllable convenience,
not a fixed broadcast every household member is forced to receive identically.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure their preferred daily digest delivery
  time and opt out of receiving it entirely, independent of other household members' settings.
