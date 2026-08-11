---
feature_id: FEAT-220
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Accessible Status/Severity Indicators (Not Color-Only)

Covers FEAT-220: health and severity states in the app are never conveyed by color alone —
always paired with a readable label/icon — and controls remain operable via accessible means
(e.g. screen reader).

## Scenario: A color-blind user checks camera health status

**Scenario ID:** SCN-672
**Feature ID:** FEAT-220

**Persona:** Karan, who is red-green color-blind, checks his camera dashboard for any issues.

1. Karan looks at his camera list and sees each camera's health shown as an icon plus a text
   label ("Online", "Attention needed", "Offline") next to a color accent — not a color-only dot
   he'd have to guess the meaning of.
2. He can tell "Attention needed" (amber) apart from "Offline" (red) purely from the icon/label,
   without relying on the color difference at all.

**What the user expects:** he gets the same information as anyone else, regardless of how he
perceives color.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall pair every health/severity status indicator with a readable
  text label and/or distinct icon, never conveying the state through color alone.

## Scenario: A screen-reader user navigates a severity alert and its controls

**Scenario ID:** SCN-673
**Feature ID:** FEAT-220

**Persona:** Meera uses a screen reader to navigate the app.

1. When a high-severity alert appears, the screen reader announces both the event and its
   severity level in words (e.g. "High severity: tamper detected"), not just a visual color cue
   the reader can't perceive.
2. Any action associated with the alert (dismiss, view live feed, acknowledge) is reachable and
   operable via the screen reader's standard navigation, not only via a gesture or visual-only
   affordance.

**What the user expects:** she can perceive severity and act on an alert entirely through
non-visual means, with nothing exclusively color- or gesture-dependent.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Severity/status announcements exposed to assistive technology shall include
  the severity level as text/label content, not rely on color/visual styling alone.
- **[mobile-app]** Every control associated with a status/severity indicator shall be operable
  via standard accessible navigation (e.g. screen-reader focus and activation), not only via a
  color-dependent or gesture-only affordance.
