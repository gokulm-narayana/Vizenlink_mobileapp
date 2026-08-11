---
feature_id: FEAT-116
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Event Detail Screen

Covers the VMS single-event detail view for FEAT-116, for an operator managing a multi-camera
site rather than a single-household user.

## Scenario: Operator reviews an event's full detail during a shift

**Scenario ID:** SCN-423
**Feature ID:** FEAT-116

**Persona:** Marcus opens a flagged event from the site's event list mid-shift.

1. The detail view shows event type, camera name, site/zone, local time (site's configured time
   zone, which may differ from Marcus's own if he's remote), snapshot, clip, confidence, and
   which rule matched.
2. Because this is a shared, multi-operator system, the detail view also shows whether another
   operator has already reviewed or acted on this event (see FEAT-117/FEAT-133 for the action
   and sync mechanics) so Marcus doesn't duplicate work purely from this screen's context.

**What the user expects:** the same complete field checklist as the mobile app, but scoped to a
site/operator context rather than a single homeowner's cameras.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The event detail view shall display event type, camera name, site/zone name, and
  local time in the site's configured time zone, alongside snapshot, clip, confidence label,
  and matched rule.
- **[vms]** The event detail view shall indicate whether any other operator has already
  reviewed or actioned this event, so a shared operations team isn't duplicating review effort
  purely by looking at this screen.
- **[camera-firmware]** The camera shall attach zone, rule-match, and confidence metadata to
  each event at generation time, consistent across both mobile-app and VMS consumption.

## Scenario: Zone or rule referenced by an old event has since been changed or removed

**Scenario ID:** SCN-424
**Feature ID:** FEAT-116

**Persona:** Marcus opens a month-old event whose zone was later renamed, or whose triggering
rule has since been deleted during a site reconfiguration.

1. The detail view still shows the zone name and rule description exactly as they were at the
   time the event was generated, not the current (renamed/deleted) configuration.
2. If the zone/rule no longer exists at all, the screen labels it clearly as historical/no
   longer configured, rather than showing a broken reference or silently omitting the field.

**What the user expects:** old events keep an accurate historical record even after zones and
rules are reconfigured — reviewing history shouldn't be corrupted by later admin changes.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The event detail view shall display the zone and rule context as they existed at
  the time the event was recorded, independent of later renames or deletions of that zone/rule.
- **[camera-firmware]** The camera shall snapshot the zone name and rule description into the
  event's own metadata at generation time, rather than storing only a reference ID that could
  later point at a changed or deleted configuration.
