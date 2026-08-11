---
feature_id: FEAT-112
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — WiFi Auto-Reconnect

Covers the fleet-operator-facing side of FEAT-112: WiFi-connected cameras across a site
automatically recovering from a router/AP outage without operator intervention.

## Scenario: Site-wide AP restart causes a brief, self-resolving blip across WiFi cameras

**Scenario ID:** SCN-407
**Feature ID:** FEAT-112

**Persona:** Dana, an operator, watches her site's WiFi access point get restarted for scheduled
maintenance, taking every WiFi-connected camera down briefly (wired cameras are unaffected).

1. Dana's fleet grid shows only the WiFi-connected cameras' tiles flip to "Offline" during the
   AP restart, while Ethernet cameras stay unaffected throughout — confirming her earlier
   FEAT-097 interface-type tracking is accurate.
2. As the AP comes back up, each WiFi camera reconnects automatically and independently — Dana
   doesn't need to visit, restart, or re-provision any of them.
3. The grid returns to fully healthy within a short window, and each camera's brief outage is
   logged individually per FEAT-085.

**What the user expects:** a planned or unplanned AP restart resolves itself across every
affected camera automatically, with the fleet grid making clear exactly which cameras were
actually affected (the WiFi ones) versus unaffected (the wired ones).

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall reflect automatic WiFi reconnection across all affected cameras at a
  site without requiring per-camera operator action, while correctly leaving wired cameras
  unaffected in status.
- **[camera-firmware]** The camera shall automatically re-associate to its known WiFi network
  after an access-point-side outage (restart, brief unavailability) using stored credentials,
  without operator intervention.

## Scenario: One WiFi camera fails to auto-reconnect after the AP is back, unlike its peers

**Scenario ID:** SCN-408
**Feature ID:** FEAT-112

**Persona:** Dana notices that after the AP maintenance window, all WiFi cameras reconnected
except one, which stays offline.

1. The VMS flags this camera distinctly once its offline duration significantly exceeds its
   fellow WiFi cameras' recovery time from the same AP event, similar to how FEAT-111 flags a
   stuck cloud reconnection.
2. Dana investigates and finds the camera's stored credentials may have become stale (e.g. a
   password rotation happened around the same time) — a case genuinely requiring the
   re-provisioning flow (FEAT-124) rather than simple auto-reconnect, since auto-reconnect only
   works when credentials are still valid.
3. She initiates re-provisioning for that specific camera while confirming the rest of the fleet
   needed no such action.

**What the user expects:** the system distinguishes an ordinary, self-resolving reconnect from a
camera that's genuinely stuck and needs manual re-provisioning, so she isn't left waiting
indefinitely for an auto-reconnect that credential changes have made impossible.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall flag a WiFi-connected camera whose reconnection time significantly
  exceeds its site peers' recovery from the same access-point event, as a candidate needing
  manual investigation/re-provisioning rather than continued automatic retry.
- **[camera-firmware]** The camera shall distinguish an association failure due to a network
  path outage (retry-appropriate) from a repeated authentication failure (credential-invalid,
  not resolvable by retrying), and report which case applies so the operator knows whether
  re-provisioning is required.
