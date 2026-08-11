---
feature_id: FEAT-157
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Current Access Roster

Covers the VMS side of FEAT-157: a live list of everyone currently granted access to a
site/camera, showing each person's role and scope.

## Scenario: Admin views the current roster for a site

**Scenario ID:** SCN-574
**Feature ID:** FEAT-157

**Persona:** Farid, doing a routine access review for one of his sites.

1. Farid opens the site's roster and sees every user with active access, their role, and their
   camera scope within that site.
2. He notices a former contractor's Support Technician grant is still listed as active, past
   when their project ended (their time-bounded grant hadn't been set correctly), and revokes
   it directly from the roster.

**What the user expects:** a single place to see, and immediately act on, exactly who has
access to a given site right now.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a roster view listing every user currently granted access to
  a site, with their role and camera scope, for authorized admins.
- **[vms]** The VMS shall allow revoking access directly from the roster view.

## Scenario: Roster highlights stale/inactive grants for review

**Scenario ID:** SCN-575
**Feature ID:** FEAT-157

**Persona:** Farid, during a quarterly access audit across his organization.

1. Farid opens the roster and sees an indicator next to users who haven't logged in for an
   extended period (e.g. 90+ days), distinct from actively-used grants.
2. He reviews those flagged entries specifically, since a stale grant nobody's used in months
   is a more likely candidate for cleanup than one used yesterday.
3. He revokes a couple of long-unused Support Technician grants directly from this flagged
   view.

**What the user expects:** the roster doesn't just list access — it helps him spot the entries
most worth a second look during a periodic review.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall indicate in the roster when a user's access has gone unused for an
  extended, configurable period, distinguishing it from recently-active access.
</content>
