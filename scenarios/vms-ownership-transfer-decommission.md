---
feature_id: FEAT-125
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md, FR-security-lifecycle.md]
---

# Scenario: VMS — Secure Ownership Transfer/Decommission Flow

Covers the VMS side of FEAT-125: transferring a camera between organizations/sites, or
decommissioning it from a fleet, in a multi-operator context.

## Scenario: Administrator transfers a camera to a different organization

**Scenario ID:** SCN-470
**Feature ID:** FEAT-125

**Persona:** Diane's organization sold a camera-equipped property to a different management
company, which now operates its own VMS account.

1. Diane opens a "Transfer Ownership" flow for the specific camera in the VMS admin panel and
   confirms, with an explicit high-friction confirmation given the permanence of the action.
2. The camera clears Diane's organization's credentials, site/zone/rule configuration, and
   pairing, returning to an unprovisioned state the receiving organization can newly provision.
3. The camera disappears from Diane's organization's fleet dashboard, and access logs record
   who performed the transfer and when.

**What the user expects:** transferring a camera between organizations is a clean handoff with
an audit trail, leaving no residual access for the old organization.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide an administrator-only "Transfer Ownership" flow per camera,
  requiring explicit high-friction confirmation, that clears the current organization's
  credentials, configuration, and pairing from the device.
- **[access-control]** Ownership transfer and decommission actions shall be restricted to users
  holding an administrative role for the owning organization, distinct from ordinary operator
  permissions.
- **[security-lifecycle]** Ownership transfer/decommission actions shall be recorded in an
  audit log capturing the acting administrator, timestamp, and camera identity.

## Scenario: Decommissioning a camera being permanently removed from the fleet

**Scenario ID:** SCN-471
**Feature ID:** FEAT-125

**Persona:** Diane's site is retiring an old camera model entirely, with no successor owner.

1. Diane uses the "Decommission Device" flow, distinct from Transfer Ownership, to factory-reset
   and remove the camera from the organization's active fleet.
2. Historical events/recordings tied to that camera remain accessible in the VMS per the
   organization's retention policy (for audit/compliance purposes) even after the physical
   device itself is wiped and removed.

**What the user expects:** wiping the physical device doesn't have to mean losing the
organization's own compliance/audit history of what that camera recorded while it was active.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a "Decommission Device" flow that factory-resets and removes
  a camera from the active fleet, distinct from Transfer Ownership.
- **[security-lifecycle]** Decommissioning a camera shall not, by itself, delete the
  organization's own retained historical event/recording records for that camera — device wipe
  and recording retention are governed independently.

## Scenario: A non-administrator attempts to transfer or decommission a camera

**Scenario ID:** SCN-472
**Feature ID:** FEAT-125

**Persona:** An ordinary operator (not an administrator) tries to access the Transfer
Ownership/Decommission flow, either by mistake or by probing what they can reach.

1. The VMS does not present the Transfer/Decommission controls to a non-administrator role at
   all.
2. If attempted directly (e.g. a stale link or an out-of-date client), the server rejects the
   request with a clear permission-denied response, and no change is made to the camera's
   ownership or configuration.

**What the user expects:** an action this consequential and hard to reverse can never be
triggered by anyone other than a genuinely authorized administrator.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The Transfer Ownership and Decommission Device controls shall be hidden entirely
  from any role without administrative permission.
- **[access-control]** The server shall independently authorize every transfer/decommission
  request against the acting user's current administrative role, rejecting any request from an
  insufficiently-privileged account regardless of what the requesting client's UI displays.
