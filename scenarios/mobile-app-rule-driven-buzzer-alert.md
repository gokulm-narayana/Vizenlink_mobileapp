---
feature_id: FEAT-028
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md, FR-security-rules-engine.md]
---

# Scenario: Mobile App — Rule-Driven Automatic Buzzer Alert Channel

Covers the homeowner-facing side of FEAT-028 (Rule-Driven Automatic Buzzer Alert Channel):
configuring a detection rule to automatically sound the buzzer as an alert channel, alongside
mobile push notifications.

## Scenario: Adding the buzzer as an automatic response to a person-detection rule

**Scenario ID:** SCN-081
**Feature ID:** FEAT-028

**Persona:** Priya has an existing rule that sends her a push notification whenever a person is
detected at her back gate after dark, and wants the camera to also sound its buzzer automatically
in that same situation, without her needing to be watching the app.

1. Priya opens that rule's configuration in the app and finds "Buzzer" available as an alert
   channel option alongside push notification, listed per rule rather than as one global setting.
2. She enables the buzzer channel for this rule and saves.
3. The next time the rule's condition fires, she both receives the push notification and the
   camera's buzzer sounds automatically, without her taking any action in the moment.

**What the user expects:** she can set up the buzzer to respond automatically to specific
detection conditions, the same way she already configures push notifications per rule.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer the buzzer as a per-rule alert channel option, configurable
  independently for each detection rule alongside push notifications.
- **[camera-firmware]** The camera shall sound the buzzer automatically when a rule configured
  with the buzzer channel fires, applying the same bounded-duration auto-stop behavior as a
  manually-triggered buzzer activation.

## Scenario: Disabling the buzzer channel for a rule that was too noisy

**Scenario ID:** SCN-082
**Feature ID:** FEAT-028

**Persona:** Priya finds that a motion-based rule she set up with the buzzer channel enabled is
firing too often (e.g. from passing cars), sounding the buzzer more than she wants.

1. Priya opens that specific rule's configuration and disables just the buzzer channel, leaving
   the push notification channel active.
2. Going forward, that rule continues to notify her but no longer triggers the buzzer, while any
   other rule she has that also uses the buzzer channel is unaffected.

**What the user expects:** she can turn off the buzzer for one overly-noisy rule without losing
notifications from it entirely, and without affecting her other rules' buzzer behavior.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let the user disable the buzzer channel for one rule
  independently of its other alert channels and independently of other rules' buzzer
  configuration.
- **[camera-firmware]** The camera shall evaluate the buzzer channel setting per rule
  independently, so disabling it on one rule has no effect on buzzer behavior triggered by any
  other rule.
