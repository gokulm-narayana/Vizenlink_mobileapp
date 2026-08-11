---
feature_id: FEAT-089
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md]
---

# Scenario: Mobile App — Prominent "Online But Unusable" Health Display

Covers the homeowner-facing side of FEAT-089: making sure a connected-but-degraded camera
(blocked view, unusable image, storage failure) is shown prominently as unusable, not just
generically "online."

## Scenario: Blocked-view camera still shows as functionally unusable, not just "online"

**Scenario ID:** SCN-336
**Feature ID:** FEAT-089

**Persona:** Marcus's camera has its view blocked (per FEAT-083), but network connectivity is
perfectly fine.

1. On the home screen, Marcus's camera does NOT show a plain green "Online" badge, even though
   it's technically connected — it shows a prominent amber/red "Needs Attention" badge with a
   short reason ("View Blocked"), placed exactly where he'd normally see the connectivity status.
2. The camera doesn't get buried among genuinely fine cameras in a multi-camera household view —
   the degraded one is sorted or highlighted to the top.
3. Only once the underlying condition clears does the badge return to plain "Online."

**What the user expects:** "connected" and "actually working" are not conflated — a camera that's
reachable but functionally useless is called out just as prominently as one that's fully
offline, not hidden behind a falsely reassuring green dot.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall never display a plain "Online" status for a camera that has any
  active functional-degradation condition (blocked view, unusable image, night-vision-unusable,
  storage failure, etc.) — it shall show a distinct "needs attention" state with the specific
  reason instead.
- **[mobile-app]** In a multi-camera home view, the app shall visually prioritize (e.g. sort to
  top, distinct color) cameras with an active degradation condition over fully-healthy cameras.

## Scenario: Two simultaneous degradation conditions on the same camera

**Scenario ID:** SCN-337
**Feature ID:** FEAT-089

**Persona:** Marcus's camera develops a storage failure at the same time its lens has also
become dirty enough to trigger a haze/fogging alert.

1. Marcus's home screen shows a single "Needs Attention" badge for that camera (not two
   competing badges), but tapping in shows both active conditions listed clearly rather than
   only the most recent one overwriting the other.
2. The app doesn't silently drop the older condition when the newer one arrives — both remain
   visible until each individually clears.
3. If he resolves one (cleans the lens) but the storage issue persists, the badge stays in
   "needs attention" state, reflecting the still-open condition rather than clearing early.

**What the user expects:** multiple simultaneous problems on one camera are all visible, and the
camera isn't shown as "fine" again until every open condition has actually cleared.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show a single "needs attention" summary badge per camera even
  when multiple degradation conditions are active simultaneously, while listing every open
  condition individually in the camera's detail view.
- **[mobile-app]** The app shall only return a camera's status to "Online" once all of its
  currently open degradation conditions have individually cleared, not upon the most recent one
  clearing.
