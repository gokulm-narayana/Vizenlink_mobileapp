---
feature_id: FEAT-096
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — WiFi Signal Strength Indicator

Covers the fleet-operator-facing side of FEAT-096: reviewing WiFi signal strength across many
WiFi-connected cameras for troubleshooting and placement judgment.

## Scenario: Operator identifies which cameras are running on marginal WiFi signal

**Scenario ID:** SCN-357
**Feature ID:** FEAT-096

**Persona:** Dana, an operator supporting a mixed-connectivity site (some cameras on Ethernet,
some on WiFi), investigating recurring stream-quality complaints.

1. Dana opens the fleet device-telemetry table and sorts by WiFi signal strength, immediately
   spotting three WiFi-connected cameras with weak signal readings, while Ethernet-connected
   cameras in the same table simply show no signal-strength column value (since it doesn't
   apply to them).
2. The three weak-signal cameras correlate with the site's known stream-quality complaints,
   giving Dana a concrete lead before dispatching anyone.
3. She schedules a placement review or extender installation for just those three cameras.

**What the user expects:** she can triage connectivity-quality complaints across a fleet using a
live, sortable signal-strength view, without that column being confusing or misleading for
Ethernet-connected cameras.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall include WiFi signal strength as a sortable/filterable column in the
  fleet device-telemetry table, showing no value (not a false zero) for cameras connected via
  Ethernet.
- **[camera-firmware]** The camera shall report its current WiFi RSSI to the VMS/cloud alongside
  its other telemetry when WiFi-connected, and shall omit or explicitly null the field when
  connected via Ethernet.

## Scenario: Signal strength readings support a remote troubleshooting call

**Scenario ID:** SCN-358
**Feature ID:** FEAT-096

**Persona:** Dana is on a support call helping a resident diagnose why their camera keeps
dropping.

1. Dana pulls up that specific camera's live signal-strength value while on the call, seeing it
   currently reads very weak.
2. She asks the resident to move the camera slightly and watches the live reading update in
   real time to confirm improvement before ending the call, rather than relying on the resident's
   own subjective sense of "seems better."
3. Once the reading stabilizes at a healthy level, Dana closes the ticket with the specific
   before/after readings recorded.

**What the user expects:** she can use the live signal reading as an objective, real-time
diagnostic tool during a remote support interaction, not just a static number checked once.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose a camera's current WiFi signal strength as a live-refreshing
  value viewable by an operator during an active remote support session, not just as a
  point-in-time snapshot.
- **[vms]** The VMS shall let an operator record before/after signal-strength readings against a
  support ticket for that camera.
