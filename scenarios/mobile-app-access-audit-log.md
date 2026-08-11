---
feature_id: FEAT-150
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Access/Configuration Change Audit Log

Covers the mobile-app side of FEAT-150: every grant, permission change, revocation, export,
deletion, and other high-impact configuration action is logged, attributed to the acting user
and timestamped.

## Scenario: Homeowner reviews who granted/changed what

**Scenario ID:** SCN-539
**Feature ID:** FEAT-150

**Persona:** Nadia, reviewing her household account's access history after noticing an
unfamiliar person had briefly had access.

1. Nadia opens an "Access history" / "Activity log" screen in the app.
2. She sees a chronological list: who was granted access and when, whose permissions were
   changed, and who was revoked — each entry attributed to the specific person who performed
   the action and timestamped.
3. She finds the entry showing a former guest was granted access three weeks ago by her spouse,
   explaining the unfamiliar name.
4. The log doesn't let her edit or delete any historical entries — it's a read-only record.

**What the user expects:** she can always answer "who did this and when" for anything affecting
who can see her cameras.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide an activity/audit log, visible to the account owner,
  listing every grant, permission change, and revocation, attributed to the acting user and
  timestamped.
- **[mobile-app]** The app shall present the audit log as read-only — no in-app control to edit
  or delete historical entries.

## Scenario: A clip export and deletion are logged distinctly from automatic retention deletion

**Scenario ID:** SCN-540
**Feature ID:** FEAT-150

**Persona:** Nadia, checking whether a particular clip was deliberately deleted by a family
member or simply aged out by the camera's normal retention policy.

1. Nadia notices an old clip she expected to still exist is gone, and checks the audit log.
2. She finds the clip was manually exported (and by whom) two days before it disappeared, and
   separately, its later removal is logged as "deleted by [family member's name]," not as an
   automatic retention purge.
3. Had it instead been removed automatically because it aged past the retention window, the log
   would show that as a distinct system-attributed entry rather than implying a person did it.

**What the user expects:** the log can tell deliberate human actions apart from routine
automatic housekeeping.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall log manual clip export and manual clip deletion as distinct,
  user-attributed audit entries.
- **[mobile-app]** The app shall log automatic/retention-driven deletions as system-attributed
  entries, distinguishable from a user-initiated deletion.
</content>
