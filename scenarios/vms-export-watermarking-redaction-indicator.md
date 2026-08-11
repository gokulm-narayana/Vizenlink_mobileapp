---
feature_id: FEAT-195
status: draft
target_fr_docs: [FR-vms.md, FR-security-lifecycle.md]
---

# Scenario: VMS — Export Watermarking & Redaction Indicator

Covers FEAT-195's VMS side: an operator exporting footage for an investigation or handoff, with
the same watermarking and redaction-indicator guarantees as the mobile app, at fleet scale.

## Scenario: Operator exports evidence footage for a police handoff

**Scenario ID:** SCN-643
**Feature ID:** FEAT-195

**Persona:** Raj exports footage from a community-lobby camera to hand to police investigating a
theft.

1. Raj selects the time range and camera in VMS and exports it.
2. The exported file carries a visible burned-in watermark identifying the source camera and
   export timestamp, and VMS logs the export per FEAT-192.
3. If the exported range includes any privacy-masked region (e.g. a resident's unit door
   configured as a masked zone), the export carries a visible "Redacted" indicator.

**What the user expects:** evidence he hands over is traceable to its source and honest about
whether anything in it was altered, protecting both the investigation's integrity and his
organization's liability.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** VMS-initiated exports shall carry the same burned-in watermark and "Redacted"
  indicator behavior as mobile-app exports of the same footage.

## Scenario: Bulk export across multiple cameras for an incident spanning several feeds

**Scenario ID:** SCN-644
**Feature ID:** FEAT-195

**Persona:** Raj needs footage from four different lobby/hallway cameras covering the same
incident window.

1. Raj selects all four cameras and the same time range, and exports them as a single bundled
   package.
2. Each individual clip in the bundle carries its own watermark (source camera, timestamp) and
   its own redaction indicator where applicable — the bundle doesn't flatten this per-clip
   detail into one bundle-level note.

**What the user expects:** a multi-camera export stays individually traceable and honest per
clip, since each clip may need to stand on its own as evidence.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** A bulk/multi-camera export shall preserve per-clip watermarking and per-clip
  redaction indicators, rather than applying one summary note across the whole bundle.

## Scenario: An export request is made for a camera the requester doesn't have export rights to

**Scenario ID:** SCN-645
**Feature ID:** FEAT-195

**Persona:** A front-desk staff account with view-only permissions attempts to export footage
from a camera outside their granted scope.

1. The export option is either not offered, or the attempt is rejected with a clear
   "insufficient permission" message — the export never silently succeeds without the
   appropriate role.
2. The attempt itself is audit-logged as a denied access attempt.

**What the user expects:** export capability is gated by the same access-control rules as any
other sensitive action, and an unauthorized attempt leaves a record rather than a silent no-op.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** Export capability shall be gated per the user's role/permission scope for the
  specific camera; a denied export attempt shall be reported clearly to the user and
  audit-logged.
