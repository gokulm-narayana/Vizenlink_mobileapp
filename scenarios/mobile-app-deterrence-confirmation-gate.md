---
feature_id: FEAT-024
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md, FR-nuraeye-service.md, FR-security-rules-engine.md]
---

# Scenario: Mobile App — Deterrence with Confirmation Gate

Covers the homeowner-facing side of FEAT-024 (Deterrence — Siren/Spotlight/Warning with
Confirmation Gate): manually triggering siren, spotlight, or a prerecorded warning from the app,
gated behind an explicit confirmation step.

## Scenario: Homeowner triggers a siren at a suspicious late-night visitor

**Scenario ID:** SCN-072
**Feature ID:** FEAT-024

**Persona:** Priya sees someone trying her side gate late at night on live view and wants to
scare them off immediately.

1. Priya taps the siren/deterrence control in the app.
2. Before anything happens, the app shows an explicit confirmation step (e.g. "Activate siren for
   10 seconds?") rather than triggering immediately on the first tap.
3. She confirms, and the camera's siren activates; the app shows it as currently active.
4. The siren stops on its own after its bounded duration, and the app reflects that it has ended.

**What the user expects:** she can't accidentally trigger a loud siren with a stray tap — it
always requires a deliberate second confirmation — but once confirmed, it fires immediately.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall require an explicit confirmation step before sending a
  siren/spotlight/warning deterrence command, distinct from and after the initial tap on the
  control.
- **[mobile-app]** The app shall show the deterrence action's current state (active/inactive) and
  update it once the camera reports the action has ended.
- **[camera-firmware]** The camera shall activate the requested deterrence action (siren,
  spotlight, or prerecorded warning) only upon receiving an explicitly-confirmed command, and
  self-terminate it after a bounded duration.
- **[cloud-components]** When issued over WAN, the deterrence command shall be relayed via the
  existing MQTT command channel, and the camera's activation/completion status shall be relayed
  back to the app the same way.

## Scenario: Playing a prerecorded warning instead of the siren

**Scenario ID:** SCN-073
**Feature ID:** FEAT-024

**Persona:** Priya prefers a spoken warning ("This property is being recorded, please leave") over
a siren for a first response, reserving the siren for more serious situations.

1. Priya opens the deterrence control and selects the prerecorded warning option instead of siren.
2. She confirms, and the camera plays the recorded message through its speaker.
3. The app shows which specific deterrence action is currently playing, not just a generic
   "deterrence active" state.

**What the user expects:** she can choose the right level of response for the situation, and the
app is specific about which one is actually happening.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let the user choose which deterrence action (siren, spotlight, or
  prerecorded warning) to trigger, each requiring its own confirmation, and display which specific
  action is currently active.
- **[camera-firmware]** The camera shall support triggering a prerecorded warning message through
  its speaker as a distinct deterrence action from siren/spotlight.

## Scenario: Deterrence command fails to reach an unreachable camera

**Scenario ID:** SCN-074
**Feature ID:** FEAT-024

**Persona:** Priya tries to trigger the siren remotely, but her camera has lost connectivity at
that moment.

1. Priya confirms the siren action.
2. After a timeout, the app reports the command could not be confirmed as delivered, rather than
   showing the siren as active when it may not actually be sounding.
3. She understands she may need another way to respond (e.g. calling someone nearby) since the
   remote deterrence didn't confirm.

**What the user expects:** in an urgent moment, she's never falsely told a deterrence action
succeeded when the camera never actually received it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall not show a deterrence action as active until the camera
  acknowledges receiving and executing the command; on timeout/failure it shall show an explicit
  error.
- **[cloud-components]** The MQTT command relay shall surface delivery failure/timeout for a
  deterrence command to an unreachable camera, rather than reporting silent success.
