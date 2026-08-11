---
feature_id: FEAT-154
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Approval Workflow for Sensitive Export/Broad Access

Covers the mobile-app side of FEAT-154: a sensitive export or a broad-scope access grant
requires a second approver's sign-off before taking effect.

## Scenario: A household member requests a broad grant that needs the owner's sign-off

**Scenario ID:** SCN-558
**Feature ID:** FEAT-154

**Persona:** Priya's spouse Arjun, wanting to grant a family friend access to every camera on
their multi-camera property, rather than just one.

1. Arjun, who has some administrative rights but isn't the primary Owner, tries to grant the
   friend access to all cameras at once.
2. Because this is a broad-scope grant (all cameras, not a limited subset), the app doesn't
   apply it immediately — it submits the request for Priya's (the Owner's) approval instead.
3. Priya gets a notification describing exactly what Arjun requested — who, and what scope —
   and can approve or decline it.
4. Once Priya approves, the grant takes effect; until then, the friend has no access at all.

**What the user expects:** a request this broad doesn't take effect just because one admin
proposed it — the primary owner gets a real say before it's live.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall route a broad-scope access grant request (e.g. all-cameras
  access) through an approval step requiring sign-off from a second, higher-privilege user
  before it takes effect.
- **[mobile-app]** The app shall notify the approver with the specific requested scope and
  requester identity, and shall not apply the grant until approved.

## Scenario: A sensitive request is declined

**Scenario ID:** SCN-559
**Feature ID:** FEAT-154

**Persona:** Arjun, whose broad-scope request above is declined by Priya after she reviews it.

1. Priya reviews Arjun's request and decides the friend shouldn't have access to every camera
   (e.g. she'd rather limit it to just the driveway camera), so she declines it.
2. Arjun receives a notification that the request was declined, along with Priya's reason if
   she provided one.
3. No access was ever granted to the friend during this process — the pending request never
   took effect.
4. Arjun can submit a new, narrower request if he wants (e.g. just the driveway camera) rather
   than being permanently blocked from proposing anything further.

**What the user expects:** declining a sensitive request cleanly prevents it from ever taking
effect, and doesn't leave the requester without a path to try a more reasonable version.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let the approver decline a pending broad-scope grant/export
  request with an optional reason, ensuring the request never takes effect.
- **[mobile-app]** The app shall notify the original requester of a decline decision and any
  reason given.
</content>
