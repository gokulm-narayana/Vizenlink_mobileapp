---
feature_id: FEAT-093
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Fleet Health Summary & Maintenance History

Covers FEAT-093: a site-wide summary of all cameras' health status plus a maintenance history
log, for community/office multi-camera deployments. VMS-only — this is an explicitly
fleet/community-scale capability with no single-camera homeowner analog.

## Scenario: Operator opens the site-wide health summary each morning

**Scenario ID:** SCN-344
**Feature ID:** FEAT-093

**Persona:** Dana, an operator responsible for a 60-camera community deployment, starts her day
with a fleet health check.

1. Dana opens the fleet health summary and sees a single roll-up: e.g. "54 Healthy, 4 Needs
   Attention, 2 Offline," rather than needing to manually scan every camera's tile.
2. She drills into the "Needs Attention" and "Offline" groups directly from the summary, each
   listing the specific camera and specific condition (tamper, image quality, offline duration,
   etc.), pulling from the per-camera health signals FEAT-084 through FEAT-090 established.
3. The summary refreshes live as conditions clear or new ones arise through her shift, so it
   stays trustworthy as an ongoing dashboard, not just a one-time snapshot.

**What the user expects:** a single-glance answer to "is the site healthy today," with a clear
path to drill into whatever isn't, aggregated from the same per-camera signals she'd otherwise
have to check individually.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a site-wide health summary rolling up every camera's current
  health state into counts per category (healthy / needs attention / offline), refreshed live as
  conditions change.
- **[vms]** The VMS shall let an operator drill from any summary count directly into the list of
  specific cameras and specific conditions behind it.

## Scenario: Maintenance history log tracks what was done and when

**Scenario ID:** SCN-345
**Feature ID:** FEAT-093

**Persona:** Dana needs to answer a board member's question: "how many cameras have needed lens
cleaning in the last six months, and were they all resolved?"

1. Dana opens the site's maintenance history log, which lists every maintenance action taken
   across the fleet — camera, condition, action taken, who performed it, and when — not just
   currently-open items.
2. She filters by condition type ("lens cleaning") and date range, and gets a clean list she can
   summarize for the board without manually cross-referencing individual camera histories.
3. The log distinguishes actions that fully resolved the condition from ones where the issue
   recurred afterward, so she can also answer whether the fixes actually held.

**What the user expects:** a durable, queryable record of maintenance work across the whole
site, not just a live status board that forgets history once a condition clears.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall maintain a persistent, site-wide maintenance history log recording
  camera, condition, action taken, performing user, and timestamp for every maintenance action,
  independent of current live health status.
- **[vms]** The VMS shall support filtering the maintenance history by condition type, camera,
  and date range, and shall indicate whether each logged action was later followed by a
  recurrence of the same condition.

## Scenario: Fleet summary during a partial site-wide network outage

**Scenario ID:** SCN-346
**Feature ID:** FEAT-093

**Persona:** Dana's site loses its uplink, taking many cameras offline simultaneously (as in
FEAT-085's site-outage scenario), and she needs the fleet summary to stay meaningful during it.

1. Rather than the summary just showing a large, undifferentiated "48 Offline" count, it notes
   this is a correlated site-wide event (per FEAT-085's grouping) so Dana immediately understands
   the scale is one root cause, not 48 independent camera failures.
2. As the uplink is restored and cameras reconnect individually, the summary's offline count
   ticks down in near-real-time rather than jumping all at once, giving her visibility into
   partial recovery progress.
3. Once fully recovered, the summary returns to its normal healthy baseline, and the whole event
   is retained in maintenance history as a single site-level incident rather than 48 separate
   entries.

**What the user expects:** the fleet summary stays useful and honestly contextualized even
during a major correlated outage, instead of just showing a scary, undifferentiated number.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The fleet health summary shall represent a correlated site-wide outage (per FEAT-085)
  as a single grouped event rather than an undifferentiated count of independently-failed
  cameras.
- **[vms]** The fleet health summary shall update incrementally as individual cameras recover
  from a grouped outage, and shall log the overall event as a single entry in maintenance
  history once fully resolved.
