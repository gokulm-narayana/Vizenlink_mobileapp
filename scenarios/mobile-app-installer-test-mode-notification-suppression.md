---
feature_id: FEAT-166
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Installer Test Mode with Notification Suppression

Covers FEAT-166: during commissioning, the installer can generate test detections and walk
zones/lines while all end-user notifications (push, buzzer, cloud alert) are suppressed, until
commissioning is explicitly completed.

## Scenario: Installer tests zones/detections with notifications suppressed

**Scenario ID:** SCN-593
**Feature ID:** FEAT-166

**Persona:** Diego, verifying a new camera's motion zones and person-detection are configured
correctly by walking through the property.

1. Diego enters "Test Mode" from the commissioning flow before walking the property.
2. While in test mode, he deliberately walks through each configured zone/line to trigger
   detections and confirm the camera reacts as expected.
3. Throughout this, no push notifications, buzzer sounds, or cloud alerts reach the homeowner —
   the app clearly shows "Test Mode: notifications suppressed" the whole time so Diego knows
   he's not spamming the customer.
4. Diego reviews the detection events generated during the test directly within the
   commissioning flow, confirming zones/lines are working, without the homeowner ever being
   bothered.

**What the user expects:** verifying detection actually works doesn't mean flooding the
homeowner's phone with test alerts.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide an installer Test Mode that suppresses end-user
  notifications (push, buzzer, cloud alert) while active, and visibly indicate that
  suppression is in effect.
- **[mobile-app]** The app shall let the installer view test-generated detection events within
  the commissioning flow itself.
- **[camera-firmware]** The camera shall withhold end-user-facing notification delivery for
  detections generated while Test Mode is active, while still processing/logging the detection
  for the installer's review.

## Scenario: Test Mode has a safeguard against being left on indefinitely

**Scenario ID:** SCN-594
**Feature ID:** FEAT-166

**Persona:** Diego, who gets pulled away and forgets to explicitly exit Test Mode before
leaving the site.

1. Diego finishes his walk-test but leaves without tapping "Complete Test Mode."
2. After a bounded maximum duration (e.g. a few hours), the app/camera automatically exits Test
   Mode on its own, resuming normal end-user notifications, rather than leaving suppression
   active indefinitely.
3. If a genuine event happens during this forgotten test-mode window, it's still recorded, but
   the homeowner isn't left permanently unprotected because an installer forgot a step.

**What the user expects:** a real safety-relevant behavior like alerting doesn't stay silently
disabled because of a single missed tap — there's a hard ceiling on how long suppression can
last.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall automatically exit Test Mode and resume normal
  end-user notification delivery after a bounded maximum duration, even if the installer never
  explicitly ends it.
- **[mobile-app]** The app shall warn the installer if Test Mode has been active for an
  extended period, prompting them to complete or explicitly extend it.

## Scenario: Completing commissioning explicitly ends Test Mode and confirms notifications are live

**Scenario ID:** SCN-595
**Feature ID:** FEAT-166

**Persona:** Diego, finishing the full commissioning checklist including the test-mode walk.

1. Diego taps "Complete Installation" at the end of the checklist.
2. Test Mode ends immediately as part of that action, and the app runs one final confirmation
   step showing that end-user notifications are now active (e.g. a clear on-screen
   confirmation that suppression has ended).
3. The homeowner's account reflects that the camera is now in normal operating mode, not test
   mode.

**What the user expects:** finishing the install visit leaves the customer with working,
confirmed-active protection — not a silent gap where someone has to remember to "turn alerts
back on."

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall exit Test Mode automatically when the installer marks
  commissioning complete, and shall confirm to the installer that end-user notifications are
  active before the flow ends.
</content>
