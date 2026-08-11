---
feature_id: FEAT-086
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Unusable Image Condition Detection

Covers the fleet-operator-facing side of FEAT-086: surfacing sustained underexposure,
overexposure, or focus loss across a multi-camera deployment.

## Scenario: Operator triages an image-quality alert among many cameras

**Scenario ID:** SCN-326
**Feature ID:** FEAT-086

**Persona:** Dana, an operator responsible for a community's 25 outdoor cameras.

1. One camera's tile shows an image-quality attention badge distinct from its otherwise-online
   state. The alert feed entry reads "Camera 14 — Severe Underexposure (ongoing 45 min)."
2. Dana opens a thumbnail preview directly from the alert without needing to pull a live stream,
   confirming the feed really is unusably dark.
3. She logs a maintenance ticket against that camera directly from the alert, and the alert stays
   open/tracked until the condition clears or she manually resolves it.

**What the user expects:** at fleet scale, a genuinely unusable image is called out with enough
detail (which condition, how long) to prioritize dispatch, without her having to check every
camera's live feed manually.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display a distinct image-quality health badge (naming the condition —
  underexposed, overexposed, or out-of-focus) on the affected camera's tile and in the alert
  feed, including how long the condition has persisted.
- **[vms]** The VMS shall let an operator create a maintenance ticket directly from an
  image-quality alert, and shall track the alert as open until the condition clears or is
  manually resolved.

## Scenario: Two adjacent cameras report conflicting image-quality conditions at once

**Scenario ID:** SCN-327
**Feature ID:** FEAT-086

**Persona:** Dana notices one camera reports "overexposed" while the physically adjacent camera
reports "underexposed" at the same time — a plausible real condition (e.g. one facing the sun,
one facing shade) rather than a bug, but worth distinguishing from a single shared cause.

1. The VMS lists both alerts independently rather than merging them, since they're different
   conditions on different cameras.
2. Dana can see each camera's individual condition and duration side by side to judge whether
   they're related (e.g. a site-wide event like fog) or coincidental.
3. She resolves each independently as she addresses them, and the VMS doesn't require closing
   one before the other.

**What the user expects:** simultaneous but different image-quality problems on different
cameras are tracked and resolved independently, without the system forcing a false connection
between them.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall track image-quality alerts per camera independently, even when
  multiple cameras report different conditions concurrently, and shall not require joint
  resolution.
- **[vms]** The VMS shall let an operator view all currently-open image-quality alerts across a
  site side by side to help distinguish a shared site-wide cause from independent per-camera
  issues.
