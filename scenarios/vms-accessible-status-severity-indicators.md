---
feature_id: FEAT-220
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Accessible Status/Severity Indicators (Not Color-Only)

Covers FEAT-220's VMS side: a fleet operator scanning a dashboard of many cameras needs severity/
health states conveyed with labels/icons, not color alone, and the dashboard's controls must
remain keyboard/screen-reader operable.

## Scenario: Scanning a large fleet dashboard for problem cameras

**Scenario ID:** SCN-674
**Feature ID:** FEAT-220

**Persona:** Raj, color-blind, scans a 40-camera dashboard grid for anything needing attention.

1. Each camera tile shows a status icon and short text label (e.g. "Offline", "Storage Full",
   "Update Needed") alongside its color accent, so Raj can identify problem cameras by icon/label
   even without distinguishing the color.
2. Sorting/filtering the dashboard by severity is available as a control, not only inferable
   from scanning colors visually.

**What the user expects:** he can operate the fleet dashboard as effectively as any other
operator, regardless of color perception.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS fleet dashboard shall pair every camera health/severity indicator with a
  readable text label and/or icon, never color alone, and shall offer a severity filter/sort
  control.

## Scenario: Operating the dashboard via keyboard/screen reader only

**Scenario ID:** SCN-675
**Feature ID:** FEAT-220

**Persona:** An operator using a screen reader (e.g. due to a temporary or permanent vision
impairment) manages the same fleet dashboard.

1. Tabbing through the dashboard announces each camera's name and current status/severity as
   text, in a sensible reading order, rather than relying on a visual grid layout that has no
   equivalent linear structure for a screen reader.
2. Every action available on a camera tile (acknowledge, view live, open details) is reachable
   and operable by keyboard alone.

**What the user expects:** the dashboard is fully usable without a mouse or the ability to
perceive its visual layout.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS dashboard shall expose each camera tile's status/severity as
  screen-reader-readable text in a sensible navigation order, and every tile action shall be
  reachable and operable via keyboard alone.
