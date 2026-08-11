---
feature_id: FEAT-065
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Zone & Line Rule Authoring

Covers the homeowner-facing side of FEAT-065: drawing polygon zones and directional lines on
the camera view as the basis for security rules.

## Scenario: Homeowner draws a driveway zone

**Scenario ID:** SCN-224
**Feature ID:** FEAT-065

**Persona:** Priya, a homeowner who wants alerts only when something enters her driveway, not
the whole camera view.

1. Priya opens the camera's rules settings and taps "Draw zone" over a live or recent snapshot
   of the driveway view.
2. She taps out the corners of the driveway area, forming a polygon; the app shows the shape
   overlaid on the image as she goes, and lets her drag a corner to adjust it before saving.
3. She names the zone ("Driveway") and saves it.
4. The zone is now available to attach to a rule; the app confirms the zone was saved
   successfully.

**What the user expects:** drawing the area she cares about is as easy as tapping around it on
the picture of her own driveway — no coordinates, no technical setup.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an authorized user draw a polygon zone directly on a
  snapshot/live view of the camera, by tapping vertices and adjusting them before saving, and
  shall let the user name the zone for later reference.
- **[camera-firmware]** The camera shall store a named polygon zone definition (in
  frame-relative coordinates) that can be referenced by one or more rules.

## Scenario: Homeowner draws a directional line at the gate

**Scenario ID:** SCN-225
**Feature ID:** FEAT-065

**Persona:** Priya, who wants to know specifically when someone walks in through her front gate,
as distinct from just being near it.

1. Priya selects "Draw line" instead of "Draw zone" and taps two points across the gate opening
   on the camera view.
2. The app shows a directional indicator (e.g. an arrow) on the line and lets Priya flip which
   side is "in" vs. "out" before saving.
3. She saves the line as "Front Gate."

**What the user expects:** a line-crossing rule needs a direction, and setting that direction
is as simple as flipping an arrow on the picture, not configuring abstract in/out labels.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an authorized user draw a directional line (two or more
  points) on the camera view, with a control to flip/set which side is considered the "in"
  direction, and shall let the user name the line.
- **[camera-firmware]** The camera shall store a named directional line definition, including
  its direction orientation, referenceable by one or more rules for crossing-based evaluation.

## Scenario: Invalid, self-intersecting zone is rejected before saving

**Scenario ID:** SCN-226
**Feature ID:** FEAT-065

**Persona:** Priya, drawing a zone quickly and accidentally crossing her own polygon's edges
over each other.

1. While tapping out a zone, Priya's last point creates a shape where two edges cross.
2. The app detects the self-intersection and stops her from saving, showing a clear message
   ("This shape crosses itself — adjust it before saving") rather than silently accepting a
   malformed zone.
3. Priya drags the offending point back into a valid position and the app allows the save once
   the shape is valid.

**What the user expects:** the app catches an obviously broken shape before it's saved, rather
than letting her save something that would behave unpredictably later.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall validate a drawn polygon for self-intersection (and any other
  structurally invalid shape) before allowing it to be saved, giving the user a clear,
  actionable message and the chance to correct it in place.
- **[camera-firmware]** The camera shall reject a zone/line definition that fails basic
  geometric validity checks (e.g. self-intersecting polygon, degenerate single-point line)
  rather than accepting and later silently misevaluating it.
