---
feature_id: FEAT-169
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Site-Type Installation Templates

Covers the mobile-app side of FEAT-169: pre-built configuration templates (default zone/rule
presets, naming conventions, placement guidance) for common deployment scenarios, applied
during installer commissioning.

## Scenario: Installer applies a site-type template during commissioning

**Scenario ID:** SCN-603
**Feature ID:** FEAT-169

**Persona:** Diego, commissioning a camera at a client's private villa.

1. During commissioning, the app asks Diego to pick a site type from a short list: villa,
   gate, parking, lobby, corridor, small-office.
2. He selects "Villa," and the app applies default zone/rule presets suited to a residential
   villa (e.g. perimeter/driveway-focused zones) along with placement guidance suggesting
   typical camera positions and naming conventions like "Villa - Front Gate."
3. Diego adjusts the presets slightly for the specific property layout and continues through
   the rest of commissioning with a strong starting point already in place.

**What the user expects:** commissioning a common deployment type starts from a sensible,
ready-made baseline rather than configuring everything by hand on-site.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a set of site-type installation templates (e.g. villa,
  gate, parking, lobby, corridor, small-office) during commissioning.
- **[mobile-app]** The app shall apply default zone/rule presets, naming conventions, and
  placement guidance from the selected site-type template, editable by the installer
  afterward.

## Scenario: No template fits, and the installer proceeds with a custom configuration instead

**Scenario ID:** SCN-604
**Feature ID:** FEAT-169

**Persona:** Diego, commissioning a camera at an unusual site (e.g. a warehouse loading dock)
that doesn't match any of the offered templates well.

1. Diego reviews the available site-type templates and none of them describes this site
   adequately.
2. He selects a "Custom / No template" option instead, which starts commissioning from a blank
   zone/rule configuration rather than forcing an ill-fitting template onto the site.
3. He configures the zones and naming manually, and commissioning proceeds normally from there.

**What the user expects:** templates are a convenience for common cases, never a requirement
that gets in the way of an unusual site.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide an explicit "custom/no template" option during
  commissioning, so the installer is never forced to select an ill-fitting site-type template.
</content>
