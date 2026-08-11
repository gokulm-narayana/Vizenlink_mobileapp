---
feature_id: FEAT-149
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Prompt Access Revocation

Covers the mobile-app side of FEAT-149: revoking a user's access takes effect immediately —
an in-progress live-view/playback session is terminated, not merely blocked for new sessions.

## Scenario: Owner revokes a Family Viewer's access mid live-view

**Scenario ID:** SCN-534
**Feature ID:** FEAT-149

**Persona:** Nadia, a homeowner, revoking her ex-partner's access to the home cameras after a
change in living arrangements, while he still has live view open on his phone.

1. Nadia opens access management and removes her ex-partner's access entirely.
2. At the exact moment she confirms the revocation, his live-view session — already open and
   playing — is terminated on his device, not just blocked for future connections.
3. His app shows a clear message that his access has been revoked, rather than the stream
   simply freezing or erroring out unexplained.
4. Any attempt to reopen the camera afterward is rejected immediately.

**What the user expects:** revoking access takes effect right now, not "the next time they try
to connect."

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall immediately terminate any active live-view (or other) session
  for a user whose access has just been revoked, rather than allowing the in-progress session
  to continue.
- **[mobile-app]** The app shall show the affected user an explicit "access revoked" message
  rather than a generic error when their live session is terminated this way.
- **[cloud-components]** The authorization/session layer shall receive an immediate
  session-termination signal the moment a revocation is recorded, rather than waiting for the
  next periodic re-check.

## Scenario: Revoking a guest mid-export/mid-playback

**Scenario ID:** SCN-535
**Feature ID:** FEAT-149

**Persona:** A homeowner revoking a temporary guest's access while the guest is exporting a
clip.

1. The guest starts exporting a clip from playback.
2. The homeowner revokes the guest's access before the export finishes.
3. The export is halted immediately rather than allowed to finish, and the guest's playback
   session closes as well.
4. Anything already fully saved to the guest's device before the revocation stays with them —
   revocation stops new access, it doesn't reach into their device to delete a locally-saved
   file — but no further data can be pulled.

**What the user expects:** an in-progress action is stopped by revocation, not grandfathered in
until it naturally finishes.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall stop an in-progress playback or export session immediately
  upon the acting user's access being revoked mid-session.

## Scenario: A revoked user was offline at the moment of revocation

**Scenario ID:** SCN-536
**Feature ID:** FEAT-149

**Persona:** A Temporary Guest whose phone was off/offline when the homeowner revoked their
access; the guest later turns their phone back on and opens the app.

1. While the guest's phone is off, the homeowner revokes their access.
2. Later the guest turns their phone on, and the app, still holding a previously cached
   session, tries to reconnect to the camera.
3. The reconnect attempt is rejected at the backend, since the revocation already took effect —
   the guest sees an "access revoked" state, not stale cached camera tiles that still appear
   reachable.
4. The camera itself never grants a session to the reconnecting guest.

**What the user expects:** being offline at the moment of revocation doesn't create a loophole
— the block is enforced the moment they try to reconnect, regardless of when the revocation
actually happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall re-validate access authorization on reconnect/app-foreground
  rather than trusting a previously cached session state, so an offline user's revoked access
  is caught the moment they come back online.
- **[cloud-components]** The authorization backend shall persist a revocation immediately and
  reject any subsequent session/reconnect attempt from the revoked user, regardless of how
  much time passed since the revocation.
</content>
