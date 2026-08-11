---
feature_id: FEAT-049
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Camera-Side Storage Capacity Estimation

Covers FEAT-049: the camera estimating and displaying remaining local-SD recording time based
on current bitrate and free storage, proactively — distinct from storage-failure detection
(FEAT-038), which reacts to something already broken.

## Scenario: Homeowner views estimated remaining recording time

**Scenario ID:** SCN-169
**Feature ID:** FEAT-049

**Persona:** Marcus wants to know, in plain terms, how much recording history his SD card can
currently hold before it starts overwriting.

1. Marcus opens the camera's storage settings.
2. The app shows an estimate like "approximately 12 days of recording remaining" based on the
   card's free space and the camera's current recording bitrate.
3. The estimate is presented as an approximation (not a false-precision exact figure), since
   actual usage varies with scene activity and encoding.

**What the user expects:** a plain, useful answer to "how much history do I actually have,"
without needing to do the math himself from raw card-size and bitrate numbers.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display an estimated remaining local recording duration on the
  storage settings screen, computed from current free SD space and recording bitrate.
- **[mobile-app]** The app shall present the estimate as approximate, not as a false-precision
  exact figure.
- **[camera-firmware]** The camera shall compute and report free SD space and current recording
  bitrate so a client can derive an estimated remaining recording duration.

## Scenario: Estimate updates after a bitrate/quality change

**Scenario ID:** SCN-170
**Feature ID:** FEAT-049

**Persona:** Priya increases her camera's recording resolution/quality, which raises its
bitrate.

1. Priya changes the video quality setting to a higher resolution.
2. The storage-remaining estimate on the settings screen updates to reflect the new, higher
   bitrate, showing a shorter remaining duration than before the change.
3. Priya can see, before committing to the change, roughly how it affects her remaining
   recording time — so the tradeoff is visible up front, not just discovered later.

**What the user expects:** the remaining-time estimate stays honest and current as he changes
settings that actually affect it, ideally before he commits to the change.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall recompute and display the updated remaining-recording-time
  estimate whenever recording bitrate/quality settings change.
- **[mobile-app]** The app shall preview the estimated impact of a pending quality/bitrate
  change on remaining recording time before the user confirms the change.

## Scenario: Estimate shows critically low remaining time

**Scenario ID:** SCN-171
**Feature ID:** FEAT-049

**Persona:** Marcus's SD card is nearly full at his current retention/bitrate settings, leaving
only a very short remaining-recording estimate.

1. As the estimate drops below a low threshold (e.g. under a day), the app highlights it
   distinctly (e.g. a warning color/badge) rather than presenting it identically to a healthy
   estimate.
2. This is presented as a proactive advisory ("your history is about to get very short") rather
   than the reactive critical failure state used by FEAT-038, since nothing has actually failed
   yet — the card is simply near its natural overwrite point.
3. Marcus can act on it (e.g. adjust retention, lower quality, or accept the shorter window)
   directly from this same screen.

**What the user expects:** he's warned before his usable recording history shrinks to something
uncomfortably short, with a way to do something about it right there.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall visually distinguish a critically low remaining-recording-time
  estimate from a healthy one, without presenting it as a storage-failure condition.
- **[mobile-app]** The app shall surface relevant remediation controls (retention duration,
  quality/bitrate settings) alongside a low remaining-time estimate.
