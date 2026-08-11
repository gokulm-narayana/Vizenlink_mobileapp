---
feature_id: FEAT-156
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — User Invitation & Access Grant Flow

Covers the VMS side of FEAT-156: an admin invites a new person (by email) and grants them a
specific role/scope on a site or camera, as part of one continuous flow.

## Scenario: Org admin invites a new staff member and assigns role+scope

**Scenario ID:** SCN-570
**Feature ID:** FEAT-156

**Persona:** Farid, onboarding a new front-desk hire at one of his sites.

1. Farid opens user management and invites the new hire by email.
2. He assigns the Office Manager role, scoped to just that site.
3. The new hire receives an email invitation, creates their VMS login, and lands with exactly
   the assigned role and scope active.
4. Farid sees the invitation's status update from pending to accepted.

**What the user expects:** bringing a new staff member into the VMS with the right access is a
single guided flow, not several disconnected admin steps.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an admin invite a new user by email and assign a specific role
  and site/camera scope as part of the same invitation.
- **[vms]** The VMS shall show invitation status (pending, accepted, expired) to the inviting
  admin.

## Scenario: An invitation expires before the new hire accepts it

**Scenario ID:** SCN-571
**Feature ID:** FEAT-156

**Persona:** Farid, whose new hire didn't check their email in time and the invitation's
validity window (e.g. 7 days) passed.

1. Farid checks the pending invitations list and sees the new hire's invitation is now marked
   "expired," not "pending."
2. He can't simply have the new hire click the old link — it's no longer valid.
3. Farid resends the invitation with a single action, generating a fresh, valid link, without
   needing to re-enter the role/scope details from scratch.

**What the user expects:** an expired invite is clearly distinguished from one still waiting,
and recovering from it is a quick resend rather than starting the whole setup over.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expire an invitation link after a configured validity window, and
  shall distinguish "expired" from "pending" in the admin's invitation list.
- **[vms]** The VMS shall let an admin resend an expired invitation without re-entering the
  originally configured role/scope.
</content>
