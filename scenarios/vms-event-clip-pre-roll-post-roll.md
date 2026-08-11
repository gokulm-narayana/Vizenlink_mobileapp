---
feature_id: FEAT-036
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Event Clip Pre-Roll/Post-Roll

Covers the fleet-operator-facing side of FEAT-036: event-triggered NVR clips including
configurable pre-roll/post-roll buffer time, viewed and configured from the VMS.

## Scenario: Reviewing an NVR-side event clip's pre/post-roll boundaries

**Scenario ID:** SCN-125
**Feature ID:** FEAT-036

**Persona:** Marcus reviews an event clip on the VMS after a line-crossing rule fires on a
perimeter camera.

1. Marcus opens the event from the VMS's event log.
2. The clip playback includes the 5s pre-roll and 10s post-roll padding around the rule's
   trigger moment, with the trigger moment itself marked on the scrub bar.
3. Marcus can jump directly to the trigger moment, or watch the full padded clip from the start.

**What the user expects:** he gets full context around any flagged event without having to dig
up the surrounding continuous footage separately.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS event log's clip playback shall include pre-roll and post-roll padding
  around the trigger moment, with a scrub-bar marker distinguishing the trigger moment from the
  padding.
- **[vms]** The VMS shall let an operator jump directly to the trigger moment within a padded
  clip.

## Scenario: Configuring pre-roll/post-roll per camera or per rule at fleet level

**Scenario ID:** SCN-126
**Feature ID:** FEAT-036

**Persona:** Priya manages a multi-camera community site and wants a longer post-roll on
entrance cameras than on general perimeter cameras.

1. Priya opens recording settings for the entrance camera group and sets a longer post-roll
   duration than the site default.
2. The VMS applies the override to just that group, leaving other cameras on the site default.
3. The VMS's settings view shows, per camera or group, whether it's using the site default or a
   camera/group-specific override.

**What the user expects:** she can tune padding differently for different parts of the site
without having to configure every camera individually or lose track of which ones are
customized.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow pre-roll/post-roll duration to be configured at site-default,
  group, or per-camera scope, with a narrower scope overriding a broader one.
- **[vms]** The VMS shall indicate, per camera, whether its current pre-roll/post-roll setting
  is inherited from a broader scope or overridden locally.
