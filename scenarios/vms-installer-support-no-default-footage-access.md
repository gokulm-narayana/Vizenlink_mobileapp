---
feature_id: FEAT-152
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — No Default Footage Access for Installer/Support Roles

Covers the VMS side of FEAT-152: Installer and Support Technician roles default to
device/diagnostic access only, with footage access requiring an explicit, separate grant.

## Scenario: Support technician's remote session defaults to diagnostics only

**Scenario ID:** SCN-551
**Feature ID:** FEAT-152

**Persona:** A vendor support technician remotely assisting an org site with a network
connectivity issue.

1. The site's admin creates a Support Technician account/session for the vendor to use.
2. By default, the technician can see device health, logs, and network diagnostics for the
   affected cameras — but no live view, playback, or export is available to them.
3. The technician resolves the connectivity issue using only diagnostic tools, without ever
   touching footage.

**What the user expects:** outside support staff can do their job without a standing ability
to watch the site's cameras.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall default the Support Technician (and Installer) role to
  device/diagnostic access only, with no footage-related permission included by default.

## Scenario: A support technician needs footage access mid-session and must get an explicit, logged grant

**Scenario ID:** SCN-552
**Feature ID:** FEAT-152

**Persona:** The same support technician, now needing to confirm a motion-zone configuration is
actually detecting movement correctly, which requires seeing a short live clip.

1. The technician explains to the site admin that resolving the issue requires briefly seeing
   the camera's live view.
2. The admin explicitly grants a scoped, temporary live-view permission to the technician's
   session — a distinct action from the default diagnostic access, not something the technician
   could self-escalate to.
3. The technician verifies the motion zone, and the temporary grant is then revoked/expires.
4. The whole exchange — the explicit grant, its scope, and its later revocation — is recorded
   in the audit log.

**What the user expects:** any footage access for a support role always requires a deliberate,
visible decision by someone with the authority to grant it — never something the support role
can switch on itself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall require an explicit, separately-authorized grant before any
  footage-related permission is added to a Support Technician or Installer session, never
  allowing the role itself to self-escalate.
- **[vms]** The VMS shall log the grant, its scope, and its later expiry/revocation of any
  temporary footage access given to an Installer/Support Technician role.
</content>
