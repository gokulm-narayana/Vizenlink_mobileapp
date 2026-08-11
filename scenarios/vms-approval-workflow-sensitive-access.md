---
feature_id: FEAT-154
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Approval Workflow for Sensitive Export/Broad Access

Covers the VMS side of FEAT-154: a sensitive export or a broad-scope access grant requires a
second approver's sign-off before taking effect.

## Scenario: An operator's large export request requires supervisor sign-off

**Scenario ID:** SCN-560
**Feature ID:** FEAT-154

**Persona:** Jamie, a Security Operator, needing to export a full day's footage from several
cameras for a legal request.

1. Jamie initiates an export spanning multiple cameras and a full day — flagged by the VMS as
   a "sensitive" export because of its scope.
2. Instead of starting immediately, the export request is submitted to Jamie's Security
   Supervisor for approval.
3. The Supervisor reviews exactly what's being requested (cameras, time range, reason if
   provided) and approves it.
4. Only after approval does the export actually begin.

**What the user expects:** large, sensitive exports get a second set of eyes before they
happen, not after.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall flag an export request as sensitive when it exceeds configured
  scope/size thresholds (e.g. multiple cameras, long duration), and route it through supervisor
  approval before it starts.
- **[vms]** The VMS shall block the export from starting until the approval decision is
  recorded.

## Scenario: An approval request goes unanswered and times out

**Scenario ID:** SCN-561
**Feature ID:** FEAT-154

**Persona:** Jamie, again, whose export approval request sits unanswered because the
Supervisor is on leave.

1. Jamie's export request sits pending for longer than the configured approval window (e.g. 48
   hours).
2. Once that window passes without a decision, the VMS marks the request as expired rather than
   leaving it pending indefinitely or auto-approving it.
3. Jamie is notified the request expired without a decision and can resubmit it (e.g. to a
   different available supervisor).

**What the user expects:** a stuck approval doesn't silently vanish or silently auto-approve —
it times out visibly, with a clear path to try again.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expire a pending sensitive-action approval request after a configured
  time window if no decision is recorded, rather than leaving it open indefinitely or
  defaulting to approved.
- **[vms]** The VMS shall notify the requester when their request expires unanswered, and shall
  allow resubmission.

## Scenario: A broad-scope access grant across all sites requires a second approver

**Scenario ID:** SCN-562
**Feature ID:** FEAT-154

**Persona:** Farid, proposing to grant a new regional manager access across all three of the
organization's sites at once.

1. Farid, even as a Site Owner, submits a request to grant all-sites access to the new manager.
2. Because this spans every site in the organization (a broad-scope grant), the VMS requires
   sign-off from another authorized approver (e.g. a second Site Owner or a designated org-level
   approver) before the grant takes effect.
3. The second approver reviews and confirms the request, and only then does the manager's
   access become active across all three sites.

**What the user expects:** even a founding-level admin doesn't get to unilaterally hand out
organization-wide access without another person confirming it makes sense.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall require a second approver's sign-off for any grant whose scope spans
  multiple/all sites in an organization, regardless of the requester's own privilege level.
- **[vms]** The VMS shall record the approval chain (requester, approver, decision, timestamp)
  for any sensitive access grant in the audit log.
</content>
