---
feature_id: FEAT-047
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Media Sharing / Share-Link Generation

Covers FEAT-047: generating a shareable URL letting a recipient download a clip/snapshot
directly from the NVR/VMS to their phone/laptop, without needing app/VMS login access —
VMS/NVR only.

## Scenario: Operator generates a share link for a clip

**Scenario ID:** SCN-163
**Feature ID:** FEAT-047

**Persona:** Marcus needs to send a neighbor a clip of their car being scraped in a shared
parking area, without giving the neighbor VMS access.

1. Marcus selects the clip and chooses "Generate Share Link."
2. He sets an expiration for the link (e.g. 48 hours) and confirms.
3. The VMS produces a URL that Marcus copies and sends however he likes (text, email); opening
   it requires no VMS login or app install — just the link.
4. The recipient opens the link and can view/download the clip directly.

**What the user expects:** sharing a clip with someone outside the system is as easy as sending
a link, with no account friction on their end.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall generate a shareable URL for a selected clip/snapshot, requiring no
  VMS login or app install for the recipient to view/download it.
- **[vms]** The VMS shall let the operator set an expiration duration when generating a share
  link.

## Scenario: Share link expiration/revocation

**Scenario ID:** SCN-164
**Feature ID:** FEAT-047

**Persona:** Priya generated a share link earlier and now wants to shut it off early, before its
set expiration, since the situation it was for is resolved.

1. Priya opens the list of active share links for her site.
2. She finds the link and revokes it manually.
3. The VMS confirms the link is now inactive immediately, ahead of its original expiration.
4. Separately, any link Priya never revokes still stops working automatically once its
   expiration passes.

**What the user expects:** she isn't stuck waiting out a link's original expiration if she wants
to cut off access sooner, and forgotten links don't stay open forever by default.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a list of active share links per site and allow an operator to
  manually revoke any link before its expiration.
- **[vms]** The VMS shall automatically deactivate a share link once its set expiration passes.

## Scenario: Recipient tries an expired or revoked link

**Scenario ID:** SCN-165
**Feature ID:** FEAT-047

**Persona:** A recipient who received a share link days ago tries to open it after it has
expired.

1. The recipient opens the link.
2. The VMS shows a clear "this link has expired/is no longer available" message rather than an
   opaque error or, worse, silently serving the content anyway.
3. No clip content is ever served once a link is expired or revoked, regardless of how the
   request is retried.

**What the user expects:** an expired or revoked link is a hard stop — the recipient gets a
clear reason, and the content is genuinely no longer reachable through it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall reject any request against an expired or revoked share link, serving
  no clip content, and shall display a clear explanatory message rather than a generic error.
