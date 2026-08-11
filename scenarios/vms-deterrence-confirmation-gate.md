---
feature_id: FEAT-024
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md, FR-security-rules-engine.md]
---

# Scenario: VMS — Deterrence with Confirmation Gate

Covers the fleet-operator-facing side of FEAT-024 (Deterrence — Siren/Spotlight/Warning with
Confirmation Gate): an operator manually triggering deterrence on a community/office camera, and
a policy-rule-gated variant for automatic triggers.

## Scenario: Operator triggers a spotlight at an intruder in a community common area

**Scenario ID:** SCN-075
**Feature ID:** FEAT-024

**Persona:** Marcus is monitoring a community site overnight and spots someone in a restricted
common area on live view.

1. Marcus selects the spotlight deterrence action for that camera in the VMS.
2. The VMS requires an explicit confirmation before sending the command, showing which camera and
   which action will be triggered.
3. He confirms, the spotlight activates, and the VMS logs the action (camera, operator, action
   type, time) as part of the site's activity record.
4. The spotlight deactivates automatically after its bounded duration, and the VMS reflects that.

**What the user expects:** he can respond quickly to something he's watching happen, with a
confirmation step that prevents an accidental trigger, and every deterrence action he takes is
recorded for later review.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall require an explicit confirmation step before sending any
  siren/spotlight/warning deterrence command, naming the target camera and action.
- **[vms]** The VMS shall log every deterrence action taken (camera, operator, action type,
  start/end time) as part of the site's activity record.
- **[camera-firmware]** The camera shall accept a deterrence command from the VMS through the same
  authorized command path used by the mobile app, applying the same bounded-duration
  self-termination behavior regardless of the initiating client.

## Scenario: A security rule auto-triggers deterrence without an operator present

**Scenario ID:** SCN-076
**Feature ID:** FEAT-024

**Persona:** A community site has a configured rule ("if intrusion detected in restricted zone
after hours, trigger siren") set up during a prior session, and it fires overnight when no
operator is actively watching.

1. The rule engine detects the configured condition and triggers the siren according to the
   pre-approved rule, without needing a human to confirm in the moment (the confirmation was
   effectively given when the rule itself was approved and enabled).
2. The VMS logs this as a rule-triggered deterrence action, distinguishing it from an
   operator-initiated one, and the fleet activity log shows it the next morning.
3. When Marcus reviews the site the next day, he can see clearly this was an automatic rule
   trigger, not something he did.

**What the user expects:** deterrence can still act automatically per a pre-approved rule when no
one's watching, but the record always makes clear whether a given action was human-confirmed in
the moment or policy-triggered.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow a security rule to trigger a deterrence action without a live
  operator confirmation, provided the rule itself was explicitly configured and enabled by an
  authorized user beforehand.
- **[vms]** The VMS activity log shall distinguish rule-triggered deterrence actions from
  operator-initiated ones.
- **[camera-firmware]** The camera shall accept a deterrence command originating from the rules
  engine through the same command path as a manually-confirmed one, and report which type of
  trigger initiated it.
