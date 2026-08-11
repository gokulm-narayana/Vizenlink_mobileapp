---
feature_id: FEAT-225
status: draft
target_fr_docs: [FR-vms.md, FR-security-lifecycle.md]
---

# Scenario: VMS — Full Camera Privacy Mode / Physical Shutter

Covers FEAT-225's VMS side: a fleet operator needing visibility into which managed cameras are
currently in privacy mode, and being unable to silently override a privacy mode a resident/
owner has enabled on their own camera.

## Scenario: Fleet dashboard shows which cameras are in privacy mode

**Scenario ID:** SCN-687
**Feature ID:** FEAT-225

**Persona:** Raj manages a mixed fleet where some cameras are individually owned within a
community and residents can enable privacy mode on their own units.

1. Raj's dashboard shows a distinct "Privacy Mode" status for any camera currently in that
   state, distinguishable from an offline/error state, so he doesn't mistake it for a fault
   needing a support ticket.
2. Cameras in privacy mode show no live feed or recent recordings for that period in the VMS
   view, consistent with the camera actually not capturing anything.

**What the user expects:** he can tell privacy mode apart from a malfunction across his whole
fleet at a glance, without needing to call the resident to ask why their camera looks offline.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS fleet dashboard shall show a distinct "Privacy Mode" status for any camera
  currently in that state, visually distinguishable from an offline/error status.

## Scenario: An operator cannot silently override a resident's privacy mode

**Scenario ID:** SCN-688
**Feature ID:** FEAT-225

**Persona:** Raj, needing to check on a camera for an unrelated maintenance reason, finds it's
currently in privacy mode (enabled by the unit's resident).

1. Raj cannot remotely disable that camera's privacy mode from VMS without the resident's own
   action or explicit prior authorization on file, respecting that the resident enabled it for
   their own privacy.
2. If VMS's access model does grant an admin an emergency override (e.g. for a safety incident),
   using it requires an elevated, clearly-logged action distinct from routine camera management,
   and notifies the resident that their privacy mode was overridden and why.

**What the user expects:** privacy mode is a real guarantee to the person who enabled it, not
something a fleet operator can quietly bypass during routine operations.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall not permit routine/administrative disabling of a resident-enabled
  privacy mode without the resident's own action or a pre-authorized emergency-override
  permission.
- **[vms]** Any emergency override of a resident's privacy mode shall require an elevated,
  distinctly logged action and shall notify the affected resident that it occurred and why.
