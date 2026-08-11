---
feature_id: FEAT-148
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Per-Site and Per-Camera Access Scope

Covers the mobile-app side of FEAT-148: a role assignment can be scoped to specific sites and,
within a site, to a subset of cameras — not just one global role per account.

## Scenario: Homeowner limits a Family Viewer to specific cameras

**Scenario ID:** SCN-529
**Feature ID:** FEAT-148

**Persona:** Raj, who owns a home with 4 cameras (front door, backyard, garage, and a bedroom
baby monitor), granting his teenage nephew occasional access.

1. Raj opens access management and selects his nephew's Family Viewer grant.
2. Instead of granting access to all 4 cameras, Raj scopes the grant to just the front-door and
   backyard cameras, leaving the garage and bedroom camera untouched.
3. The nephew's app only ever shows the front-door and backyard cameras in his camera list —
   the other two don't appear at all, not even as disabled "no access" placeholders that hint
   at their existence.
4. If Raj later adds another camera to the property, it also isn't visible to the nephew unless
   Raj deliberately adds it to the scope.

**What the user expects:** access can be limited to only the cameras that make sense for a
given person, not all-or-nothing for the whole property.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall allow a role assignment to be scoped to a specific subset of
  a site's cameras, not just a single global grant covering every camera at the site.
- **[mobile-app]** The app shall omit cameras outside a user's granted scope from their camera
  list entirely, rather than showing them in a disabled/no-access state that reveals their
  existence.

## Scenario: A guest tries to reach a camera outside their granted site

**Scenario ID:** SCN-530
**Feature ID:** FEAT-148

**Persona:** Priya, whose account manages two family properties; she has granted her
house-sitter access only to her own home's cameras, not to her parents' separate property on
the same account.

1. The house-sitter opens the app and sees only Priya's home's cameras — her parents' site and
   its cameras don't appear in the house-sitter's camera list at all.
2. If the house-sitter somehow obtains a direct link/ID for one of the parents' cameras (e.g.
   shared by mistake), the app rejects the request rather than opening the stream, since that
   camera is outside the site scope granted to this account.

**What the user expects:** scoping isn't just a UI convenience — access to an out-of-scope
site/camera is actually blocked, not merely unlisted.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall enforce site-level access scope at the backend, rejecting a
  direct request for a camera outside the user's granted site(s) even if the camera ID is
  somehow obtained.
- **[cloud-components]** The authorization backend shall validate site/camera scope on every
  session request, rather than relying on the app to simply not display out-of-scope cameras.
</content>
