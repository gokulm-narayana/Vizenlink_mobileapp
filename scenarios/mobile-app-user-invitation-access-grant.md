---
feature_id: FEAT-156
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — User Invitation & Access Grant Flow

Covers the mobile-app side of FEAT-156: an owner invites a new person (by phone/email) and
grants them a specific role/scope on a camera or site, as part of one continuous flow.

## Scenario: Homeowner invites a family member and grants a scoped role

**Scenario ID:** SCN-567
**Feature ID:** FEAT-156

**Persona:** Priya, wanting to give her adult daughter access to view the home cameras.

1. Priya opens "Invite someone" and enters her daughter's phone number.
2. She selects the Family Viewer role and scopes it to all cameras at the property.
3. Her daughter receives an invitation (SMS/notification) and accepts it from her own phone,
   landing directly in the shared camera account with exactly the granted role and scope.
4. Priya can see the invitation move from "pending" to "active" once accepted.

**What the user expects:** inviting someone and deciding exactly what they can do is one
smooth flow, not a separate account-creation step and a separate permissions step.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an owner invite a new person by phone number or email and
  assign a specific role and scope as part of the same invitation.
- **[mobile-app]** The app shall show the invitation's status (pending, accepted) to the
  inviting owner.

## Scenario: Invitee doesn't have the app yet

**Scenario ID:** SCN-568
**Feature ID:** FEAT-156

**Persona:** Priya's daughter, who has never installed the camera app before, receiving the
invitation.

1. The daughter gets an SMS with an invitation link.
2. Tapping the link takes her to install the app first (if not already installed), then
   straight into accepting the specific invitation waiting for her, rather than a generic
   sign-up flow disconnected from the invite.
3. Once she accepts, she's granted exactly the role/scope Priya set — no separate manual step
   for Priya to redo the grant after her daughter creates an account.

**What the user expects:** a new user gets from "received an invite" to "using it" in one
continuous flow, even if they start with nothing installed.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall carry an invitation through app installation and account
  creation, so a brand-new user lands directly on accepting the specific pending invitation
  rather than a disconnected generic sign-up.

## Scenario: Owner cancels a pending invitation sent to the wrong contact

**Scenario ID:** SCN-569
**Feature ID:** FEAT-156

**Persona:** Priya, realizing she typo'd a phone number and the invitation went to the wrong
person.

1. Priya notices the invitation is still "pending" and the wrong recipient hasn't accepted it.
2. She cancels the pending invitation from her access-management screen.
3. If the wrong recipient later tries to tap the (still-received) invitation link, it's
   rejected as no longer valid.
4. Priya then sends a corrected invitation to the right phone number.

**What the user expects:** a mistaken invite can be undone before it's accepted, cleanly,
without contacting support.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an owner cancel a pending (not-yet-accepted) invitation,
  immediately invalidating its link/token.
</content>
