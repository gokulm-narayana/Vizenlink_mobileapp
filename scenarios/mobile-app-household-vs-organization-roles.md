---
feature_id: FEAT-146
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Distinct Household vs. Organization Role Models

Covers the mobile-app side of FEAT-146: a simple household role model (Owner/Family
Viewer/Temporary Guest) is kept distinct from a richer organization role model, rather than one
model stretched to cover both.

## Scenario: Homeowner grants a Family Viewer role in the simple household model

**Scenario ID:** SCN-520
**Feature ID:** FEAT-146

**Persona:** Priya, a homeowner using the mobile app on a personal residential account with two
cameras.

1. Priya opens the household's "People with access" screen.
2. She sees only the three household roles: Owner (herself), Family Viewer, and Temporary
   Guest — no organizational roles like "Security Supervisor" appear, since this is a household
   account.
3. She assigns her college-age daughter a Family Viewer role, which lets her view live and
   recorded footage but not manage anyone else's access.
4. Her daughter's app now shows exactly the fixed permission set tied to Family Viewer —
   nothing more, nothing separately configurable.

**What the user expects:** household accounts stay simple — a small, familiar set of roles,
not the complexity of an office deployment.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall present the simplified household role set (Owner, Family
  Viewer, Temporary Guest) exclusively when the account is provisioned as a household/
  residential account.
- **[mobile-app]** The app shall associate a fixed, predefined permission set with each
  household role rather than exposing granular per-permission editing, keeping the household
  model simple.

## Scenario: One user account bridges a household and an organization

**Scenario ID:** SCN-521
**Feature ID:** FEAT-146

**Persona:** Wanda, who has her own home camera under a personal household account, and also
manages a small office site's cameras as part of a property-management job.

1. Wanda opens the app and switches between "My Home" (household context) and the office site
   (organization context) via an account/site switcher.
2. Under "My Home," she only ever sees the household roles (Owner/Family Viewer/Temporary
   Guest).
3. Under the office site, she instead sees the richer organization roles (Site Owner, Security
   Supervisor, Office Manager, etc.), matching what an organization deployment actually needs.
4. The app never mixes the two role vocabularies in the same context — access management always
   uses whichever model matches the site she's currently working in.

**What the user expects:** the same login can operate in both worlds without the two role
systems bleeding into or confusing each other.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall scope which role model (household vs. organization) is
  offered per-site, based on that site's provisioning type, even when a single account has
  access to sites of both types.
- **[mobile-app]** The app shall never present a hybrid or merged role list combining household
  and organization role names within the same site's access-management screen.
</content>
