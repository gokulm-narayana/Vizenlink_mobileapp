---
feature_id: FEAT-083
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Camera Tamper Detection (Blocked View & View Movement)

Covers the homeowner-facing side of FEAT-083: the mobile app surfacing a distinct tamper alert
when the camera's view is suddenly blocked/covered, or when the camera has been physically
repositioned.

## Scenario: Sudden view blockage triggers an immediate tamper alert

**Scenario ID:** SCN-309
**Feature ID:** FEAT-083

**Persona:** Marcus, a homeowner whose porch camera view is suddenly covered — someone has
taped over the lens or placed an object directly in front of it.

1. Within moments of the view going dark/obstructed, Marcus gets a push notification labeled
   distinctly as a tamper alert, not a routine motion alert.
2. Opening the app, the alert feed shows "Possible Tamper — View Blocked" with a timestamp and
   a thumbnail of the last usable frame before the blockage, since there's no useful live frame
   to show.
3. The camera's status badge on the home screen also flips to a tamper/attention state, distinct
   from its normal "Recording" state.
4. Marcus can tap through to see the camera is still online and reachable — it hasn't gone
   offline, its view has simply been blocked.

**What the user expects:** a blocked camera is called out immediately and specifically as
possible tampering, not silently treated as "no motion" or lumped in with a generic offline
state.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall push a distinctly-labeled tamper notification (separate from
  motion/detection alerts) when the camera reports a sudden view-blockage condition.
- **[mobile-app]** The app shall show the camera's home-screen status badge in a
  tamper/attention state, visually distinct from both its normal "online/recording" state and a
  fully-offline state.
- **[camera-firmware]** The camera shall detect a sudden, sustained loss of usable image content
  (e.g. near-uniform dark or obstructed frame) and raise a tamper event distinct from a
  connectivity-loss event.

## Scenario: Camera repositioning triggers a distinct "view moved" alert

**Scenario ID:** SCN-310
**Feature ID:** FEAT-083

**Persona:** Marcus's camera is knocked or deliberately turned so it now points at the sky
instead of his driveway.

1. The app sends a tamper notification worded specifically as a view-change ("Camera View May
   Have Moved"), not the same wording used for a blocked-view alert.
2. In the app, the alert includes a side-by-side of the camera's known reference view and its
   current view, so Marcus can visually confirm the framing has actually shifted.
3. Marcus is prompted to either confirm the new position is intentional (e.g. he just
   repositioned it) or flag it as unauthorized movement.
4. If he confirms it's intentional, the app offers to capture a new reference view so future
   comparisons use the corrected framing instead of repeatedly re-alerting.

**What the user expects:** the app tells him specifically that the camera's framing changed —
not just "something's wrong" — and gives him a clear way to accept a deliberate repositioning
so it stops nagging him about it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall label a view-movement tamper alert distinctly from a
  view-blockage tamper alert, and shall display the stored reference view alongside the current
  view for comparison.
- **[mobile-app]** The app shall let the user confirm a detected view change as intentional and
  trigger capture of a new reference view, so the same repositioning is not re-flagged.
- **[camera-firmware]** The camera shall compare its current framing against a stored reference
  view and raise a distinct "view movement" tamper event when the deviation exceeds a
  significant-repositioning threshold, separately from the blocked-view condition.

## Scenario: A brief, incidental blockage clears on its own

**Scenario ID:** SCN-311
**Feature ID:** FEAT-083

**Persona:** Marcus's camera view is briefly blocked by a delivery box left directly in front of
it for a few minutes before the courier moves it.

1. Marcus receives the tamper alert as usual when the blockage starts.
2. A few minutes later, once the box is moved and the view returns to normal, the app updates
   the same alert entry to show it has cleared, rather than leaving it stuck in an active
   "tampered" state indefinitely.
3. The camera's home-screen status badge returns to its normal state automatically once the
   condition clears.
4. The alert history still records both the start and clear time, so Marcus can see how long the
   view was actually blocked if he checks back later.

**What the user expects:** a short-lived, incidental blockage doesn't leave his camera looking
permanently broken in the app — the alert and status resolve themselves once the view is
actually restored, while still keeping a record of what happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall update an active tamper alert to a "cleared" state and restore
  the camera's normal status badge once the camera reports the underlying condition has
  resolved, without requiring user action.
- **[mobile-app]** The app shall retain the start and clear timestamps of a resolved tamper
  event in the camera's alert history.
- **[camera-firmware]** The camera shall re-evaluate its view continuously while a tamper
  condition is active and emit a clear/resolved event as soon as the view returns to a usable,
  unobstructed state matching expected framing.
