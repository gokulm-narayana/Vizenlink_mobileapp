---
feature_id: FEAT-074
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Crowd/Occupancy Threshold Events

Covers FEAT-074: alerting when the number of people in a zone (lobby/common area) exceeds a
configured occupancy threshold. Operator/community-deployment use case, per FEAT-074's
description.

## Scenario: Lobby occupancy exceeds the configured threshold

**Scenario ID:** SCN-262
**Feature ID:** FEAT-074

**Persona:** Dana, who wants to know if a community clubhouse's lobby ever exceeds its posted
occupancy limit of 40 people.

1. Dana configures an occupancy rule on the lobby zone with a threshold of 40.
2. During a well-attended event, the tracked person count in the zone crosses 40.
3. Dana receives an occupancy-threshold alert in the VMS naming the zone and the current
   count, and the alert clears automatically once the count drops back below the threshold.

**What the user expects:** she's notified promptly when a monitored area actually goes over
capacity, and the alert resolves itself once the crowd thins out, without her needing to
manually dismiss it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator configure a numeric occupancy threshold on a zone,
  raise an alert when the concurrently tracked person count in that zone exceeds it, and
  automatically clear the alert once the count drops back below threshold.
- **[camera-firmware]** The camera shall maintain a live count of concurrently tracked persons
  within a zone and report threshold crossings (both exceeding and dropping back below) to the
  VMS.

## Scenario: Overlapping/occluding people don't distort the occupancy count

**Scenario ID:** SCN-263
**Feature ID:** FEAT-074

**Persona:** Dana, monitoring the same lobby during a crowded event where people frequently
overlap and briefly block each other from the camera's view.

1. As the crowd moves, individuals momentarily overlap or occlude one another from the camera's
   angle.
2. The occupancy count doesn't wildly fluctuate (e.g. dropping and re-spiking) purely due to
   these momentary occlusions — the system tolerates brief overlap without losing track of
   already-counted individuals.
3. The reported count stays a reasonably stable, trustworthy estimate throughout the busy
   period, rather than looking erratic.

**What the user expects:** the occupancy count is usable during exactly the crowded conditions
it's meant for, not just in a sparse, easy-to-count scene.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera's occupancy counting shall tolerate brief mutual occlusion
  between tracked persons in a crowded zone without erroneously dropping or double-counting
  individuals, maintaining a stable count estimate under crowded conditions.
