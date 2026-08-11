---
feature_id: FEAT-082
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md]
---

# Scenario: VMS — Per-Rule Enable/Disable Toggle

Covers the fleet-operator side of FEAT-082: disabling an individual rule during a known
false-positive situation, and keeping its status clearly distinguishable in the rule list.

## Scenario: Operator disables a rule during a known false-positive event

**Scenario ID:** SCN-282
**Feature ID:** FEAT-082

**Persona:** Dana, whose loading-dock parking-duration rule would fire constantly during a
week of scheduled construction work with vehicles legitimately parked long-term in that zone.

1. Dana opens the rule and toggles it off for the duration of the construction work, rather
   than deleting it or editing its schedule.
2. The VMS confirms the rule is now disabled and stops generating alerts from it, while every
   other rule on the site continues operating.
3. Once construction wraps up, Dana toggles the rule back on, and it resumes with its original
   configuration exactly as it was.

**What the user expects:** she has a clean way to silence one rule for a known, temporary
reason across a whole site's worth of rules, without touching anything else or losing the
rule's setup.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a per-rule enable/disable toggle usable independently on any
  rule across a multi-camera site, with disabling one rule having no effect on any other rule's
  configuration or active state.

## Scenario: Disabled status is clearly distinct from schedule-inactive in the rule list

**Scenario ID:** SCN-283
**Feature ID:** FEAT-082

**Persona:** Dana, scanning a site's full rule list where some rules are manually disabled,
some are simply outside their scheduled active hours right now, and none are deleted.

1. Dana opens the site's rule list, which shows every rule with a status indicator.
2. Manually-disabled rules are shown with a distinct label/icon (e.g. "Disabled") separate from
   rules that are merely currently outside their schedule window (e.g. "Inactive — outside
   schedule").
3. Dana can tell at a glance, without opening each rule individually, which ones she
   deliberately turned off versus which are just quiet because of the time of day.

**What the user expects:** managing many rules across a site requires being able to
distinguish "I turned this off on purpose" from "this just isn't in its active window right
now" without extra digging.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS's rule list shall display a manually-disabled rule with a status indicator
  visually distinct from a rule that is schedule-inactive, so an operator scanning many rules
  across a site can tell the two states apart without opening each rule's detail view.
