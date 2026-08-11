---
feature_id: FEAT-147
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Per-Action Permission Enforcement

Covers the mobile-app side of FEAT-147: permissions are enforced separately per action — live
view, playback, audio, export, settings, rule configuration, user management, audit — so a
grant on one action never implicitly grants another.

## Scenario: A Family Viewer can watch live video but not export or change settings

**Scenario ID:** SCN-524
**Feature ID:** FEAT-147

**Persona:** Maria, a Family Viewer on her parents' household camera account.

1. Maria opens live view and watches the front-door camera normally.
2. She also opens recorded playback from yesterday, which works fine — her role grants
   playback access separately from live view.
3. When she looks for an "Export clip" control, it isn't offered to her at all, since her role
   wasn't granted export permission.
4. She also can't reach the camera's settings or rule-configuration screens — those controls
   simply aren't shown to her.

**What the user expects:** being able to watch video doesn't imply being able to do anything
else with the camera — each capability is its own separate permission.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall enforce each action (live view, playback, audio, export,
  settings, rule configuration, user management, audit) as an independently grantable
  permission, never implying one from another.
- **[mobile-app]** The app shall hide or disable controls for actions the current user's role
  doesn't grant, rather than showing them and rejecting the action after the fact.

## Scenario: Playback is granted but audio is not

**Scenario ID:** SCN-525
**Feature ID:** FEAT-147

**Persona:** Tomás, a temporary guest granted playback access to review a delivery from two
days ago, but not granted audio access.

1. Tomás opens the recorded clip and the video plays normally.
2. The audio track is muted/unavailable — there's no way for him to unmute it, since audio
   wasn't part of his grant.
3. The app makes clear that audio is withheld by permission (rather than appearing as a broken
   recording), so Tomás doesn't think something is wrong with the clip.

**What the user expects:** audio is treated as its own distinct permission from video
playback, not bundled in automatically.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall treat audio access as a permission independent from
  video/playback access, muting or omitting audio for a user not granted it.
- **[mobile-app]** The app shall indicate that audio is withheld by permission, rather than
  appearing as a technical fault, when a user without audio access views a clip that has audio.

## Scenario: A permission is revoked while a user is mid-action

**Scenario ID:** SCN-526
**Feature ID:** FEAT-147

**Persona:** A Family Viewer, mid-way through exporting a clip, whose export permission is
revoked by the household owner at that exact moment.

1. The Family Viewer starts exporting a recorded clip; the export begins processing.
2. The owner, from their own device, revokes the Family Viewer's export permission moments
   later.
3. The in-progress export is halted rather than allowed to complete, and the Family Viewer
   sees a message that the action could no longer be completed because their permission
   changed.
4. Any exports already completed before the revocation aren't retroactively deleted, but no new
   export can be started.

**What the user expects:** a permission change takes effect immediately, even for a currently
in-progress action, not just for the next attempt.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall halt an in-progress action (e.g. export) and surface an
  explicit message if the acting user's permission for that action is revoked mid-action,
  rather than letting it complete on stale authorization.
- **[cloud-components]** The backend authorization point shall re-validate per-action
  permission at each meaningful step of a long-running action, not only at its start, so a
  mid-action revocation takes effect immediately rather than only on the next new request.
</content>
