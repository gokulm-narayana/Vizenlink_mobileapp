---
feature_id: FEAT-081
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Rule Recalibration After View Change

Covers the homeowner-facing side of FEAT-081: requiring recalibration/confirmation of zone/line
rules once a significant view change is detected, before they're trusted again.

## Scenario: Camera bumped — homeowner prompted to recalibrate before rules resume

**Scenario ID:** SCN-276
**Feature ID:** FEAT-081

**Persona:** Marcus, whose porch camera gets knocked slightly out of position by a delivery box
being set down nearby.

1. The camera detects its view has changed significantly from its saved reference view.
2. Marcus's app shows a prominent notice: his existing zone/line rules are suspended pending
   recalibration, since their drawn shapes no longer reliably correspond to the same real-world
   areas.
3. Marcus opens the rules screen, reviews each affected rule's zone against the new view, and
   either confirms it still looks correct or redraws it.
4. Once every affected rule is confirmed/redrawn, the rules resume normal live evaluation.

**What the user expects:** the app doesn't let a rule keep silently "protecting" the wrong part
of the frame after the camera moves — it stops and makes him look before trusting it again.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall detect a significant change from its saved reference
  view and, upon detecting one, suspend evaluation of every zone/line rule until each is
  explicitly recalibrated or confirmed by an authorized user.
- **[mobile-app]** The app shall prominently notify the user when rules have been suspended due
  to a detected view change, list which rules are affected, and provide a direct path to
  review/redraw/confirm each one before it resumes.

## Scenario: Minor view shift from wind sway isn't mistaken for a significant change

**Scenario ID:** SCN-277
**Feature ID:** FEAT-081

**Persona:** Marcus, whose camera is mounted on a slightly flexible pole that sways a little in
strong wind, shifting the view by a few pixels temporarily.

1. Wind causes the camera's view to shift slightly for a period, then settle back.
2. Because this shift is within the tolerance for normal minor movement (not a genuinely
   different framing), the camera does not treat it as a significant view change and does not
   suspend his rules.
3. Marcus's rules continue evaluating normally throughout, with no unnecessary recalibration
   prompt.

**What the user expects:** he isn't bothered with a recalibration interruption every time the
camera wobbles slightly in the wind — only a real, lasting reframing triggers the safeguard.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall apply a tolerance threshold (and, where relevant, a
  minimum sustained-duration check) to view-change detection so that transient minor movement
  (e.g. wind sway) does not falsely trigger rule suspension, reserving that response for a
  genuinely significant and lasting reframing.
