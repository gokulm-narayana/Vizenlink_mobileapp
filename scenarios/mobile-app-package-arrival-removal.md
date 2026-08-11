---
feature_id: FEAT-075
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Package Arrival/Removal Detection

Covers the homeowner-facing side of FEAT-075: candidate detection of a package being placed at
or removed from a suitable entrance view.

## Scenario: Package delivered at the door

**Scenario ID:** SCN-264
**Feature ID:** FEAT-075

**Persona:** Priya, who wants to know as soon as a package is left at her door, separate from
the generic "person detected" alert for the courier.

1. A courier sets a box down on the porch and walks away.
2. Priya gets a "Package detected" alert, distinct from the person-detected alert she also
   received for the courier's approach.
3. Opening the alert, she sees a snapshot clearly showing the package now sitting at the door.

**What the user expects:** the app tells her specifically that something was left behind, not
just that a person came and went — so she knows to go check the door.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall detect a package/object being placed within a suitable
  entrance view — a static object appearing where none was present before, associated with a
  person's visit — and classify it as a candidate "package arrival" event distinct from the
  person-detection event.
- **[mobile-app]** The app shall present a package-arrival alert as its own distinct alert type,
  separate from the person-detected alert for the same visit, with its own snapshot showing the
  package.

## Scenario: Package removed without a prior "arrival" alert reaching the homeowner

**Scenario ID:** SCN-265
**Feature ID:** FEAT-075

**Persona:** Priya, who was away when a package first arrived (e.g. delivered by a courier
during a period the camera missed logging the arrival, or before she set up the rule) and later
sees it get picked up by someone else.

1. Someone removes a package that was sitting at the door, with no corresponding "arrival"
   alert ever having been sent for it.
2. The camera still raises a "package removed" candidate event for the pickup itself, since
   removal detection doesn't require having also detected the same package's arrival.
3. Priya receives the removal alert and can review the clip to see who took it, even without an
   earlier arrival alert for context.

**What the user expects:** a removal is flagged on its own merits — she isn't left uninformed
just because she doesn't have the matching earlier "arrival" notification for the same
package.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall detect a package/object's removal from an entrance
  view (a previously-static object disappearing, associated with a person's presence)
  independently of whether that object's earlier arrival was itself detected/alerted, so a
  removal is never suppressed for lack of a matching prior arrival event.
