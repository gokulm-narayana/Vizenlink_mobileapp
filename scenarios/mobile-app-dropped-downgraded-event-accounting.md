---
feature_id: FEAT-106
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Dropped/Downgraded Event Accounting

Covers the homeowner-facing side of FEAT-106: recording any event that was dropped, downgraded,
or overwritten due to storage/queue pressure, so nothing vanishes without a trace.

## Scenario: Priya sees an accounting entry for an event that was downgraded, not fully dropped

**Scenario ID:** SCN-391
**Feature ID:** FEAT-106

**Persona:** Priya's camera, under storage pressure during an outage, keeps a routine event's
metadata (that it happened, roughly when) but discards its full clip to save space — a
downgrade, not a total loss.

1. Priya's timeline shows this event as a lightweight entry ("Motion detected — clip
   unavailable, storage pressure at the time") rather than either the event vanishing entirely
   or falsely appearing as if a full clip exists.
2. She can still see that something happened and roughly when, even without the visual evidence,
   which is more useful to her than nothing at all.
3. This is visually distinguished from a fully-preserved event so she isn't confused into
   thinking a clip should be there when it isn't.

**What the user expects:** even a partially-lost event still leaves an honest, useful trace
rather than disappearing completely or misleadingly looking whole.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a distinct, lightweight timeline entry for an event
  that was downgraded (metadata retained, clip/snapshot discarded) due to storage pressure,
  visually distinguished from a fully-preserved event.
- **[camera-firmware]** The camera shall retain at minimum an event's metadata (type,
  approximate time) even when forced to discard its associated clip/snapshot under storage
  pressure, rather than dropping the event record entirely.

## Scenario: Priya later asks support "how many events did I actually lose last month?"

**Scenario ID:** SCN-392
**Feature ID:** FEAT-106

**Persona:** Priya, curious after noticing a few gaps in her timeline, wants a clear answer about
total impact over the past month.

1. Priya finds a simple summary (e.g. in an account/history section) showing how many events
   were fully dropped and how many were downgraded over the past month, tied to the specific
   outage windows that caused them.
2. This gives her a concrete, honest answer rather than her having to manually count gaps in her
   timeline herself.
3. If the count is zero for a given period (no outages, or none severe enough to cause loss),
   the summary says so plainly rather than being silent/ambiguous about whether it checked.

**What the user expects:** she can get a clear, honest total picture of what she actually lost
over time, not just piecemeal per-event disclosures she'd have to tally up herself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a summary view of total dropped and downgraded events
  over a selectable period, tied to the outage windows that caused them, including an explicit
  zero-loss statement when applicable.
