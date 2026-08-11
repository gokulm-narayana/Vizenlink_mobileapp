---
feature_id: FEAT-089
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md]
---

# Scenario: VMS — Prominent "Online But Unusable" Health Display

Covers the fleet-operator-facing side of FEAT-089: making sure degraded-but-connected cameras
stand out in the fleet grid rather than reading as generically healthy.

## Scenario: Fleet grid distinguishes "connected and fine" from "connected but degraded"

**Scenario ID:** SCN-338
**Feature ID:** FEAT-089

**Persona:** Dana, an operator scanning a 40-camera grid for anything needing attention.

1. Cameras with an active degradation condition (blocked view, unusable image, storage failure)
   show a visually distinct tile treatment — not the same plain "online" green indicator used for
   fully healthy cameras — even though they remain network-reachable.
2. Dana can filter the grid to "needs attention" cameras specifically, and this filter includes
   both fully-offline cameras and degraded-but-online ones, since both need her action, just for
   different reasons.
3. Hovering/clicking shows the specific reason, so she doesn't have to guess why a given camera
   is flagged.

**What the user expects:** the grid never lets a functionally-broken-but-connected camera hide
behind a generic "online" indicator — anything needing her attention is visually distinguishable
from anything genuinely fine, fleet-wide.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall render a distinct tile/badge treatment for any camera with an active
  degradation condition, visually different from both fully-healthy "online" and fully
  "offline," across the fleet grid.
- **[vms]** The VMS shall provide a unified "needs attention" filter that includes both offline
  cameras and degraded-but-online cameras, each showing its specific reason on inspection.

## Scenario: A degraded camera is deprioritized by a newer operator unfamiliar with the site

**Scenario ID:** SCN-339
**Feature ID:** FEAT-089

**Persona:** A new operator covering Dana's shift for the day sees the fleet grid for the first
time and needs to correctly prioritize a degraded-but-connected camera over a batch of routine
motion alerts from healthy cameras.

1. The grid's visual hierarchy makes the degraded camera stand out even without prior site
   familiarity — its badge styling and position in a sorted "attention" list make its priority
   unambiguous.
2. The new operator opens the flagged camera and sees a plain-language reason plus how long the
   condition has been active, letting them act correctly without needing Dana's institutional
   knowledge of the site.
3. They log the appropriate maintenance action directly, and it's recorded under that camera's
   history for Dana to review when she returns.

**What the user expects:** the display is legible enough that a health condition gets triaged
correctly even by someone unfamiliar with the specific site or its cameras.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall present degradation conditions with plain-language descriptions and
  duration-since-onset, sufficient for an operator unfamiliar with the specific camera/site to
  triage correctly without prior context.
- **[vms]** The VMS shall record any maintenance action taken against a degradation condition in
  that camera's persistent history, visible to any operator who later reviews it.
