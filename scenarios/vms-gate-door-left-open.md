---
feature_id: FEAT-076
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Gate/Door-Left-Open Detection

Covers the fleet-operator side of FEAT-076: monitoring a community gate with both an integrated
physical sensor and visual confirmation, and resolving a disagreement between the two.

## Scenario: Operator monitors a community gate with sensor + visual confirmation

**Scenario ID:** SCN-270
**Feature ID:** FEAT-076

**Persona:** Dana, managing a community's vehicle gate that has both a camera view and an
integrated physical open/closed sensor.

1. Dana configures the gate-left-open rule to use the integrated sensor as the primary signal,
   with the camera's visual state as corroborating evidence shown alongside any alert.
2. The gate is left open past the threshold; the physical sensor reports "open," and the alert
   fires with the camera's snapshot attached for visual confirmation.
3. Dana can see both the sensor reading and the visual evidence together in the alert, giving
   her confidence it's a real event, not a sensor glitch.

**What the user expects:** where a physical sensor exists, she gets its reliability plus visual
proof in the same alert, rather than having to trust one signal blindly.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display both the integrated sensor's reported state and the camera's
  visual snapshot together on a gate/door-left-open alert, when a physical sensor is available
  for that gate/door.
- **[camera-firmware]** The camera shall report both its own visual open/closed determination
  and, where an integrated physical sensor is present, that sensor's reading, tagging which
  source (or both) triggered the alert.

## Scenario: Sensor and visual state disagree

**Scenario ID:** SCN-271
**Feature ID:** FEAT-076

**Persona:** Dana, reviewing an alert where the physical sensor reports the gate as open but the
camera's visual state reads it as closed (e.g. the sensor is stuck or miscalibrated).

1. The gate-left-open rule fires based on the sensor's "open" reading, but the alert's attached
   snapshot clearly shows the gate closed.
2. The VMS surfaces this disagreement explicitly in the alert (e.g. "Sensor: Open / Visual:
   Closed — mismatch"), rather than silently trusting one source and hiding the conflict.
3. Dana recognizes the sensor is likely faulty and flags it for maintenance, while trusting the
   visual evidence for this particular event.

**What the user expects:** when the two signals disagree, she's told about the conflict plainly
so she can judge which to trust, rather than the system picking one silently and leaving her
unaware there was ever a discrepancy.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect and explicitly flag a mismatch between a gate/door's physical
  sensor reading and its camera-derived visual state on any alert where both are available,
  rather than presenting only one source as if it were undisputed.
