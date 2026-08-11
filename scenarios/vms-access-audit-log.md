---
feature_id: FEAT-150
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Access/Configuration Change Audit Log

Covers the VMS side of FEAT-150: every grant, permission change, revocation, export, deletion,
and other high-impact configuration action is logged, attributed and timestamped, and cannot be
tampered with — including by administrators.

## Scenario: Org admin reviews the site's full audit trail

**Scenario ID:** SCN-541
**Feature ID:** FEAT-150

**Persona:** Farid, investigating a recent unexplained settings change on one of his site's
cameras.

1. Farid opens the VMS's audit log for his organization's site.
2. He filters by the specific camera and finds an entry showing a rule-configuration change,
   attributed to a specific Security Operator account, timestamped to the exact time in
   question.
3. He also sees separate entries for a recent access grant, an export, and a permission change,
   all similarly attributed and timestamped.
4. He's able to export or share this log with his compliance team when needed.

**What the user expects:** any high-impact action on his site is traceable to exactly who did
it and when, without having to ask around.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall log every grant, permission change, revocation, export, deletion, and
  other high-impact configuration action, attributed to the acting user and timestamped.
- **[vms]** The VMS shall allow filtering/searching the audit log by camera, user, action type,
  and time range.

## Scenario: An administrator's own actions are logged with no exemption

**Scenario ID:** SCN-542
**Feature ID:** FEAT-150

**Persona:** Farid himself, making a broad-scope access grant directly as the Site Owner.

1. Farid, using his own Site Owner account, grants a new hire access to two cameras.
2. This action appears in the audit log exactly like any other user's action would —
   attributed to Farid's own account, timestamped, with no special "admin action, not logged"
   exemption.
3. Later, if Farid's own access decisions are questioned (e.g. during a compliance review), the
   log provides the same evidentiary record for him as for anyone else.

**What the user expects:** nobody, including the most senior admin, is invisible to the audit
trail.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall log administrator/owner-level actions in the same audit trail with
  the same attribution as any other user's actions, with no built-in exemption for
  high-privilege accounts.

## Scenario: An attempt to tamper with or delete audit log entries is rejected

**Scenario ID:** SCN-543
**Feature ID:** FEAT-150

**Persona:** A disgruntled former Security Supervisor who briefly still has console access,
attempting to erase evidence of an improper broad access grant made just before being demoted.

1. The user, prior to their access change taking effect, tries to find a way to edit or delete
   their own earlier audit log entry.
2. The VMS provides no UI path to modify or delete any audit log entry, for any role including
   their former Security Supervisor role.
3. If they attempt a direct API call to delete an entry, the backend rejects it, since the
   audit log is append-only by design.
4. Their attempt to tamper is itself recorded as a new audit entry (the attempt, not a
   modification of the old one).

**What the user expects:** the audit trail is trustworthy specifically because no one, however
privileged, can quietly rewrite history.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall implement the audit log as append-only, providing no interface (UI or
  API) capable of editing or deleting an existing entry, regardless of role.
- **[vms]** The VMS shall log an attempted modification/deletion of an audit entry as its own
  new audit entry, rather than allowing it to silently fail with no record.
</content>
