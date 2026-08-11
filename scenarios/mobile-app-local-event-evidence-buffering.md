---
feature_id: FEAT-100
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Local Event/Evidence Buffering (During Outage)

Covers the homeowner-facing side of FEAT-100: events and clips that happened during an outage
are buffered locally and then delivered once sync resumes, instead of being silently lost.

## Scenario: Priya's home internet is down for an hour; events from that window arrive once it's back

**Scenario ID:** SCN-367
**Feature ID:** FEAT-100

**Persona:** Priya's WAN goes down for about an hour during the day, during which her camera
detects two motion events at the front door.

1. While the WAN is down, Priya gets no push notifications for the two events, since her phone
   can't be reached — but nothing is lost; the camera keeps recording and noting the events
   locally.
2. Once her internet returns, the app fills in the missing events into her timeline, each
   correctly timestamped to when they actually happened (not to when they synced), including
   their snapshots/clips.
3. Priya sees an unobtrusive note in the app (e.g. "2 events synced from an earlier outage")
   so she understands why they appeared all at once rather than being confused.

**What the user expects:** an internet blip at home doesn't mean losing the actual security
events that happened during it — they show up correctly once connectivity is back, clearly
timestamped to when they occurred.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall backfill the user's event timeline with events that occurred
  during a connectivity outage once sync resumes, each correctly timestamped to its actual
  occurrence time rather than its sync/delivery time.
- **[mobile-app]** The app shall indicate, unobtrusively, when a batch of events was delivered
  late due to a resolved outage, so the user understands the delayed appearance.
- **[camera-firmware]** The camera shall buffer event metadata locally during a WAN outage, and
  buffer associated snapshots/clips according to configured storage policy, for later
  synchronization once connectivity resumes.

## Scenario: Outage lasts long enough that the local buffer nears capacity

**Scenario ID:** SCN-368
**Feature ID:** FEAT-100

**Persona:** Priya is away for several days during an extended outage at her house, during which
far more events accumulate than usual.

1. Once the outage resolves and events start backfilling, the app doesn't silently assume every
   single event was preserved — if the camera's buffer reached capacity at some point during the
   outage (per FEAT-104/105's eviction policy), the app tells Priya plainly that some
   lower-priority events from that window were not retained, rather than implying full 100%
   coverage.
2. Higher-severity events (e.g. a person detection) that were preserved thanks to
   severity-based prioritization (FEAT-105) still appear normally.
3. Priya can see, for the outage window specifically, an honest summary of what is and isn't
   available, rather than a timeline that looks complete when it isn't.

**What the user expects:** the app is honest about buffer limits during a long outage — it
doesn't imply everything survived if it didn't, but it does show her what higher-priority events
were protected.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall clearly disclose, for any outage window where the local buffer
  reached capacity, that some lower-priority events were not retained, rather than presenting the
  backfilled timeline as necessarily complete.
- **[camera-firmware]** The camera shall report, alongside a backfilled event batch, whether any
  events were dropped/evicted during that outage window (per its queue-full policy), so this can
  be surfaced to the user honestly.
