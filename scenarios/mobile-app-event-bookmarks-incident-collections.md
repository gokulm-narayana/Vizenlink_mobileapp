---
feature_id: FEAT-127
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Event Bookmarks & Multi-Clip Incident Collections

Covers the mobile-app side of FEAT-127: bookmarking individual events and grouping several
related clips/events, possibly across cameras, into one incident collection.

## Scenario: Bookmarking an event for later reference

**Scenario ID:** SCN-477
**Feature ID:** FEAT-127

**Persona:** Priya wants to keep track of an event (a delivery she wants to remember later)
without it getting lost among dozens of routine events.

1. Priya taps a bookmark control on the event's detail screen.
2. The event now appears in a dedicated "Bookmarked" list, separate from the ordinary
   chronological event list, and remains there indefinitely regardless of the platform's
   normal event-retention window (subject to underlying clip retention/export policy).
3. Un-bookmarking removes it from that list without deleting the underlying event itself.

**What the user expects:** bookmarking is a lightweight, reversible way to keep a specific
event easy to find again, distinct from Save/Export.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user bookmark/unbookmark an individual event from its
  detail screen, and shall provide a dedicated view listing all bookmarked events.
- **[mobile-app]** Un-bookmarking an event shall remove it from the bookmarked view without
  deleting or otherwise altering the underlying event record.

## Scenario: Grouping several related clips across cameras into one incident collection

**Scenario ID:** SCN-478
**Feature ID:** FEAT-127

**Persona:** Priya's front-door and driveway cameras both captured different moments of the
same suspicious visit, and she wants to keep them together as one story.

1. From an event's detail screen, Priya adds it to a new or existing named collection (e.g.
   "Suspicious visitor — Tuesday night").
2. She repeats this for the second camera's event, adding it to the same collection.
3. Opening the collection shows both events together, each still clearly attributed to its own
   camera and timestamp, in one combined view rather than requiring her to hold both events'
   context in her head separately.

**What the user expects:** she can assemble a coherent multi-camera story out of separate
events without the app forcing her to treat each camera's footage in total isolation.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user create a named incident collection and add events
  from any of their cameras to it, regardless of which camera captured each event.
- **[mobile-app]** A collection's view shall display every included event with its own camera
  and timestamp attribution, ordered coherently (e.g. chronologically) across cameras.

## Scenario: Removing an event from a collection, and deleting a collection entirely

**Scenario ID:** SCN-479
**Feature ID:** FEAT-127

**Persona:** Priya later decides one of the two events in her collection wasn't actually
related, and separately, weeks later, decides the whole collection is no longer needed.

1. Priya removes the unrelated event from the collection; the event itself remains fully intact
   and viewable in the ordinary event list/timeline — only its membership in that collection is
   removed.
2. Later, Priya deletes the entire collection; the events that were in it are unaffected and
   remain in the event list/timeline exactly as before — only the grouping itself is gone.

**What the user expects:** collections are purely an organizational overlay — removing an event
from one, or deleting one entirely, never deletes the underlying recorded events themselves.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Removing an event from a collection, or deleting a collection outright, shall
  never delete or otherwise affect the underlying event records — only the grouping/membership
  is removed.
