---
feature_id: FEAT-120
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Admin Configuration of Notification Preferences

Covers the VMS admin-config angle of FEAT-120: the VMS has no push channel of its own, so its
role is letting an administrator configure who/what gets notified via the mobile app, on behalf
of a team.

## Scenario: Admin sets up notification routing for the team

**Scenario ID:** SCN-446
**Feature ID:** FEAT-120

**Persona:** Diane, a site administrator, wants to make sure the overnight operator gets every
high-severity alert, while other staff only get alerts for their own assigned cameras.

1. Diane opens an admin notification-routing screen in the VMS and, per operator account,
   configures which cameras, event types, and severities that operator's mobile app should
   notify them for.
2. Diane saves the configuration; the affected operators' mobile apps reflect the new routing
   the next time a qualifying event occurs, without those operators having to change anything
   themselves.

**What the user expects:** as an administrator, she can centrally control who gets notified
about what, rather than relying on every individual staff member to configure it correctly on
their own phone.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an administrator configure per-operator notification routing
  (camera, event type, severity) that governs what that operator's mobile app delivers as push
  notifications.
- **[access-control]** Admin-set notification routing shall be restricted to users holding an
  administrative role, distinct from an individual operator's own personal preference controls.
- **[cloud-components]** Admin-configured routing rules shall be applied by the same
  notification-routing layer that evaluates individual user preferences, with a documented
  precedence when both an admin rule and a personal preference could apply to the same
  operator.

## Scenario: Admin bulk-configures notification routing for a newly onboarded site

**Scenario ID:** SCN-447
**Feature ID:** FEAT-120

**Persona:** Diane's organization just onboarded a new community site with a dozen cameras and
several new operator accounts.

1. Rather than configuring each operator-camera pairing individually, Diane applies a single
   routing template (e.g. "all overnight-shift operators get high-severity alerts for every
   camera at this site") across the whole new site in one action.
2. She can later override an individual operator's routing without disturbing the template
   applied to the rest of the site's team.

**What the user expects:** onboarding a new site's notification routing doesn't require
repetitive one-by-one configuration.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an administrator apply a notification-routing template across
  multiple operators/cameras at a site in a single action.
- **[vms]** An individually overridden operator's routing shall persist independently of later
  changes to the site-wide template it was originally derived from.
