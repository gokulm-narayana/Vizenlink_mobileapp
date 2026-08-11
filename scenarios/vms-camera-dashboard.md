---
feature_id: FEAT-114
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Camera List/Grid Dashboard with Status Badges

Covers the VMS-operator side of FEAT-114: a fleet-operator's single-screen view across every
site and camera under management.

## Scenario: Operator scans a multi-site fleet for problems

**Scenario ID:** SCN-412
**Feature ID:** FEAT-114

**Persona:** Marcus, a security operator managing 40 cameras across 6 community sites, opens the
VMS dashboard at the start of his shift.

1. The dashboard shows every camera across every site in a grid (or grouped-by-site list),
   each with online, recording, health, and unread-event badges.
2. Marcus can immediately spot the handful of cameras with a non-healthy badge without opening
   each site individually.
3. Cameras are grouped or labeled by site, so Marcus knows at a glance which physical location
   an alerting camera belongs to.

**What the user expects:** a single screen tells him, across the whole fleet, exactly where to
focus first.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS dashboard shall display every camera across every site the operator has
  access to, grouped or labeled by site, each with online, recording, health, and unread-event
  status badges.
- **[vms]** The dashboard shall visually surface non-healthy cameras (offline, storage issue,
  tamper, etc.) so they stand out from healthy ones across a large multi-site grid.
- **[camera-firmware]** Each camera shall report its current health status (storage, tamper,
  connectivity) on query so the VMS dashboard reflects true current state rather than a stale
  cache.

## Scenario: A camera's recording silently stopped

**Scenario ID:** SCN-413
**Feature ID:** FEAT-114

**Persona:** Marcus is scanning the dashboard when a camera that's online and reachable has
actually stopped recording (e.g. storage full, encoder fault).

1. That camera's card shows "Online" but a distinct "Not Recording" badge — the dashboard does
   not conflate "reachable" with "recording," which are different facts.
2. Marcus can tell from the badge alone that this is a recording problem, not a connectivity
   problem, without opening the camera's detail page.

**What the user expects:** online and recording are tracked and shown as separate facts, so a
silent recording failure isn't masked by the camera otherwise looking fine.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The dashboard shall show online/offline status and recording/not-recording status
  as two independent badges per camera, never merging them into a single "camera is fine"
  indicator.
- **[camera-firmware]** The camera shall report its actual recording state (active vs. stopped,
  and why, where known) independently of network reachability, so a reachable-but-not-recording
  camera is distinguishable from both a fully healthy and a fully offline one.

## Scenario: Large fleet requires sorting/searching the grid

**Scenario ID:** SCN-414
**Feature ID:** FEAT-114

**Persona:** Marcus needs to find one specific camera among 40 quickly, rather than scanning
visually.

1. Marcus types part of a camera or site name into a search box above the grid, and the grid
   filters down to matching cameras instantly.
2. Marcus can also sort the grid (e.g. problem cameras first, or alphabetically by site) instead
   of only browsing in a fixed order.

**What the user expects:** the dashboard scales to a large fleet — he's not stuck scrolling and
scanning by eye once there are dozens of cameras.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The dashboard shall provide a search/filter box that narrows the camera grid by
  camera name or site name as the operator types.
- **[vms]** The dashboard shall let the operator sort the grid (e.g. by health status, site, or
  name) rather than only presenting a fixed default order.
