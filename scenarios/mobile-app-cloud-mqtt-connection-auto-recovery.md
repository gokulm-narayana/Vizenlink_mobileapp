---
feature_id: FEAT-111
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Cloud/MQTT Connection Auto-Recovery

Covers the homeowner-facing side of FEAT-111: mobile push alerts and remote live-view/control
automatically resume after a network blip, without any manual action.

## Scenario: Push alerts resume automatically after a brief cloud connectivity blip

**Scenario ID:** SCN-401
**Feature ID:** FEAT-111

**Persona:** Priya's camera briefly loses its cloud/MQTT connection for a couple of minutes due
to a transient ISP hiccup, then reconnects on its own.

1. Priya doesn't notice anything happened — no push alerts are missed for long, since the camera
   automatically re-establishes its cloud connection within moments of the blip clearing.
2. She isn't required to open the app, toggle anything, or restart the camera for alerts and
   remote live-view/control to resume — it's fully automatic.
3. If she happens to check the camera's status during the brief gap, it correctly shows
   "cloud-unreachable" (per FEAT-084), then reverts to "Online" once reconnected.

**What the user expects:** brief connectivity blips are invisible to her in practice — alerts
and remote access just keep working without her ever needing to intervene.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall resume receiving push alerts and remote live-view/control
  automatically once the camera's cloud connection recovers, without requiring any user action
  (app restart, manual reconnect, etc.).
- **[cloud-components]** The MQTT/cloud connection layer shall automatically re-establish a
  dropped connection from the camera without requiring a manual reconnect trigger, using a
  reasonable backoff/retry strategy.

## Scenario: A longer cloud outage requires more persistent auto-recovery, and Priya is kept informed

**Scenario ID:** SCN-402
**Feature ID:** FEAT-111

**Persona:** Priya's cloud connectivity is down for over an hour due to a broader ISP issue
affecting her whole neighborhood.

1. Priya sees her camera's status as "cloud-unreachable" for the duration, consistent with the
   health-state model, rather than a confusing generic error.
2. Once her ISP issue resolves, the camera automatically re-establishes its cloud connection
   without any manual step from her, and her push alerts and remote access resume within a short
   time of reconnection.
3. She doesn't need to have kept the app open the whole time — reconnection happens on the
   camera/cloud side independent of whether she was actively watching.

**What the user expects:** even a longer outage resolves itself automatically once the
underlying connectivity issue clears — she's never required to manually intervene to restore
remote functionality.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall not require the user to have the app open or take any manual
  step for cloud connectivity and its dependent features (push, remote live-view/control) to
  resume after an extended outage — recovery happens independent of app foreground state.
- **[cloud-components]** The MQTT/cloud connection layer shall continue retrying reconnection
  with backoff indefinitely (not give up after a fixed number of attempts) for as long as the
  camera remains powered and network-capable.
