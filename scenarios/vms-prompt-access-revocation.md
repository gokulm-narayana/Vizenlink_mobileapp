---
feature_id: FEAT-149
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Prompt Access Revocation

Covers the VMS side of FEAT-149: revoking a user's access takes effect immediately at the
backend/NVR authorization point.

## Scenario: Admin revokes an operator's access while multiple tiles are open

**Scenario ID:** SCN-537
**Feature ID:** FEAT-149

**Persona:** Farid, revoking a departing operator's VMS access while that operator still has a
multi-camera dashboard open in their browser.

1. Farid removes the operator's account access from the VMS user management panel.
2. All of the operator's currently open camera tiles across their dashboard go dark/locked
   within moments, not just the next time they try to open a new one.
3. The operator's browser shows a clear "access revoked" state rather than tiles simply failing
   to load with a vague error.

**What the user expects:** a revocation immediately clears every currently active view for
that user, not just gates future logins.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall terminate all of a user's currently active sessions/tiles across the
  entire dashboard immediately when their access is revoked, not only when they next attempt to
  open something new.

## Scenario: A revoked operator's already-authenticated session token is reused

**Scenario ID:** SCN-538
**Feature ID:** FEAT-149

**Persona:** The same departing operator, whose browser still holds a valid-looking session
token/cookie from before the revocation, refreshing the page after being revoked.

1. Farid revokes the operator's access.
2. The operator (or someone using their still-logged-in browser) reloads the VMS page.
3. Despite the browser still holding what looks like a valid session, the backend rejects every
   request associated with that session, forcing a re-login that will also fail since the
   account itself is revoked.

**What the user expects:** revocation invalidates the session at the backend, not just the
frontend UI state — a stale token can't be used to keep working.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall invalidate the backend session/token immediately upon revocation, so
  a client holding a stale but previously-valid session cannot continue to make authorized
  requests.
</content>
