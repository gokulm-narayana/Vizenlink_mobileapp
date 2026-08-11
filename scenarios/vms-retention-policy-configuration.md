---
feature_id: FEAT-037
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Retention Policy Configuration

Covers the fleet-operator-facing side of FEAT-037: a full retention-policy engine spanning
camera, stream, event severity, and storage destination — not a single global duration.

## Scenario: Configuring per-stream retention (high-res vs. low-res)

**Scenario ID:** SCN-129
**Feature ID:** FEAT-037

**Persona:** Marcus wants to keep low-resolution continuous footage for 30 days but only keep
high-resolution footage for 7 days, to balance storage cost against evidentiary detail.

1. Marcus opens the site's retention policy settings and finds separate retention controls for
   the high-res and low-res streams.
2. He sets 7 days for high-res and 30 days for low-res, and applies the policy.
3. The VMS confirms the split policy and shows, per stream, the resulting estimated storage
   usage.

**What the user expects:** he isn't forced into one retention number for everything when the
two streams serve very different purposes.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS retention policy engine shall support independently configurable retention
  durations per stream (e.g. high-resolution vs. low-resolution).
- **[vms]** The VMS shall show estimated storage usage resulting from a retention policy,
  per stream, at configuration time.

## Scenario: Configuring retention by event severity

**Scenario ID:** SCN-130
**Feature ID:** FEAT-037

**Persona:** Priya wants to keep low-priority motion events for only a few days but keep
high-severity events (e.g. line-crossing, loitering) for much longer.

1. Priya opens the retention policy's event-severity tier settings.
2. She sets a short retention window for low-severity events and a long one for high-severity
   events.
3. The VMS applies the tiered policy going forward and confirms which severity tiers exist and
   their current durations.

**What the user expects:** the system doesn't waste storage on routine motion at the same rate
it keeps the events that actually matter for investigation.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS retention policy engine shall support independently configurable retention
  durations per event-severity tier.
- **[vms]** The VMS shall clearly list the currently configured severity tiers and their
  retention durations in one place, not scattered across per-camera settings.

## Scenario: Configuring retention by storage destination

**Scenario ID:** SCN-131
**Feature ID:** FEAT-037

**Persona:** Marcus keeps footage locally on the NVR for 14 days but wants events backed up to
the cloud (see FEAT-043) to be retained for a full year.

1. Marcus opens the retention policy's storage-destination settings and sets a 14-day duration
   for local NVR storage and a 365-day duration for cloud-backed events.
2. The VMS confirms each destination's retention independently.
3. When local retention would delete footage that the policy says should still exist in the
   cloud copy, the VMS deletes only the local copy, leaving the cloud copy intact per its own
   duration.

**What the user expects:** local and cloud retention are genuinely independent knobs, not one
setting silently governing both.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS retention policy engine shall support independently configurable retention
  durations per storage destination (local NVR vs. cloud).
- **[vms]** The VMS shall delete only the expired destination's copy of a recording when
  retention durations differ across destinations, leaving other destinations' copies intact per
  their own policy.

## Scenario: Retention change conflicts with an in-progress export or lock

**Scenario ID:** SCN-132
**Feature ID:** FEAT-037

**Persona:** Marcus shortens the retention duration for a camera while an operator is actively
exporting a clip from footage that would now fall outside the new window, and while another
clip on that camera is locked as evidence.

1. Marcus applies a shorter retention duration.
2. The VMS does not delete footage currently referenced by an in-progress export, and does not
   delete any footage that is locked/protected, regardless of the new duration.
3. The VMS surfaces a summary of what the new policy would otherwise have deleted but didn't,
   due to these exceptions, so Marcus isn't left guessing why storage didn't shrink as expected.

**What the user expects:** tightening retention never breaks an export already in flight or
silently deletes protected evidence, and he's told when that safeguard kicked in.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall exclude footage referenced by an in-progress export and any
  locked/protected recording from deletion when a retention policy change would otherwise remove
  it.
- **[vms]** The VMS shall report, after applying a tightened retention policy, which recordings
  were exempted from deletion and why (in-progress export, lock).
