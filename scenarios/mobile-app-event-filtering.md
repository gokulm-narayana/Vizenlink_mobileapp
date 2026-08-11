---
feature_id: FEAT-119
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Multi-Dimensional Event Filtering

Covers the mobile-app side of FEAT-119: filtering the event list/timeline by camera, type,
object class, zone, severity, review status, and date/time.

## Scenario: Narrowing the event list with several filters at once

**Scenario ID:** SCN-437
**Feature ID:** FEAT-119

**Persona:** Priya wants to find every unreviewed "person" detection in her backyard zone from
the last week.

1. Priya opens the event list's filter panel and selects: camera = Backyard, object class =
   Person, zone = Backyard Zone, review status = Unreviewed, date range = last 7 days.
2. The event list updates to show only events matching all selected filters at once, not just
   the last one applied.
3. Active filters are visibly summarized (e.g. as removable chips) so Priya can see exactly
   what's currently narrowing the list.
4. Priya removes one filter (e.g. the zone) with a single tap, and the list widens accordingly.

**What the user expects:** she can combine several filter dimensions together and clearly see
— and adjust — what's currently applied.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The event list shall support filtering by any combination of camera, event
  type, object class, zone, severity, review status, and date/time range, applying all active
  filters together (logical AND).
- **[mobile-app]** Active filters shall be visibly summarized (e.g. as removable chips/tags),
  and removing one shall update the list immediately without clearing the others.

## Scenario: A filter combination matches no events

**Scenario ID:** SCN-438
**Feature ID:** FEAT-119

**Persona:** Priya applies filters (e.g. object class = Vehicle, zone = Backyard) that happen
to match nothing, since no vehicle event was ever flagged in that zone.

1. The event list shows a clear "no events match these filters" empty state, distinct from a
   loading state or an error.
2. The active filter chips remain visible and editable so Priya can immediately adjust rather
   than having to reopen the filter panel from scratch.

**What the user expects:** an empty result is stated plainly as "nothing matches," not
mistakable for a bug or a stuck loading screen.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The event list shall display an explicit empty-result state when the active
  filter combination matches zero events, distinct from a loading or error state.
- **[mobile-app]** Active filter chips shall remain visible and editable in the empty-result
  state, so the user can adjust filters without re-opening the filter panel.

## Scenario: Saving a frequently-used filter combination

**Scenario ID:** SCN-439
**Feature ID:** FEAT-119

**Persona:** Priya regularly checks "unreviewed Person events at the front door" and wants to
avoid re-selecting the same five filters every time.

1. After setting up her usual filter combination, Priya saves it as a named preset.
2. Later, she selects that saved preset from a shortcut list and every underlying filter is
   reapplied at once.
3. She can update or delete a saved preset without it affecting the event list's currently
   active filters until she chooses to apply it.

**What the user expects:** a filter combination she uses often becomes a one-tap shortcut
instead of repeated manual setup.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user save a named filter-combination preset and reapply
  it in one action.
- **[mobile-app]** Saved presets shall be editable/deletable independently of the event list's
  currently active filter state.
