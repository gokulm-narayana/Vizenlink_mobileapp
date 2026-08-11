---
feature_id: FEAT-130
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Site/E-Map Camera View

Covers FEAT-130: a visual site map showing each camera's physical location, for
community/office multi-camera deployments.

## Scenario: Operator views the site map with live camera status overlaid

**Scenario ID:** SCN-491
**Feature ID:** FEAT-130

**Persona:** Marcus opens the site map for a community property with a dozen cameras placed
around the grounds.

1. The map shows each camera as an icon positioned at its actual physical location on the site
   layout, with each icon's color/badge reflecting its current status (online/offline/health),
   consistent with the dashboard's status badges (FEAT-114).
2. Marcus can tell at a glance, spatially, which physical area has a camera needing attention,
   which is easier to reason about geographically than a flat list for a large site.

**What the user expects:** the map gives him a physical, spatial understanding of coverage and
status that a list view can't.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall render a site map with each camera positioned at its configured
  physical location, showing the same online/health status indicators used elsewhere in the
  VMS.
- **[vms]** Camera status on the map shall update to reflect current state consistent with the
  dashboard, without requiring a separate manual refresh of the map view.

## Scenario: Clicking a camera icon on the map opens its live view

**Scenario ID:** SCN-492
**Feature ID:** FEAT-130

**Persona:** Marcus notices an unhealthy camera icon on the map and wants to investigate
immediately.

1. Marcus clicks the camera's icon on the map.
2. The VMS deep-links directly into that camera's live view (consistent with FEAT-115's
   deep-link behavior), without requiring him to separately look up which camera that icon
   corresponds to in a list first.

**What the user expects:** the map isn't just a static diagram — it's a real navigation surface
into each camera's live feed.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** Clicking a camera icon on the site map shall deep-link directly to that camera's
  live view, consistent with the VMS's other deep-link entry points.

## Scenario: Administrator uploads a site map and places camera icons

**Scenario ID:** SCN-493
**Feature ID:** FEAT-130

**Persona:** Diane is setting up the map view for a newly onboarded site with no map configured
yet.

1. Diane uploads a floor plan/site layout image and, for each camera at the site, drags its
   icon onto the corresponding physical location on the image.
2. Diane saves the layout; from then on, every operator viewing this site's map sees cameras
   positioned as she placed them.
3. If a camera is added to the site later, it initially appears unplaced (e.g. in an
   "unplaced cameras" tray) until an administrator positions it on the map, rather than being
   silently omitted from the map entirely.

**What the user expects:** setting up the map is a one-time administrative task, and cameras
never fall through the cracks even before someone gets around to placing them.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an administrator upload a site layout image and position each
  camera's icon on it, persisting the layout for all operators viewing that site.
- **[vms]** A camera newly added to a site with an existing map shall appear in an unplaced-
  cameras list until an administrator positions it, rather than being omitted from the map
  view.
