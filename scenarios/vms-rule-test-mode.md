---
feature_id: FEAT-070
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md]
---

# Scenario: VMS — Installer Rule Test Mode

Covers the professional-installer side of FEAT-070: test-running a new rule during commissioning
of a multi-camera site before enabling live notifications.

## Scenario: Installer test-runs a new rule during commissioning

**Scenario ID:** SCN-249
**Feature ID:** FEAT-070

**Persona:** Theo, an installer commissioning a new camera on a community site, wanting to
verify a newly-drawn zone/rule behaves correctly before the site's operators start receiving
alerts from it.

1. Theo creates the rule in the VMS and explicitly sets it to "Test mode" rather than "Live."
2. Over the next hour, as people and vehicles move through the actual site, Theo watches the
   test-event log build up in real time in the VMS, confirming trigger timing and zone
   boundaries look right.
3. Satisfied, Theo switches the rule to "Live," and from that point on the site's configured
   notification recipients start receiving real alerts.

**What the user expects:** he can validate a rule against real, live site activity during
commissioning without spamming the site's actual operators with test alerts.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an installer/operator explicitly set a newly-created rule to
  "Test mode" at creation time, and shall route test-mode events only to the VMS's own test log
  view, never to the site's configured live-notification recipients.
- **[camera-firmware]** The camera shall report a distinct event type/flag for test-mode
  trigger events, so downstream systems (VMS, alert relay) can reliably distinguish them from
  live-rule events without relying on client-side filtering alone.

## Scenario: Test-mode events reviewed and used to adjust the rule before going live

**Scenario ID:** SCN-250
**Feature ID:** FEAT-070

**Persona:** Theo, reviewing the test-event log from the previous scenario and noticing the
zone is triggering on pedestrians on the adjacent public sidewalk, just outside the intended
property line.

1. Theo reviews the test log entries and their linked snapshots, spotting several triggered by
   sidewalk pedestrians rather than actual property activity.
2. He goes back to the zone drawing, tightens the boundary to exclude the sidewalk, and saves.
3. He resumes test mode with the corrected zone, confirms the false triggers stop, and only
   then switches the rule to Live.

**What the user expects:** test mode isn't just a one-time gate — he can iterate on the rule
using real evidence from the test log until it's actually tuned correctly, all before it ever
reaches a live notification.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator inspect each test-mode-triggered event's linked
  snapshot/clip from the test log, and shall allow editing the rule's zone/schedule/class
  filter while it remains in test mode, re-evaluating subsequent activity against the updated
  configuration without needing to recreate the rule.
