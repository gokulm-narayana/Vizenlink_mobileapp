---
feature_id: FEAT-153
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Time-Bounded Access Grants

Covers the VMS side of FEAT-153: an access grant for a contractor or other temporary user
automatically expires after a set duration.

## Scenario: Admin grants a contractor time-bounded access for a project's duration

**Scenario ID:** SCN-555
**Feature ID:** FEAT-153

**Persona:** Farid, bringing in an external contractor to help configure security rules for a
two-week project.

1. Farid creates the contractor's account with a role scoped to the relevant cameras, and sets
   the grant to automatically expire two weeks from the start date, matching the project
   timeline.
2. The contractor works normally for the two weeks.
3. On the day the grant expires, their access ends automatically — Farid doesn't need to
   remember to manually revoke it once the project wraps up.

**What the user expects:** temporary contractor access aligns with the actual engagement
length, without becoming a standing account someone has to remember to clean up.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an admin set an explicit expiration date/duration on a role
  assignment for a contractor or other temporary user.
- **[vms]** The VMS shall automatically expire a time-bounded grant at its set time without
  requiring manual revocation.

## Scenario: Admin extends an active time-bounded grant before it expires

**Scenario ID:** SCN-556
**Feature ID:** FEAT-153

**Persona:** Farid, whose contractor's two-week project runs long and needs another week.

1. A few days before the contractor's access is due to expire, Farid opens their grant and
   extends the expiration date by one more week.
2. The contractor's access continues uninterrupted past the original expiration date, now under
   the new one.
3. The extension itself is recorded in the audit log, distinct from the original grant.

**What the user expects:** adjusting a temporary grant's duration is a normal, supported
action, not something that requires deleting and recreating the whole assignment.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow an admin to extend or shorten an active time-bounded grant's
  expiration before it lapses, without requiring the grant to be deleted and recreated.
- **[vms]** The VMS shall log any change to a grant's expiration date as its own audit entry.

## Scenario: A grant expires while the contractor is actively viewing footage

**Scenario ID:** SCN-557
**Feature ID:** FEAT-153

**Persona:** Farid's contractor, mid-way through reviewing footage right at the moment their
time-bounded grant's expiration is reached.

1. The contractor is actively viewing a camera when their grant's expiration time passes.
2. The session is terminated at that moment, the same way an explicit revocation would
   terminate it — the contractor sees a clear "access expired" message.
3. Farid doesn't need to take any manual action for this enforcement to happen; it's driven
   purely by the previously-configured expiration.

**What the user expects:** expiration is enforced with the same immediacy as a manual
revocation — it isn't merely "no new sessions after this time" while an old one quietly
continues.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall terminate an active session immediately when its underlying grant's
  expiration is reached, with the same immediacy required for a manual revocation.
</content>
