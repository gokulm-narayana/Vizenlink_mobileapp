---
feature_id: FEAT-009
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-onvif-stack.md, FR-access-control.md]
---

# Scenario: VMS — Privacy Masks

Covers the fleet-operator-facing side of FEAT-009 (Privacy Masks): an installer/admin configuring
privacy masks on cameras at a community or office site, restricted to admin-level VMS accounts.

## Scenario: Admin masks a public sidewalk area to comply with site policy

**Scenario ID:** SCN-027
**Feature ID:** FEAT-009

**Persona:** Marcus, an admin-level VMS user, is told that a community site's entrance camera must
not record the public sidewalk beyond the property line, per HOA policy.

1. Marcus opens that camera's privacy mask editor in the VMS, restricted to admin-level accounts.
2. He draws a mask over the sidewalk region using the live view as reference.
3. He saves it, and the VMS confirms the mask is active — the masked region shows as permanently
   blacked out in the live feed and in the recorded footage going forward.
4. He can verify this from any other VMS session (e.g. a different operator's login) that the
   mask is enforced identically, not just on his own session.

**What the user expects:** once he sets a privacy mask to satisfy a policy requirement, it's
reliably enforced for every viewer of that camera, not just cosmetically applied in his own UI.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall restrict privacy mask creation/editing to admin-level accounts, and
  shall display existing masks (read-only) to lower-privilege viewers so they understand a region
  is intentionally obscured.
- **[camera-firmware]** The camera shall enforce privacy masks identically for every client
  requesting its stream, since masking is applied at the camera/encoder level rather than by any
  individual viewing client.

## Scenario: Reviewing privacy masks across a site during a compliance audit

**Scenario ID:** SCN-028
**Feature ID:** FEAT-009

**Persona:** Marcus needs to confirm, ahead of a compliance audit, that every camera required to
mask a specific area (e.g. neighboring private property) at a site actually has that mask applied
and hasn't been accidentally cleared.

1. Marcus opens a fleet-level privacy mask overview for the site.
2. He can see, per camera, whether any privacy masks are configured, without opening each
   camera's individual editor.
3. He finds one camera where a required mask is missing (e.g. removed during a firmware
   reconfiguration) and re-applies it directly from this overview.

**What the user expects:** verifying that required privacy masks are actually still in place
across a whole site doesn't require manually re-checking every camera one at a time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-level view showing which cameras currently have privacy
  masks configured, without requiring the operator to open each camera's individual editor.
- **[vms]** The VMS shall allow an admin to re-apply or edit a camera's privacy mask directly from
  this fleet-level view.
