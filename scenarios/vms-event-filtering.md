---
feature_id: FEAT-119
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Multi-Dimensional Event Filtering

Covers the VMS side of FEAT-119: filtering the event list/timeline across a multi-site,
multi-camera fleet.

## Scenario: Operator filters events fleet-wide by severity and site

**Scenario ID:** SCN-440
**Feature ID:** FEAT-119

**Persona:** Marcus wants to see every high-severity, unreviewed event across all six sites
from the overnight shift.

1. Marcus opens the fleet event list and applies filters for severity = High, review status =
   Unreviewed, date range = last 12 hours, across all sites (no site filter narrows it further).
2. The list returns matching events from every site, each clearly labeled with its site and
   camera, so results aren't ambiguous about origin once mixed together.
3. Marcus then narrows to one specific site to focus his review.

**What the user expects:** filtering works the same way at fleet scale as it does for one
camera, and results always make clear which site/camera each event came from.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The event list shall support filtering by site, camera, event type, object class,
  zone, severity, review status, and date/time range, applied together across the entire
  fleet the operator has access to.
- **[vms]** Every event row in a filtered, multi-site result set shall display its originating
  site and camera clearly, since results are no longer implicitly scoped to a single camera.

## Scenario: A broad filter returns a very large result set

**Scenario ID:** SCN-441
**Feature ID:** FEAT-119

**Persona:** Marcus applies a broad filter (all sites, all cameras, last 30 days, all
severities) that matches thousands of events.

1. The event list loads results in manageable pages rather than attempting to load everything
   at once, with a visible total count and page controls (or infinite scroll with clear
   loading feedback).
2. Marcus can add a narrower filter at any point and the paged results update to reflect the
   new, smaller set without inconsistent leftover results from the prior broad query.

**What the user expects:** an accidentally broad filter doesn't stall or crash the interface —
it degrades gracefully into a browsable, paginated result set.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The event list shall paginate (or incrementally load) large filtered result sets
  rather than attempting to render an unbounded result set at once, showing a total match count.
- **[vms]** Adding or changing a filter on a large result set shall discard stale results from
  the prior query rather than merging old and new pages inconsistently.
