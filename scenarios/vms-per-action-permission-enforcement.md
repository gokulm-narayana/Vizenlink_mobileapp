---
feature_id: FEAT-147
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Per-Action Permission Enforcement

Covers the VMS side of FEAT-147: permissions are enforced separately per action, so a role
granting one capability never implicitly grants another.

## Scenario: An operator with live view but no settings access

**Scenario ID:** SCN-527
**Feature ID:** FEAT-147

**Persona:** Jamie, a Security Operator on an office VMS, granted live view and playback but
not settings/rule configuration.

1. Jamie logs into the VMS and watches several camera tiles live, and pulls up playback for an
   earlier shift's footage.
2. Jamie tries to open a camera's settings panel (e.g. to adjust motion zones) and finds the
   settings tab isn't available at all.
3. If Jamie reaches a settings URL directly (e.g. a bookmarked link from a previous role), the
   VMS blocks the action server-side and shows a permission-denied message, not just hiding the
   button.

**What the user expects:** live view/playback capability never implicitly grants
configuration capability — trying to reach it directly is blocked, not just hidden from the
menu.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall enforce settings/rule-configuration access as a permission fully
  independent of live view/playback, hiding the relevant UI and rejecting any direct request
  server-side.
- **[vms]** The VMS shall enforce every permission check at the backend/API layer, not only in
  the UI, so a user cannot bypass a hidden control by crafting a direct request.

## Scenario: Audit-log access and user-management access are separately grantable

**Scenario ID:** SCN-528
**Feature ID:** FEAT-147

**Persona:** an Auditor-role user at a corporate site, reviewing recent configuration changes.

1. The Auditor opens the VMS's audit log and reviews recent permission changes and exports.
2. They do not have access to the user-management screen at all — they can see who did what
   (via the audit log) but cannot themselves grant, change, or revoke anyone's access.
3. When they try to navigate to user management via a direct link, the VMS denies the request
   rather than granting incidental access just because they can view the audit trail.

**What the user expects:** being trusted to review history doesn't imply being trusted to
change anything.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall keep audit-log-viewing and user-management permissions fully
  independent, so a role granted one is not implicitly granted the other.
- **[vms]** The VMS shall deny direct/bookmarked navigation to a permission-gated screen for a
  user lacking that specific permission, consistent with its hidden-UI behavior.
</content>
