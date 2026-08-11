---
feature_id: FEAT-207
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Generic Digital I/O / Relay Event Support

Covers FEAT-207: a homeowner/installer configuring a camera's generic digital input/output (a
dry-contact relay output, or a digital-input trip signal) on hardware SKUs that support it.

## Scenario: Configuring the relay output to trigger on an alarm event

**Scenario ID:** SCN-655
**Feature ID:** FEAT-207

**Persona:** Vikram installs a VizenLink camera with a relay output wired to an existing gate
release mechanism, and wants the relay to pulse whenever the camera detects a specific event.

1. Vikram opens the camera's Device Settings → I/O in the app and sees the relay-output control
   (only shown because his camera's SKU has this hardware; a SKU without it doesn't show the
   option at all).
2. He configures the relay to trigger for a chosen event type (e.g. person detected in a
   defined zone) and sets the pulse duration.
3. He tests it with a "Trigger now" button in the app, confirming the relay physically fires
   before relying on it for the real event trigger.

**What the user expects:** he can wire the camera into existing site equipment through a simple,
camera-app-configured relay, without needing separate relay-control hardware.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show digital I/O configuration only for camera SKUs that report
  the corresponding hardware capability, hiding the control entirely otherwise.
- **[mobile-app]** The app shall let a user map a relay output to a chosen event type and pulse
  duration, and shall provide a manual "Trigger now" test action.
- **[camera-firmware]** The camera shall drive its relay output per the configured event-type
  mapping and pulse duration, and shall support a manual on-demand trigger command for testing.

## Scenario: Configuring the digital input as a trip signal from other site equipment

**Scenario ID:** SCN-656
**Feature ID:** FEAT-207

**Persona:** Vikram also wants the camera to react when an external device (e.g. a simple door
contact switch) trips the camera's digital input.

1. Vikram configures the digital input in the app: what it means when triggered (e.g. "door
   opened") and what the camera should do in response (e.g. start recording, raise an alert).
2. He simulates the trip (shorting the input, or via a test toggle) and confirms the app reports
   the expected reaction.

**What the user expects:** the camera can receive a simple external signal and react to it
meaningfully, the same way it can send one out.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user configure the meaning of a digital-input trigger and
  the camera's resulting action (recording, alert).
- **[camera-firmware]** The camera shall detect a digital-input trip signal and execute the
  configured resulting action (recording start, alert generation).

## Scenario: Attempting to configure I/O on a SKU without the hardware

**Scenario ID:** SCN-657
**Feature ID:** FEAT-207

**Persona:** Priya, on a base-model camera without a relay/I/O port, browses Device Settings
looking for the same control Vikram has.

1. Priya's Device Settings screen simply does not show an I/O section for her camera model,
   rather than showing a control that would fail or do nothing if used.

**What the user expects:** she isn't shown a setting that would silently not work on her
hardware.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall query the camera's reported hardware capabilities and omit the
  digital I/O settings section entirely for a camera that does not report the capability.
