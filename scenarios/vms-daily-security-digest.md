---
feature_id: FEAT-128
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Daily Security Digest

Covers the VMS side of FEAT-128: a daily summary across a site or multi-site fleet for an
operator/administrator.

## Scenario: Administrator receives a site-wide daily digest

**Scenario ID:** SCN-485
**Feature ID:** FEAT-128

**Persona:** Diane, the site administrator, receives (or opens, on login) a daily digest
summarizing the site's confirmed activity and health status across all its cameras.

1. The digest aggregates confirmed events and health issues across every camera at the site
   (e.g. "2 confirmed incidents, 1 camera flagged low storage"), rather than requiring Diane to
   review each camera's own history individually.
2. The digest links directly into the relevant incident/health item for follow-up.

**What the user expects:** a single daily summary answers "how did the whole site do
yesterday?" without manual per-camera review.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall generate a daily digest aggregating confirmed events and health
  issues across every camera at a site (or across a selected scope), linking to each item's
  detail.
- **[vms]** The digest shall be accessible on demand (e.g. from a dashboard widget) in addition
  to any scheduled delivery, since VMS use is session-based rather than push-notification-based.

## Scenario: A multi-site operator digest highlights the site needing attention

**Scenario ID:** SCN-486
**Feature ID:** FEAT-128

**Persona:** Marcus manages several sites and wants the digest to help him triage which site to
check first each morning.

1. The digest is organized per site, with each site's summary showing its own activity and
   health counts.
2. A site with an unresolved health issue (e.g. a storage failure, per FEAT-123) is visually
   called out ahead of sites with only routine activity to report.

**What the user expects:** across many sites, the digest itself helps him prioritize where to
look first, not just list everything with equal visual weight.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The multi-site digest shall organize its summary per site and visually prioritize
  any site with an unresolved health issue ahead of sites with only routine activity.
