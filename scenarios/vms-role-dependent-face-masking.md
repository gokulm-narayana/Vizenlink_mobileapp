---
feature_id: FEAT-193
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md, FR-security-lifecycle.md]
---

# Scenario: VMS — Role-Dependent Face Masking for Shared/Public Views

Covers FEAT-193: dynamically masking/blurring detected faces for certain roles or shared/
public-facing views (e.g. a community lobby display), while leaving faces unmasked for roles
with full investigative access.

## Scenario: A public lobby display shows masked faces

**Scenario ID:** SCN-637
**Feature ID:** FEAT-193

**Persona:** A community management office runs a live camera feed on a lobby TV, viewable by
any resident or visitor walking past.

1. The lobby display is configured in VMS as a "Public View" for that camera's feed.
2. Faces of anyone in frame are automatically detected and blurred/masked in real time on this
   display, while the rest of the scene (movement, general activity) remains visible.
3. A property manager checking the same camera through their own authenticated VMS session, with
   full-access role, sees the same feed unmasked.

**What the user expects:** the public display gives useful situational visibility (is the lobby
busy, is there an obstruction) without exposing identifiable faces of everyone who walks by to
anyone glancing at a TV in a public area.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support configuring a camera feed as a masked "Public View" in which
  detected faces are blurred/masked in real time, independent of the same feed's unmasked
  presentation to full-access roles.
- **[vms]** Face masking shall be applied per viewing context (role/view configuration), not as
  a single global toggle that would also mask the feed for investigative access.

## Scenario: An incident requires unmasking for authorized investigation

**Scenario ID:** SCN-638
**Feature ID:** FEAT-193

**Persona:** After a reported incident in the lobby, a community admin needs to review the
original, unmasked footage for the relevant time window.

1. The admin, using a role with investigative access, opens the recorded footage for that
   window directly (not through the public-view path) and sees it unmasked, as their role
   permits.
2. Accessing the unmasked footage for this purpose is itself audit-logged (per FEAT-192), since
   it's sensitive-data access.

**What the user expects:** masking protects casual public visibility without ever preventing a
legitimate, authorized investigation from seeing what actually happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let a role with investigative-access permission view recorded footage
  unmasked regardless of whether that same feed has a masked public-view configuration.
- **[vms]** Unmasked access to footage that has a masked public-view configuration shall be
  audit-logged as sensitive-data access.

## Scenario: Face detection/masking fails or lags on a public view

**Scenario ID:** SCN-639
**Feature ID:** FEAT-193

**Persona:** A resident happens to notice, on the lobby display, a moment where a face appears
briefly unmasked before the blur catches up.

1. If the masking pipeline cannot keep up with a fast-moving subject or momentarily fails, the
   public-view display does not silently fall back to showing the raw, unmasked feed — it
   either maintains the last-known mask region, freezes/blanks briefly, or drops that view
   rather than exposing an unmasked face.

**What the user expects:** a masking failure degrades toward "less useful" (a frozen or blanked
frame), never toward "accidentally exposes what it was supposed to protect."

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The public-view masking pipeline shall fail closed — on a masking failure or
  processing lag, the public view shall not display an unmasked frame; it shall hold the last
  masked state, blank, or drop the frame instead.
