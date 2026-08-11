---
feature_id: FEAT-027
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Buzzer Auto-Stop Safety Timer & Status Query

Covers the homeowner-facing side of FEAT-027 (Buzzer Auto-Stop Safety Timer & Status Query): a
buzzer activation that always self-terminates within a bounded time, a re-trigger that restarts
rather than extends/stacks the countdown, and the ability to check current buzzer status or stop
it immediately.

## Scenario: Re-triggering the buzzer restarts rather than stacks the countdown

**Scenario ID:** SCN-077
**Feature ID:** FEAT-027

**Persona:** Priya activates her camera's buzzer at a persistent stray animal, and it keeps coming
back, so she taps activate again while the buzzer is still sounding from the first trigger.

1. Priya taps the buzzer control while it's already active from an earlier trigger.
2. Rather than the buzzer running for the combined/stacked duration of both activations, it simply
   restarts its bounded countdown from the full duration again.
3. The buzzer still stops entirely once that fresh countdown elapses, never running indefinitely
   no matter how many times she re-triggers it.

**What the user expects:** she never has to worry about accidentally causing the buzzer to run for
an excessively long combined duration just by tapping it more than once.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let the user re-trigger the buzzer while it's already active, and
  shall reflect that this restarts (not extends) the remaining active duration.
- **[camera-firmware]** The camera shall restart its bounded auto-stop countdown from full
  duration on a re-trigger while the buzzer is already active, rather than stacking/extending the
  remaining time, guaranteeing the buzzer always self-terminates within one bounded window from
  its most recent trigger.

## Scenario: Checking buzzer status and stopping it immediately

**Scenario ID:** SCN-078
**Feature ID:** FEAT-027

**Persona:** Priya isn't sure whether the buzzer is currently sounding (e.g. she triggered it from
another device, or a rule triggered it) and wants to check, then stop it early if it's still
going.

1. Priya opens the camera's status view and can see whether the buzzer is currently active,
   without needing to be watching live view.
2. Seeing it's still active, she taps "Stop" and the buzzer silences immediately, rather than
   having to wait out its remaining countdown.
3. The status view updates to show the buzzer as inactive.

**What the user expects:** she can always check and immediately stop the buzzer on demand, whether
or not she was the one who triggered it or knows why it's currently active.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a buzzer status query showing whether the buzzer is
  currently active, independent of live view being open.
- **[mobile-app]** The app shall provide an immediate-stop control for the buzzer, usable
  regardless of whether the current activation was triggered locally, by a rule, or remotely.
- **[camera-firmware]** The camera shall report current buzzer active/inactive status on request,
  and shall immediately silence an active buzzer upon receiving a stop command, overriding any
  remaining auto-stop countdown.
