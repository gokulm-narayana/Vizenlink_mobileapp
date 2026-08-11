---
feature_id: FEAT-100
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Local Event/Evidence Buffering (During Outage)

Covers the fleet-operator-facing side of FEAT-100: reviewing backfilled events across a
multi-camera site after a WAN outage.

## Scenario: Operator reviews backfilled events after a site-wide outage

**Scenario ID:** SCN-369
**Feature ID:** FEAT-100

**Persona:** Dana, an operator, returns after a two-hour site-wide internet outage to a wave of
backfilled events across many cameras.

1. The VMS's event timeline shows all backfilled events correctly timestamped to when they
   actually occurred across the outage window, merged into each camera's normal timeline rather
   than dumped as a separate unsorted batch.
2. A site-wide banner or summary notes that an outage occurred (start/end time) and that some
   events synced late as a result, giving Dana context for the sudden influx.
3. She reviews the backlog same as any other events, confident the timestamps reflect actual
   occurrence, not delivery order.

**What the user expects:** a large batch of delayed events after a site outage integrates
cleanly into the normal review workflow, correctly ordered by real occurrence time, with clear
context for why they arrived late.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall merge backfilled events into each camera's normal event timeline,
  ordered by actual occurrence time, and shall display a site-level notice summarizing any
  outage window that caused delayed delivery.
- **[cloud-components]** The cloud ingestion pipeline shall preserve a buffered event's original
  occurrence timestamp through to the VMS/app, regardless of how much later it was actually
  synced.

## Scenario: Some cameras at the site had local buffer overflow during the outage, others didn't

**Scenario ID:** SCN-370
**Feature ID:** FEAT-100

**Persona:** Dana's site outage affects 15 cameras, but only the busiest 3 (near a high-traffic
entrance) actually filled their local buffers, while the other 12 preserved everything.

1. The VMS's post-outage summary distinguishes, per camera, whether any events were dropped due
   to buffer capacity — not a single site-wide "some data may be missing" disclaimer applied
   uniformly to all 15 cameras regardless of whether they were actually affected.
2. Dana can immediately identify which 3 cameras need a closer look (e.g. checking whether any
   evictions dropped something important) rather than treating the whole site's backlog as
   equally suspect.
3. This per-camera detail is retained in each camera's history for future reference, not just
   shown transiently.

**What the user expects:** the honesty about buffer overflow is precise per camera, not a
blanket caveat that would make her needlessly distrust the 12 cameras whose data was actually
complete.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall report buffer-overflow/event-drop disclosure on a per-camera basis for
  a shared outage window, not as a single undifferentiated site-wide caveat.
- **[vms]** The VMS shall retain per-camera buffer-overflow disclosure in that camera's
  persistent history, not only as a transient post-outage notice.
