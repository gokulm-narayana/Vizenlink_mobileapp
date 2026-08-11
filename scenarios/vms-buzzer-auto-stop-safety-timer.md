---
feature_id: FEAT-027
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Buzzer Auto-Stop Safety Timer & Status Query

Covers the fleet-operator-facing side of FEAT-027 (Buzzer Auto-Stop Safety Timer & Status Query):
monitoring and controlling buzzer state across a site's cameras, including buzzer activations
triggered locally at the camera or by a security rule rather than only remotely.

## Scenario: Operator sees a locally-triggered buzzer active on the fleet view

**Scenario ID:** SCN-079
**Feature ID:** FEAT-027

**Persona:** Marcus notices, while reviewing the site's fleet status view, that one camera's
buzzer is currently active even though no operator triggered it remotely — it was activated by a
person pressing a local confirm button at the camera itself.

1. Marcus sees the camera flagged as having an active buzzer in the fleet view.
2. He can immediately stop it from the VMS if needed, even though it wasn't remotely triggered in
   the first place.
3. The fleet view also shows this activation's source (local trigger) so he understands it wasn't
   a VMS-issued command.

**What the user expects:** buzzer status and stop control work uniformly regardless of how the
buzzer was originally triggered — locally, by a rule, or remotely — since he's responsible for the
whole site's behavior either way.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS fleet view shall show buzzer active/inactive status per camera regardless of
  what triggered the current activation (remote, local, or rule-based), and provide an
  immediate-stop control for it.
- **[camera-firmware]** The camera shall report buzzer status and accept a stop command uniformly
  regardless of the activation's original trigger source (local button, rule, or remote command).

## Scenario: Repeated rule-triggered activations don't stack into an extended buzzer run

**Scenario ID:** SCN-080
**Feature ID:** FEAT-027

**Persona:** Marcus reviews a site where a security rule keeps re-triggering a camera's buzzer as
a detection condition repeatedly re-fires (e.g. continuous motion in a restricted zone).

1. Marcus checks the fleet view during a period of repeated rule-triggered activations and
   confirms the buzzer's active duration is still bounded to one countdown window at a time, not
   growing longer with each re-trigger.
2. He can see, from the activity log, that repeated triggers restarted rather than extended the
   countdown.

**What the user expects:** a mis-tuned or repeatedly-firing rule can never cause the buzzer to run
effectively continuously by chaining together stacked activations.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS activity log shall record each buzzer re-trigger during an already-active
  window as a countdown restart, not a duration extension, so an operator reviewing the log can
  confirm the bounded-duration guarantee held.
