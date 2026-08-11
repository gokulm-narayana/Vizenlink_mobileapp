---
feature_id: FEAT-077
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Wrong-Way Vehicle Detection

Covers FEAT-077: alerting on vehicle movement against the expected direction on configured
internal roads/ramps. Community/operator-scale rule per the guidance on advanced rule types.

## Scenario: Vehicle enters an exit-only ramp

**Scenario ID:** SCN-272
**Feature ID:** FEAT-077

**Persona:** Dana, managing a parking garage with a one-way exit ramp that should never see
vehicles entering against the flow.

1. Dana configures a wrong-way rule on the exit ramp's directional line, with "out" set as the
   only expected direction.
2. A vehicle drives up the ramp in the wrong direction (entering rather than exiting).
3. The rule fires immediately, and Dana's VMS event list shows a "Wrong-way vehicle" alert with
   the direction of travel and a snapshot.

**What the user expects:** she's alerted the moment a vehicle goes against the ramp's intended
flow, which is both a safety and a security concern worth catching immediately.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator configure a wrong-way rule on a directional line,
  specifying the single expected direction of travel, and shall label a resulting alert
  distinctly as "Wrong-way vehicle."
- **[camera-firmware]** The camera shall determine a tracked vehicle's direction of travel
  across a calibrated line and raise a wrong-way event when that direction opposes the rule's
  configured expected direction.

## Scenario: Vehicle briefly reverses to correct a wrong turn

**Scenario ID:** SCN-273
**Feature ID:** FEAT-077

**Persona:** Dana, whose ramp camera occasionally sees a driver realize they entered the wrong
ramp, and immediately reverse back out before actually driving further in.

1. A vehicle starts to enter against the expected direction, but reverses and exits again within
   a few seconds, never actually completing a wrong-way traversal past the line.
2. The camera's direction determination is based on the vehicle's net displacement across the
   line over a short evaluation window, not the instant it first noses across — so a
   corrected, reversed approach doesn't count as a completed wrong-way crossing.
3. No wrong-way alert fires for this self-corrected near-miss.

**What the user expects:** the system distinguishes a driver's momentary mistake, corrected
before it becomes a real wrong-way trip, from an actual sustained wrong-way traversal — she
isn't alerted on every brief hesitation at a ramp entrance.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall determine wrong-way direction based on a tracked
  vehicle's net crossing/displacement over a short evaluation window rather than its
  instantaneous heading at first contact with the line, so a vehicle that reverses out before
  completing the crossing does not trigger a false wrong-way event.
