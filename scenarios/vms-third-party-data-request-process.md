---
feature_id: FEAT-200
status: draft
target_fr_docs: [FR-vms.md, FR-security-lifecycle.md]
---

# Scenario: VMS — Third-Party (Non-Account-Holder) Data Access/Deletion Request Process

Covers FEAT-200's real touchpoint: an admin/operator receiving and processing a request from
someone who appears in footage but doesn't hold an account (e.g. a neighbor captured on a
driveway camera) asking to see or have deleted footage of themselves.

## Scenario: An admin logs and processes a footage-deletion request from a non-account-holder

**Scenario ID:** SCN-650
**Feature ID:** FEAT-200

**Persona:** Raj receives an email from a neighbor of a homeowner in his community, asking that
footage of themselves walking past a driveway camera be deleted.

1. Raj opens a "Third-Party Data Request" intake form in VMS and logs the request: requester
   identity/contact, what they're asking for (access or deletion), and which camera/time range
   is in question.
2. VMS walks Raj through the defined process steps (verify the request is legitimate, locate the
   matching footage, take the requested action) rather than leaving it as an unstructured
   support ticket with no camera-specific tooling.
3. Once Raj takes the action (e.g. deletes the specific footage segment), VMS records the request
   as resolved with what was done and when.

**What the user expects:** there's an actual defined, trackable process for handling this kind
of request rather than relying on ad hoc judgment each time it comes up — important since these
requests come from people the product otherwise has no direct relationship with.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a structured intake and tracking flow for third-party (non-
  account-holder) data access/deletion requests, distinct from the camera owner's own recording
  management.
- **[vms]** The VMS shall record each third-party request's resolution (action taken, date) as
  an auditable record.

## Scenario: A third-party request conflicts with an active retention/legal hold

**Scenario ID:** SCN-651
**Feature ID:** FEAT-200

**Persona:** Raj receives a similar deletion request, but the footage in question is under an
active legal hold tied to an ongoing investigation.

1. When Raj attempts to action a deletion against footage under legal hold, VMS blocks the
   deletion and explains why, rather than silently permitting it (which would destroy evidence)
   or silently ignoring the request (which would leave it unresolved with no explanation).
2. Raj records the outcome (request deferred pending hold release) so the requester can be given
   an honest, specific reason rather than silence.

**What the user expects:** a legitimate privacy request doesn't get to silently override an
active legal/evidentiary hold, but it also isn't just dropped without an explanation.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall prevent deletion of footage under an active legal hold even when
  requested through the third-party data-request process, and shall surface the conflict
  explicitly to the operator handling the request.
