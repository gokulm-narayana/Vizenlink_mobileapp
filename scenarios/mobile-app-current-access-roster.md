---
feature_id: FEAT-157
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Current Access Roster

Covers the mobile-app side of FEAT-157: a live list of everyone currently granted access to a
site/camera, showing each person's role and scope.

## Scenario: Owner views everyone with current access to the home cameras

**Scenario ID:** SCN-572
**Feature ID:** FEAT-157

**Persona:** Priya, doing an occasional check of who currently has access to her cameras.

1. Priya opens "Who has access" and sees a roster listing every person currently granted
   access, each with their role (Owner, Family Viewer, Temporary Guest) and their camera scope.
2. She spots her house-sitter from months ago still listed with active Temporary Guest access
   she forgot to revoke, and removes them directly from this roster view.
3. The roster updates immediately once she removes them.

**What the user expects:** a single, current, trustworthy list of exactly who can see her
cameras right now, from which she can act directly.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a roster view listing every person currently granted
  access to a site/camera, with their role and scope shown, for the owner/admin.
- **[mobile-app]** The app shall allow revoking access directly from the roster view.

## Scenario: Roster stays accurate immediately after a change, and can be filtered

**Scenario ID:** SCN-573
**Feature ID:** FEAT-157

**Persona:** Priya, right after revoking the house-sitter above, checking the roster reflects
it correctly and filtering it by a specific camera.

1. Priya refreshes the roster and confirms the house-sitter no longer appears at all.
2. She filters the roster to just the backyard camera and sees only the people actually scoped
   to that camera, not everyone with access to the whole property.

**What the user expects:** the roster is never stale — it reflects grants and revocations the
moment they happen, and can be narrowed to a specific camera when the property has more than
one.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall reflect a grant or revocation in the roster view immediately,
  without requiring a manual data refresh beyond opening/reloading the screen.
- **[mobile-app]** The app shall let the roster be filtered by camera, so scope-specific access
  can be reviewed at a glance.
</content>
