---
feature_id: FEAT-078
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Climbing Behavior Detection

Covers FEAT-078: detecting climbing-like behavior within a configured boundary zone, after
pose/trajectory validation. Community/operator-scale rule per the guidance on advanced rule
types.

## Scenario: Person climbing a perimeter fence triggers an alert

**Scenario ID:** SCN-274
**Feature ID:** FEAT-078

**Persona:** Dana, monitoring a community's perimeter fence line for unauthorized entry attempts.

1. Dana configures a climbing-detection rule on a boundary zone that runs along the fence line.
2. A person scales the fence, showing a sustained vertical-motion, hands-and-feet climbing
   posture over several frames.
3. Once the camera's pose/trajectory validation confirms this is genuine climbing motion (not
   just standing near the fence), the rule fires a "Climbing detected" alert with the linked
   clip.

**What the user expects:** she's alerted specifically to an actual perimeter-breach attempt,
with enough validation behind it that she can trust it's not just someone standing nearby.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator configure a climbing-detection rule on a boundary
  zone, and shall label a resulting alert distinctly as "Climbing detected," with its
  validating clip available for review.
- **[camera-firmware]** The camera shall validate a candidate climbing detection against
  pose/trajectory cues (sustained vertical motion, characteristic climbing posture) across
  multiple frames before raising a climbing-triggered event, rather than triggering on mere
  proximity to the boundary.

## Scenario: Person leaning or sitting on the fence is not mistaken for climbing

**Scenario ID:** SCN-275
**Feature ID:** FEAT-078

**Persona:** Dana, whose fence-line camera also sees residents occasionally leaning against or
sitting on the low perimeter wall to chat or rest.

1. A resident leans against the fence for a few minutes, remaining largely stationary.
2. Because the pose/trajectory validation requires sustained vertical climbing motion (not
   static contact with the boundary), leaning or sitting does not trigger a climbing alert.
3. Dana's event list stays free of nuisance climbing alerts from ordinary, non-climbing contact
   with the boundary.

**What the user expects:** the rule reacts to genuine climbing motion, not to any physical
contact with the fence at all — so residents resting against it don't set off a security alert.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall distinguish sustained climbing motion from static or
  non-vertical contact with a boundary (leaning, sitting, brief touching) as part of its
  pose/trajectory validation, so the latter does not raise a climbing-triggered event.
