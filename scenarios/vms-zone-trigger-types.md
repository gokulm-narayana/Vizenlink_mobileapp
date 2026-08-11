---
feature_id: FEAT-068
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Zone Entry/Exit/Crossing/Presence Detection

Covers the fleet-operator side of FEAT-068: configuring line-crossing and presence trigger
types across a multi-camera deployment, including a partially-occluded edge case.

## Scenario: Operator sets a line-crossing trigger at a gate

**Scenario ID:** SCN-241
**Feature ID:** FEAT-068

**Persona:** Dana, configuring a rule on a previously-drawn directional line at a community
vehicle gate, wanting an alert only when something actually crosses through, not merely
approaches.

1. Dana creates a rule referencing the gate's directional line and sets its trigger type to
   "Crossing."
2. She saves, and the VMS shows the rule's trigger type in its summary view.
3. A vehicle driving up to the gate and stopping short of it produces no alert; once it
   actually crosses through the line, the rule fires with the correct direction (in/out)
   recorded.

**What the user expects:** the rule reacts specifically to the crossing motion the line was
drawn to detect, not to mere proximity or approach.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator select trigger type "Crossing" for a rule referencing
  a directional line, distinct from zone-based entry/exit/presence trigger types.
- **[camera-firmware]** The camera shall fire a crossing-triggered rule only when a tracked
  object's path actually crosses the defined line, recording which direction it crossed in.

## Scenario: Presence trigger with an object partially occluded at the zone edge

**Scenario ID:** SCN-242
**Feature ID:** FEAT-068

**Persona:** Dana, whose lobby zone presence rule (alert if someone lingers) covers an area
where a support pillar partially blocks the camera's view of one corner.

1. A person stands mostly behind the pillar at the edge of the zone, only partially visible, for
   longer than the dwell threshold.
2. The camera's tracking maintains the person as the same tracked object across the partial
   occlusion (rather than losing and re-acquiring them as a "new" object each time they're
   partly hidden), so the presence timer continues accumulating correctly.
3. The presence rule fires once the real total dwell time is exceeded, not restarted every time
   the object is partially occluded.

**What the user expects:** a brief, partial occlusion at the zone edge doesn't reset the clock
on an otherwise continuous presence — the rule reflects genuine total dwell time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera's short-term tracking shall tolerate brief partial occlusion
  of a tracked object without dropping and re-acquiring it as a new object, so presence-based
  rule timers are not incorrectly reset by momentary occlusion.
- **[vms]** The VMS shall display a presence-rule alert's actual measured dwell duration in its
  detail view, so an operator can sanity-check that occlusion didn't distort the reported time.
