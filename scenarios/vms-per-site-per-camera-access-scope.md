---
feature_id: FEAT-148
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Per-Site and Per-Camera Access Scope

Covers the VMS side of FEAT-148: a role assignment can be scoped to specific sites and, within
a site, to a subset of cameras.

## Scenario: Org admin scopes an operator's role to one site in a multi-site deployment

**Scenario ID:** SCN-531
**Feature ID:** FEAT-148

**Persona:** Farid, Site Owner overseeing three separate retail locations under one VMS
organization account, onboarding a new regional operator.

1. Farid opens user management and creates a Security Operator assignment for the new hire.
2. He scopes the assignment to just one of the three sites (the downtown store), leaving the
   other two sites untouched.
3. The new operator's VMS dashboard shows only the downtown store's cameras and site data —
   the other two sites don't appear in their navigation at all.
4. When Farid later needs the same operator to also help at a second site temporarily, he adds
   that site explicitly to the scope rather than re-creating the whole role.

**What the user expects:** a large multi-site organization can hand out access site-by-site,
not just company-wide.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow a role assignment to be scoped to one or more specific sites
  within a multi-site organization account, rather than granting access to every site by
  default.
- **[vms]** The VMS shall allow a site scope to be edited (sites added/removed) without
  requiring the role assignment to be deleted and recreated.

## Scenario: Within one site, access is further scoped to a subset of cameras

**Scenario ID:** SCN-532
**Feature ID:** FEAT-148

**Persona:** Farid, scoping a contractor's temporary access within the downtown store site,
excluding the back-office camera that covers the safe.

1. Farid assigns a contractor a Support Technician role scoped to the downtown site.
2. Within that site, he further narrows the scope to exclude the back-office/safe camera,
   leaving the contractor access only to the public-area cameras relevant to their diagnostic
   work.
3. The contractor's VMS view never shows the back-office camera, even though they do have
   access to the rest of the site.

**What the user expects:** scoping isn't only site-level — within a site, individual sensitive
cameras can be carved out of an otherwise broad grant.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow a role assignment already scoped to a site to be further
  narrowed to a subset of that site's cameras.
- **[vms]** The VMS shall apply a camera-level exclusion consistently across every feature
  (live view, playback, exports, dashboards) so an excluded camera never surfaces through an
  indirect path.

## Scenario: A camera moves between sites and stale scope doesn't silently carry over

**Scenario ID:** SCN-533
**Feature ID:** FEAT-148

**Persona:** Farid, reorganizing his organization's sites after the downtown store's
inventory-room camera is physically relocated and reassigned to a newly created "Warehouse"
site.

1. Farid reassigns the camera's site association in the VMS from "Downtown Store" to
   "Warehouse."
2. A contractor previously scoped only to "Downtown Store" (not "Warehouse") immediately loses
   access to that camera, since it's no longer part of their granted site.
3. The VMS doesn't require Farid to manually chase down and update every existing role
   assignment that referenced the camera — the effective scope recalculates automatically from
   the camera's new site membership.
4. Farid can confirm, from an access-review screen, exactly who currently has access to the
   relocated camera after the move.

**What the user expects:** reorganizing sites/cameras doesn't leave behind stale, unintended
access — scope always reflects the camera's current site membership.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall recompute effective camera-level access automatically whenever a
  camera's site assignment changes, so scope always reflects current site membership rather
  than a stale snapshot.
- **[vms]** The VMS shall let an admin view, after any site/camera reassignment, exactly which
  users currently have access to a given camera.
</content>
