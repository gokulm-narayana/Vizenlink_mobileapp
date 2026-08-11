---
feature_id: FEAT-084
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md]
---

# Scenario: Mobile App — Health State Model (Online/Cloud-Unreachable/NVR-Unreachable/Offline)

Covers the homeowner-facing side of FEAT-084: the app showing a structured connectivity state
for the camera rather than a single generic online/offline flag.

## Scenario: Camera is fully online and healthy

**Scenario ID:** SCN-314
**Feature ID:** FEAT-084

**Persona:** Priya, a homeowner opening the app on an ordinary day with everything working
normally.

1. Priya opens the app and the camera's status badge reads simply "Online" in a calm, positive
   color.
2. Tapping into the camera's details, she can see this reflects both a working local connection
   and a working link to the cloud (so remote alerts and remote viewing both work).
3. She doesn't need to do anything — the state is just a quiet confirmation everything is fine.

**What the user expects:** when everything is genuinely fine, the app should look reassuringly
simple — one clear "Online" state, without exposing internal plumbing she doesn't need.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a single, simple "Online" status when the camera is
  reachable both locally and via the cloud, without surfacing the underlying multi-state model
  unless the user drills into camera details.
- **[camera-firmware]** The camera shall report a composite health state distinguishing at least
  local-online, cloud-unreachable, NVR-unreachable, and fully-offline, rather than a single
  boolean connectivity flag.

## Scenario: Camera is locally fine but the cloud link is down

**Scenario ID:** SCN-315
**Feature ID:** FEAT-084

**Persona:** Priya's home internet has an outage, but her camera is still running fine on her
local network.

1. While Priya is home and on the same WiFi, live view still works perfectly if she opens the
   app locally.
2. But the app's status badge changes to something like "Online — Remote Access Limited" instead
   of a plain green "Online," since the cloud link the app depends on when she's away is down.
3. A short explanation clarifies that local viewing still works, but she won't get push alerts or
   be able to view remotely until the connection is restored.
4. Once her internet comes back, the badge reverts to plain "Online" without her having to do
   anything.

**What the user expects:** the app tells her specifically what's degraded (remote reachability)
rather than either hiding the problem or scaring her with a generic "Offline" that isn't
accurate — her camera is still working, just not reachable from outside.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a distinct "cloud-unreachable" status (visually and
  textually different from both fully-online and fully-offline) when the camera is
  locally-reachable but its cloud connection is down, and shall explain the practical impact
  (no remote view/alerts) in plain language.
- **[camera-firmware]** The camera shall continue local operation (recording, local live view)
  normally while in a cloud-unreachable state, and shall report the cloud link status
  independently of local network status.
- **[cloud-components]** The cloud/MQTT layer shall reflect a camera's last-known state as
  cloud-unreachable (not silently "unknown" or "offline") when it stops receiving expected
  keepalive/heartbeat traffic from that camera.

## Scenario: Camera goes fully offline, then recovers

**Scenario ID:** SCN-316
**Feature ID:** FEAT-084

**Persona:** Priya's camera loses power during a storm, then comes back once power is restored.

1. While the camera is unreachable both locally and via the cloud, the app shows a distinct
   "Offline" status — not the same badge as cloud-unreachable — since neither path works at all.
2. Priya gets a notification once the offline duration crosses a noticeable threshold, so she's
   not left wondering silently.
3. When power returns and the camera reconnects, the app's badge automatically updates back to
   "Online" and the notification feed shows when the camera went down and when it came back.

**What the user expects:** a fully-dead camera looks unmistakably different from one that's just
missing its cloud link, and she's told both when it went down and when it's back.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a distinct "Offline" status, visually different from
  "cloud-unreachable," when the camera is unreachable via both local and cloud paths, and shall
  notify the user once the offline condition persists past a minimum threshold.
- **[mobile-app]** The app shall automatically clear the "Offline" status and restore normal
  status display once the camera becomes reachable again, without requiring a manual refresh.
- **[camera-firmware]** The camera shall persist enough local state (or the cloud shall infer
  from a heartbeat gap) to determine and report an offline-to-online transition, including
  approximate offline start time, once connectivity resumes.
