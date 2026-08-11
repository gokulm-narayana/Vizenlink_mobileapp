---
feature_id: FEAT-169
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Site-Type Installation Templates

Covers the VMS side of FEAT-169: pre-built configuration templates (default zone/rule presets,
naming conventions, placement guidance) for common deployment scenarios — villa, gate, parking,
lobby, corridor, small-office.

## Scenario: Admin applies a site-type template when setting up a new parking-lot site

**Scenario ID:** SCN-601
**Feature ID:** FEAT-169

**Persona:** Farid, setting up a new site for a client that operates a parking garage.

1. When creating the new site, Farid is offered a set of site-type templates: villa, gate,
   parking, lobby, corridor, small-office.
2. He selects "Parking," and the VMS pre-populates default zone/rule presets suited to
   parking-lot monitoring (e.g. vehicle-focused motion zones, naming conventions like "Parking -
   Level 1 - Entrance") and placement guidance for typical camera positions.
3. Farid reviews the pre-filled configuration, which already reflects sensible defaults for
   this site type, and only needs to adjust specifics for his actual layout rather than
   building everything from a blank slate.

**What the user expects:** setting up a common deployment type starts from a sensible baseline
instead of a blank configuration every time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall offer a set of site-type installation templates (e.g. villa, gate,
  parking, lobby, corridor, small-office) when creating a new site.
- **[vms]** The VMS shall pre-populate default zone/rule presets and naming conventions from
  the selected site-type template, editable afterward.

## Scenario: Customizations to a template-based site aren't overwritten by future template updates

**Scenario ID:** SCN-602
**Feature ID:** FEAT-169

**Persona:** Farid, months later, after the "Parking" template itself gets updated by a future
product release with new default presets.

1. Farid's existing parking site was set up using the "Parking" template and has since been
   customized with his own zone adjustments and camera names.
2. When the underlying "Parking" template is later updated, Farid's already-configured site
   keeps its own customized settings — it isn't silently reset or merged with the new template
   defaults.
3. If Farid wants to adopt the new template defaults, that requires an explicit action on his
   part, not something that happens automatically.

**What the user expects:** a template is a one-time starting point, not something that keeps
reaching back into his already-configured site.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall apply a site-type template only at the time it's selected, never
  retroactively re-applying or merging a later template update into an already-configured site
  without explicit user action.
</content>
