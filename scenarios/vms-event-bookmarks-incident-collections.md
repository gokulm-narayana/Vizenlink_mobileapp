---
feature_id: FEAT-127
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Event Bookmarks & Multi-Clip Incident Collections

Covers the VMS side of FEAT-127: an operator assembling a multi-camera, multi-clip incident
collection for a site, and sharing it as one bundle.

## Scenario: Operator assembles a cross-camera incident collection for a case

**Scenario ID:** SCN-480
**Feature ID:** FEAT-127

**Persona:** Marcus is building a record of a break-in attempt captured piecemeal across three
different cameras at a site.

1. Marcus creates a named collection and adds the relevant events from each of the three
   cameras to it, in the order they occurred.
2. The collection view presents all three clips together as one coherent case record, each
   still attributed to its own camera/timestamp, viewable alongside the case's incident-
   management notes/status (FEAT-126) if one exists for the same events.

**What the user expects:** building a complete cross-camera case record doesn't require
juggling three separate camera timelines mentally — the collection holds it together.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator create a named incident collection spanning events
  from multiple cameras at a site, viewable together with per-event camera/timestamp
  attribution.
- **[vms]** A collection view shall be able to surface each included event's incident-management
  status/notes (per FEAT-126) alongside the clip itself, where such a case exists.

## Scenario: Exporting a collection as a single shareable bundle

**Scenario ID:** SCN-481
**Feature ID:** FEAT-127

**Persona:** Marcus needs to hand the full cross-camera collection from SCN-480 to law
enforcement as one package rather than three separate clip downloads.

1. Marcus exports the collection; the VMS produces a single bundle (e.g. a packaged download or
   one share link) containing every clip in the collection along with its camera/timestamp
   metadata.
2. The recipient can access every clip in the bundle without needing separate access to each
   individual camera's own event history.

**What the user expects:** handing off a multi-camera case to an outside party is one export
action, not three separate ones he has to remember to assemble correctly himself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support exporting an entire incident collection as a single bundle
  (packaged download or share link) containing every included clip and its camera/timestamp
  metadata.
