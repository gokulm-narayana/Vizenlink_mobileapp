---
feature_id: FEAT-102
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: VMS — Resumable Sync Without Duplication

Covers the fleet-operator-facing side of FEAT-102: ensuring interrupted syncs resume cleanly
without generating duplicate events across a multi-camera fleet's shared event stream.

## Scenario: Fleet-wide outage recovery doesn't flood the VMS with duplicate events

**Scenario ID:** SCN-377
**Feature ID:** FEAT-102

**Persona:** Dana's site recovers from a multi-hour outage, and dozens of interrupted uploads
across many cameras all resume around the same time.

1. As the backlog syncs in, Dana's event feed shows exactly one entry per real event across all
   affected cameras — not a wave of duplicates from interrupted-then-resumed uploads piling on
   top of each other.
2. She isn't left needing to manually de-duplicate or clean up the timeline after a mass
   recovery event.
3. She can confirm this by spot-checking a few cameras' timelines against their known event
   counts for that window.

**What the user expects:** a large-scale recovery event, with many simultaneous resumed
uploads, doesn't turn her event feed into a duplicate-ridden mess she has to clean up by hand.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display exactly one entry per real-world event across the fleet event
  feed even during mass-recovery periods with many simultaneously-resuming uploads.
- **[cloud-components]** The cloud sync service shall deduplicate concurrently-resuming uploads
  from many cameras by stable per-event ID, at fleet scale, without requiring per-camera
  serialized processing.

## Scenario: Operator investigates a suspected duplicate and confirms it's actually two distinct events

**Scenario ID:** SCN-378
**Feature ID:** FEAT-102

**Persona:** Dana sees two very similar-looking entries close together for the same camera and
initially suspects a duplication bug.

1. Dana opens both entries and checks their underlying event IDs and precise timestamps in the
   VMS, confirming they're a few seconds apart with distinct IDs — genuinely two separate
   detections, not a duplicate of one.
2. The VMS makes this easy to verify by exposing the stable event ID and precise timestamp on
   each entry, rather than requiring her to just trust the UI at face value.
3. Satisfied it's not a bug, she moves on without filing an unnecessary support ticket.

**What the user expects:** she has enough detail available to distinguish a genuine duplicate
bug from two legitimately close-together real events, without having to take the system's word
for it either way.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose each event's stable event ID and precise occurrence timestamp
  on inspection, so an operator can independently verify whether two similar-looking entries are
  a duplication issue or genuinely distinct events.
