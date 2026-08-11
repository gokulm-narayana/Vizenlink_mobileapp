---
feature_id: FEAT-050
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — NVR/VMS-Side Storage Capacity Estimation

Covers FEAT-050: the VMS/NVR estimating and displaying aggregate remaining-recording-time
across all cameras' allocated storage.

## Scenario: Operator views aggregate remaining recording time across the fleet

**Scenario ID:** SCN-172
**Feature ID:** FEAT-050

**Persona:** Marcus manages a 20-camera community site and wants a single-glance answer to "how
much longer can we keep recording at this rate before we run out of space."

1. Marcus opens the site's storage overview in the VMS.
2. The VMS shows an aggregate estimate (e.g. "approximately 18 days remaining across all
   cameras") based on total free NVR storage and the combined current bitrate of all recording
   cameras.
3. The estimate is clearly labeled as an approximation, since actual usage varies with scene
   activity across cameras.

**What the user expects:** one clear number for planning storage capacity across the whole
site, without having to add up per-camera figures himself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display an aggregate estimated remaining recording duration across all
  recording cameras at a site, computed from total free storage and combined current bitrate.
- **[vms]** The VMS shall present the aggregate estimate as approximate, not as a
  false-precision exact figure.

## Scenario: Per-camera estimates differ due to different settings

**Scenario ID:** SCN-173
**Feature ID:** FEAT-050

**Persona:** Priya notices the aggregate estimate alone doesn't tell her which specific cameras
are consuming disproportionate storage.

1. Priya drills into the storage overview's per-camera breakdown.
2. She sees that a couple of cameras with higher bitrate and longer retention settings are
   consuming far more of the shared storage than others.
3. She can adjust an individual camera's retention or quality directly from this breakdown and
   see the aggregate estimate update accordingly.

**What the user expects:** the aggregate number is useful, but she also needs to see which
cameras are actually driving storage consumption so she can act on the right ones.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a per-camera storage-consumption breakdown alongside the
  aggregate remaining-time estimate.
- **[vms]** The VMS shall update the aggregate estimate immediately when a per-camera
  retention/quality setting is changed from the breakdown view.

## Scenario: Adding a new camera changes the aggregate estimate

**Scenario ID:** SCN-174
**Feature ID:** FEAT-050

**Persona:** Marcus adds two new cameras to a site that was already near its comfortable storage
capacity.

1. As soon as the new cameras are enrolled and begin recording, the VMS recalculates the
   aggregate remaining-time estimate to include their expected storage consumption.
2. If the new cameras push the estimate below a low-capacity threshold, the VMS proactively
   flags it at the point of enrollment, not only later when storage actually runs low.
3. Marcus can see the estimate both before finalizing enrollment (a projection) and confirmed
   afterward (based on actual recording).

**What the user expects:** he finds out immediately that adding cameras meaningfully shortens
his storage runway, ideally before he commits to it, not as a surprise days later.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall recalculate the aggregate remaining-recording-time estimate whenever a
  camera is added to or removed from a site's recording pool.
- **[vms]** The VMS shall project the estimated impact of enrolling a new camera on the
  aggregate remaining-time estimate before enrollment is finalized, and shall proactively flag
  the result if it falls below a low-capacity threshold.
