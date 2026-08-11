---
feature_id: FEAT-040
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Evidence Export with Integrity Manifest

Covers the fleet-operator-facing side of FEAT-040: exporting evidence-grade clips with
metadata and an integrity manifest, for a security operator responding to a formal request
(police, legal, insurance).

## Scenario: Security operator exports evidence for a formal request

**Scenario ID:** SCN-143
**Feature ID:** FEAT-040

**Persona:** Marcus, a security operator at a community site, receives a formal request from
police for footage of an incident spanning two cameras.

1. Marcus selects the relevant clips across both cameras and initiates an export.
2. The VMS packages each clip with its camera/site/time metadata and computes an integrity
   manifest covering the full export bundle.
3. The VMS logs the export itself (who exported what, when, for which request) as part of the
   site's audit trail, distinct from the manifest that protects the exported content's
   integrity.
4. Marcus downloads the completed export bundle, ready to hand over.

**What the user expects:** a formal evidence request produces something he can defend later —
both that the footage itself is provably unaltered, and that there's a record of the export
having happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator export one or more clips bundled with camera/site/time
  metadata and a cryptographic integrity manifest covering the exported content.
- **[vms]** The VMS shall log every export event (user, timestamp, clips exported) to a
  site-level audit trail, separate from the per-export integrity manifest.

## Scenario: Export interrupted mid-transfer

**Scenario ID:** SCN-144
**Feature ID:** FEAT-040

**Persona:** Priya starts a large multi-camera evidence export, and her connection to the VMS
drops partway through.

1. The VMS detects the interrupted export and does not present a partial file as if it were a
   complete, valid export.
2. Priya can resume or restart the export once reconnected; the VMS makes clear whether a
   previously partial export is still usable or must be redone.
3. Any bundle that does complete still has its integrity manifest computed only over the actual
   final, complete content — never over a partial state.

**What the user expects:** an interrupted export never quietly hands her something that looks
complete but isn't, especially for something meant to serve as evidence.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect an interrupted evidence export and clearly mark any resulting
  partial file as incomplete rather than presenting it as a finished export.
- **[vms]** The VMS shall allow resuming or restarting an interrupted export, and shall compute
  the integrity manifest only over the final, complete exported content.
