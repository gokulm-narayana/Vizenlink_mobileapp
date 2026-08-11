---
feature_id: FEAT-065
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Zone & Line Rule Authoring

Covers the fleet-operator side of FEAT-065: drawing polygon zones and directional lines across a
multi-camera deployment from the VMS, including reusing a zone shape across similar cameras.

## Scenario: Operator draws zones across multiple cameras from the VMS

**Scenario ID:** SCN-227
**Feature ID:** FEAT-065

**Persona:** Dana, an operator setting up rules for a newly-installed community camera covering
a parking area.

1. Dana opens the camera's rule-authoring view in the VMS and draws a polygon zone over the
   parking area directly on the camera's live view, the same tap-to-place-vertex interaction as
   any single-camera setup.
2. She names it "Visitor Parking" and saves; the VMS confirms the zone is attached to this
   camera.
3. Dana repeats this for each of the 6 cameras covering different parking areas on the site,
   each with its own independently-named zone.

**What the user expects:** authoring a zone from the VMS feels the same regardless of which of
her many cameras she's working on, and each camera's zones stay clearly scoped to that camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an authorized operator draw a named polygon zone or directional
  line on any managed camera's live/snapshot view, using the same drawing interaction
  regardless of how many cameras the site has.
- **[camera-firmware]** The camera shall store its zone/line definitions independently per
  camera, so an operator managing many cameras never has one camera's zone accidentally apply
  to another.

## Scenario: Operator copies a zone template to a similar camera

**Scenario ID:** SCN-228
**Feature ID:** FEAT-065

**Persona:** Dana, who has just finished drawing a well-tuned "Sidewalk" zone on one camera and
has four more cameras with a near-identical mounting angle covering similar sidewalks.

1. Dana selects the finished zone and chooses "Copy to another camera."
2. The VMS applies the same relative zone shape to the target camera's view and shows it
   overlaid for Dana to review before confirming.
3. Because the new camera's mounting angle differs slightly, Dana nudges a couple of vertices
   to fit, then saves it as a new, independent zone on that camera.

**What the user expects:** she shouldn't have to re-draw a nearly-identical shape from scratch
on every similar camera — copying and adjusting is much faster, while each camera still ends up
with its own independently-editable zone.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator copy an existing zone/line definition to another
  managed camera as a starting point, presenting it for review/adjustment before it is saved as
  that camera's own independent definition.

## Scenario: Editing a zone that multiple rules already reference

**Scenario ID:** SCN-229
**Feature ID:** FEAT-065

**Persona:** Dana, needing to widen the "Loading Dock" zone slightly after noticing it misses
part of the actual dock area — a zone already used by two separate rules (an after-hours rule
and a dwell-time rule).

1. Dana opens the zone for editing and adjusts its boundary.
2. Before saving, the VMS tells her this zone is used by two existing rules and that the change
   will affect both, rather than silently applying the edit with no warning.
3. Dana confirms, and both rules immediately evaluate against the updated boundary going
   forward.

**What the user expects:** she isn't surprised later by a rule behaving differently because a
shared zone changed underneath it without her being told at edit time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall warn the operator, before saving an edit to a zone/line, when that
  zone/line is referenced by one or more existing rules, and shall name which rules are
  affected.
- **[camera-firmware]** The camera shall apply an edited zone/line definition to every rule that
  references it immediately upon the edit taking effect, with no rule left evaluating a stale
  copy of the old shape.
