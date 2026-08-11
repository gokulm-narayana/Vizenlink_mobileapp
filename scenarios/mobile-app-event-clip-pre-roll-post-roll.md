---
feature_id: FEAT-036
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Event Clip Pre-Roll/Post-Roll

Covers the homeowner-facing side of FEAT-036: event-triggered clips that include buffer time
before and after the triggering moment, initially 5s pre-roll / 10s post-roll, viewed and
configured through the mobile app.

## Scenario: Reviewing an event clip with default pre-roll/post-roll

**Scenario ID:** SCN-123
**Feature ID:** FEAT-036

**Persona:** Marcus gets a motion alert for his front door camera and opens the clip in the app.

1. Marcus taps the alert notification and the app opens the associated event clip.
2. The clip starts 5 seconds before the detected motion actually began, so Marcus sees what led
   up to the event, not just the moment it was detected.
3. The clip continues 10 seconds past the point activity stopped, so he sees what happened
   right after, not a clip that cuts off abruptly.
4. The app visually marks where the "trigger moment" itself falls within the clip, distinct from
   the pre-roll and post-roll padding.

**What the user expects:** an event clip that shows the full moment in context, not just a bare
snippet starting exactly when the camera decided something happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall play an event clip including its pre-roll and post-roll
  buffers, and shall visually mark the actual trigger moment within the timeline distinct from
  the padding.
- **[camera-firmware]** The camera shall buffer at least 5 seconds of pre-event footage
  continuously so it can be included in a clip once an event actually triggers, and shall
  continue recording at least 10 seconds past the end of triggering activity before closing the
  clip.

## Scenario: Adjusting pre-roll/post-roll duration

**Scenario ID:** SCN-124
**Feature ID:** FEAT-036

**Persona:** Priya finds the default 10-second post-roll cuts off before a delivery person is
fully out of frame, and wants to extend it.

1. Priya opens the event-clip settings and adjusts the post-roll duration upward (within a
   supported range).
2. The app confirms the new value was applied to the camera.
3. Subsequent event clips reflect the new duration; clips already recorded under the old
   setting are not retroactively changed.

**What the user expects:** she can tune how much padding she gets around an event without it
disrupting clips she already has.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user adjust pre-roll and post-roll duration within a
  supported range, confirming the change only once the camera acknowledges it.
- **[camera-firmware]** The camera shall apply an updated pre-roll/post-roll duration to clips
  recorded from that point forward, without altering the padding of clips already recorded.
