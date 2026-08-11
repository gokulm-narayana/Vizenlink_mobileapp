---
feature_id: FEAT-146
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Distinct Household vs. Organization Role Models

Covers the VMS side of FEAT-146: organization deployments get the richer role model (Site
Owner, Security Supervisor/Operator, Resident/Tenant Viewer, Office Manager, Installer, Support
Technician, Auditor), kept distinct from the household model used by residential accounts.

## Scenario: Organization admin assigns roles from the richer org role model

**Scenario ID:** SCN-522
**Feature ID:** FEAT-146

**Persona:** Farid, the Site Owner of a corporate office deployment, onboarding a new security
guard through the VMS.

1. Farid opens the VMS's user management panel for his office site.
2. He sees the full set of organization roles: Site Owner, Security Supervisor, Security
   Operator, Resident/Tenant Viewer, Office Manager, Installer, Support Technician, Auditor.
3. He assigns the new guard the "Security Operator" role, scoped to live view, playback, and
   event acknowledgment, but not user management.
4. Later he assigns a visiting compliance reviewer the "Auditor" role, which grants access to
   logs and audit trails but explicitly no live view.
5. The VMS never offers the household model's shorthand roles (Family Viewer, Temporary Guest)
   in this organization context — those don't apply here.

**What the user expects:** an organization deployment gets the depth of role separation an
office/security team actually needs, without the household model's roles cluttering the list.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall present the full organization role set for organization-type sites,
  and shall never mix in household-model role names.
- **[vms]** The VMS shall enforce that each organization role's default permission set matches
  its intended scope (e.g. Auditor gets logs/audit access but no live view by default).

## Scenario: Attempting to apply a household-model role to an organization site

**Scenario ID:** SCN-523
**Feature ID:** FEAT-146

**Persona:** Farid's colleague, expecting to find a "Family Viewer" style role on the office
site's user list because that's the vocabulary he's used to from his own home camera.

1. The colleague opens the office site's user management panel and looks for a "Family Viewer"
   or "Guest" option.
2. The VMS doesn't offer those role names for this site at all — only the organization role set
   is presented, since the site is provisioned as an organization deployment.
3. If he tries to invite someone with a role name copied from a household context (e.g. a stale
   bookmark or old documentation), the VMS rejects it as not a valid role for this site type
   rather than silently accepting a mismatched or under-scoped role.

**What the user expects:** the two models stay genuinely separate — there's no accidental
cross-over that could create a confusing or under-scoped role assignment.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall reject any role-assignment request naming a role that doesn't belong
  to the site's provisioned model (organization vs. household), with an explicit error rather
  than silently mapping it to something else.
</content>
