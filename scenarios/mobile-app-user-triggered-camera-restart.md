---
feature_id: FEAT-098
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — User-Triggered Camera Restart with Health Confirmation

Covers the homeowner-facing side of FEAT-098: an on-demand "Restart Camera" action that reboots
the camera and reports back whether it recovered healthy.

## Scenario: Priya restarts a sluggish camera and gets confirmation it recovered

**Scenario ID:** SCN-363
**Feature ID:** FEAT-098

**Persona:** Priya notices her camera's live view has been laggy for a while and decides to try
restarting it herself before contacting support.

1. Priya taps "Restart Camera" in the app, and gets a clear confirmation prompt warning that live
   view/recording will briefly interrupt.
2. After confirming, the app shows a "Restarting…" state and doesn't let her assume it's done
   just because the app itself is responsive again — it waits for the camera to actually
   reconnect.
3. Once the camera comes back online, the app explicitly reports the outcome: "Camera restarted
   successfully and is healthy" (or names any condition still present, e.g. "restarted, but
   image quality issue persists"), not just a generic "back online."

**What the user expects:** a simple, self-service way to power-cycle her camera without calling
support, with a clear before/after confirmation that tells her whether it actually helped.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a "Restart Camera" action with an explicit confirmation
  step warning of the temporary interruption, and shall track the restart through to the
  camera's actual reconnection rather than assuming success once the command is sent.
- **[mobile-app]** The app shall report the post-restart health outcome explicitly (healthy, or
  naming any condition still present), not just a generic "camera is back online" message.
- **[camera-firmware]** The camera shall accept an authorized remote restart command, perform a
  clean reboot, and report its post-boot health state once initialization completes.

## Scenario: Restart is requested but the camera doesn't come back

**Scenario ID:** SCN-364
**Feature ID:** FEAT-098

**Persona:** Priya triggers a restart, but the camera fails to reconnect afterward — perhaps a
power issue unrelated to the restart itself.

1. After a reasonable timeout with no reconnection, the app tells Priya the restart could not be
   confirmed and the camera appears offline, rather than leaving the "Restarting…" spinner
   indefinite or silently timing out with no explanation.
2. The app suggests next steps (check the camera's power, check the network) since a self-issued
   restart that doesn't come back usually points at something beyond a simple reboot.
3. Priya can retry the restart command once she suspects the underlying issue is fixed (e.g.
   after checking the power cable), rather than being locked out of trying again.

**What the user expects:** if her restart attempt doesn't actually bring the camera back, the
app tells her clearly instead of leaving her staring at an ambiguous "restarting" state
forever.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall time out and explicitly report a failed/unconfirmed restart
  (camera did not reconnect within a reasonable window) rather than showing an indefinite
  "restarting" state, and shall suggest relevant next steps.
- **[mobile-app]** The app shall allow the user to retry the restart command after a failed
  attempt, without requiring any special unlock step.
