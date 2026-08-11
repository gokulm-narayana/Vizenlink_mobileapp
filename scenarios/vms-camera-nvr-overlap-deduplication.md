---
feature_id: FEAT-044
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Camera/NVR Overlap Deduplication

Covers FEAT-044: when the same footage/event exists on both a camera's local SD card and the
NVR, defining which is authoritative and avoiding duplicate events presented to the operator.
VMS/NVR-side only — the camera itself has no dedup concept, it just records to both.

## Scenario: The same event recorded on both camera SD and NVR shows once

**Scenario ID:** SCN-152
**Feature ID:** FEAT-044

**Persona:** Marcus reviews the event log for a camera that records both locally (SD) and to
the NVR simultaneously (per FEAT-031/FEAT-032 both being active).

1. A motion event triggers recording on both the camera's SD card and the NVR at the same time.
2. In the VMS's event log, Marcus sees this as a single event entry, not two, even though two
   physical copies of the footage exist.
3. When Marcus opens the event, the VMS plays back from the NVR copy by default (the defined
   authoritative source for sites where both exist), with the SD copy available as a fallback
   if he explicitly asks for it.

**What the user expects:** having both local and NVR recording active for redundancy doesn't
mean he has to sort through duplicate entries for every single event.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall present a single event-log entry for an event recorded to both camera
  SD and NVR simultaneously, rather than duplicate entries per source.
- **[vms]** The VMS shall treat the NVR copy as the authoritative source for playback by default
  when both copies exist, while still allowing the operator to explicitly view the SD copy.

## Scenario: NVR temporarily offline, camera SD becomes the only available copy

**Scenario ID:** SCN-153
**Feature ID:** FEAT-044

**Persona:** Priya's NVR goes offline for a period (network outage, maintenance) while cameras
with local SD keep recording independently.

1. During the outage, events recorded only to camera SD (no NVR copy exists yet) show in the
   VMS as coming from the camera directly, once the VMS can reach the camera again, clearly
   marked as "local-only" rather than silently missing from the timeline.
2. Once the NVR comes back and, where supported, syncs or backfills from camera SD, the VMS
   reconciles the previously local-only events with any newly-arrived NVR copies rather than
   ending up with duplicates after the fact.
3. If reconciliation can't cleanly match an event (e.g. ambiguous timestamps), the VMS flags it
   for the operator to resolve manually rather than guessing and risking a false merge or a
   surviving duplicate.

**What the user expects:** an NVR outage doesn't create a permanent gap or a permanent mess of
duplicate events once things reconnect.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall present events recorded only to camera SD (no NVR copy available) as
  "local-only" in the timeline/event log during an NVR outage, rather than omitting them.
- **[vms]** The VMS shall reconcile local-only events against newly-arrived NVR copies once the
  NVR reconnects, merging matched pairs into a single entry rather than leaving duplicates.
- **[vms]** The VMS shall flag any event it cannot confidently reconcile for manual operator
  resolution, rather than guessing at a merge.

## Scenario: Conflicting timestamps between camera and NVR

**Scenario ID:** SCN-154
**Feature ID:** FEAT-044

**Persona:** Marcus notices an event's camera-reported timestamp and NVR-reported timestamp
differ by several seconds, due to clock drift between the two systems.

1. When the VMS attempts to match a camera-side and NVR-side record of what should be the same
   event, it applies a reasonable time-matching tolerance rather than requiring an exact
   timestamp match.
2. If the discrepancy is within tolerance, the VMS merges them into one event as usual.
3. If the discrepancy is large enough to be suspicious (beyond normal clock drift), the VMS
   treats them as distinct events rather than silently merging two things that might not
   actually be the same occurrence, and surfaces the clock-drift condition itself as a
   noteworthy health signal.

**What the user expects:** minor clock drift doesn't cause duplicate entries, but a real,
larger discrepancy isn't silently papered over either.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall apply a configurable time-matching tolerance when reconciling
  camera-side and NVR-side records of the same event, merging matches within tolerance.
- **[vms]** The VMS shall keep camera-side and NVR-side records as distinct events when their
  timestamp discrepancy exceeds the matching tolerance, and shall surface the underlying
  clock-drift condition as a health signal rather than silently merging.
