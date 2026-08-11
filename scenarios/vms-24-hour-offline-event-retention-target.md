---
feature_id: FEAT-108
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — 24-Hour Offline Event Retention Target

Covers the fleet-operator-facing side of FEAT-108: verifying and reporting on the 24-hour
retention target across a multi-camera deployment.

## Scenario: Operator validates the retention target holds under a real fleet-wide outage

**Scenario ID:** SCN-397
**Feature ID:** FEAT-108

**Persona:** Dana, an operator, wants to confirm the camera fleet actually met its documented
24-hour retention target after a 20-hour site outage.

1. Dana pulls the fleet-wide accounting report (per FEAT-106) for the outage window and confirms
   zero events were dropped across all cameras, consistent with the outage staying under the
   24-hour target.
2. She uses this confirmation as part of her own SLA reporting to her building's stakeholders,
   citing the specific target that was met.
3. She also notes each camera's actual event rate during the outage stayed within the "qualified
   event-rate test profile" the target assumes, so the confirmation is meaningful rather than a
   coincidence of low activity.

**What the user expects:** she can concretely verify, after a real outage, that the documented
retention target actually held — not just trust the spec on faith.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator cross-reference an outage's actual duration and
  per-camera event rate against the documented 24-hour retention target and qualified
  event-rate profile, to confirm whether the target was met.

## Scenario: Operator identifies a site whose typical event rate exceeds the target's assumptions

**Scenario ID:** SCN-398
**Feature ID:** FEAT-108

**Persona:** Dana manages a high-traffic retail site whose event rate is well above the
"qualified event-rate test profile" the 24-hour target assumes, and wants to know if the target
still applies there.

1. Dana finds the VMS surfaces each site's actual average event rate against the documented
   qualified profile the retention target is based on, flagging this site as above the
   assumption.
2. Because the target is an engineering figure tied to a specific assumed rate, the VMS makes
   clear that this site's *effective* offline retention window is likely shorter than 24 hours,
   rather than letting Dana assume the 24-hour figure applies universally regardless of load.
3. She uses this to set more conservative expectations for this specific site, rather than
   quoting the generic 24-hour figure.

**What the user expects:** the target's stated assumptions (a specific event-rate profile) are
visible and checkable against her site's actual conditions, so she isn't misled into promising a
number that doesn't actually apply to her busier deployment.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display a site's actual average event rate alongside the documented
  qualified event-rate profile the 24-hour retention target assumes, flagging when a site's rate
  exceeds that assumption.
