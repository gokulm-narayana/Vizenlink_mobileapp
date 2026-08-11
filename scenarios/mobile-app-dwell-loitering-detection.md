---
feature_id: FEAT-071
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Dwell/Loitering Detection

Covers the homeowner-facing side of FEAT-071: alerting when an object remains within a zone
longer than a configured dwell threshold.

## Scenario: Person lingers near the door beyond the threshold

**Scenario ID:** SCN-251
**Feature ID:** FEAT-071

**Persona:** Sofia, who wants to know if someone hangs around her front door area rather than
just passing by or making a quick delivery.

1. Sofia sets a loitering rule on her front-door zone with a 2-minute dwell threshold.
2. A stranger stands near the door for over 2 minutes without leaving.
3. Once the 2-minute mark is crossed, Sofia's phone receives a "Loitering detected" alert,
   distinct from an ordinary person-detected alert.
4. The linked clip covers the full dwell period so far, not just the trigger instant.

**What the user expects:** a brief visit (courier drop-off) doesn't alert her as loitering, but
someone genuinely lingering does, clearly labeled as such.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure a dwell/loitering threshold duration on a
  zone-based rule, and shall label a resulting alert as "Loitering" distinctly from an ordinary
  entry/presence alert.
- **[camera-firmware]** The camera shall track a detected object's continuous time within a
  zone and raise a loitering-triggered event only once that continuous dwell time exceeds the
  rule's configured threshold.

## Scenario: Person leaves briefly then returns — dwell timer reset vs. continuation

**Scenario ID:** SCN-252
**Feature ID:** FEAT-071

**Persona:** Sofia, whose visitor steps just outside the zone boundary for a few seconds (e.g.
to look at something) before returning to the same spot.

1. The person exits the zone briefly, then re-enters within a few seconds.
2. Because the gap is short, the camera treats it as continuous dwell (not a reset to zero), so
   the loitering timer keeps accumulating across the brief gap.
3. If instead the person had left for several minutes before returning, the camera would treat
   the later presence as a fresh dwell period starting from zero.

**What the user expects:** a momentary step outside the zone doesn't unfairly reset an otherwise
continuous loitering situation, but a genuinely separate, later visit isn't wrongly combined
with an earlier one either.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall tolerate a brief gap (within a bounded short window,
  consistent with FEAT-062's short-term tracking) in an object's zone presence without resetting
  its accumulated dwell time, but shall reset the dwell timer to zero for a gap exceeding that
  window.
