---
feature_id: FEAT-072
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Stopped-Vehicle/Parking-Duration Rules

Covers the fleet-operator side of FEAT-072: configuring parking-duration rules for a lot, and
avoiding false alerts on legitimate short stops.

## Scenario: Operator configures a parking-duration rule for a community lot

**Scenario ID:** SCN-257
**Feature ID:** FEAT-072

**Persona:** Dana, setting up a rule for a community's visitor parking lot where vehicles
parked over 4 hours should be flagged for management follow-up.

1. Dana creates a parking-duration rule scoped to the visitor-lot zone with a 4-hour threshold.
2. A vehicle parked past that threshold triggers an alert visible in the VMS's event list, with
   the elapsed duration and the vehicle's snapshot.
3. Dana uses this to identify vehicles that may need a follow-up notice, without having to
   manually watch the lot.

**What the user expects:** the rule gives her an automatic, evidence-backed way to spot
overstaying vehicles across a lot she can't watch continuously herself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display a parking-duration alert's elapsed stopped time and linked
  snapshot in the site event list, filterable separately from ordinary vehicle-entry alerts.

## Scenario: Delivery truck's brief legitimate stop doesn't trigger an alert

**Scenario ID:** SCN-258
**Feature ID:** FEAT-072

**Persona:** Dana, whose loading-zone parking-duration rule has a 2-hour threshold, and a
delivery truck stops there for 20 minutes to unload — well under the threshold.

1. The truck parks, stays stationary for 20 minutes, then leaves.
2. No parking-duration alert is generated, since the stop never reached the configured
   threshold.
3. Dana's event list isn't cluttered with every routine, short-duration stop — only genuine
   overstays are surfaced.

**What the user expects:** normal, brief operational stops (deliveries, drop-offs) don't
generate noise — only stops that actually exceed her configured concern threshold do.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall suppress any parking-duration event entirely for a
  stopped vehicle whose duration never reaches the configured threshold, rather than logging a
  sub-threshold "stop" that the client would need to filter out itself.
