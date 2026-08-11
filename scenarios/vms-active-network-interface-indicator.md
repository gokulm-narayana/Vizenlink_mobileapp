---
feature_id: FEAT-097
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: VMS — Active Network Interface Indicator

Covers the fleet-operator-facing side of FEAT-097: distinguishing WiFi vs. Ethernet cameras
across a site, and pairing WiFi cameras with their signal strength.

## Scenario: Operator distinguishes WiFi and Ethernet cameras in the fleet table

**Scenario ID:** SCN-361
**Feature ID:** FEAT-097

**Persona:** Dana, an operator managing a mixed-connectivity office deployment.

1. The fleet device table shows an "Interface" column reading either "WiFi" or "Ethernet" per
   camera, with the signal-strength column populated only for the WiFi rows.
2. Dana can filter to "WiFi only" when investigating a connectivity-quality issue, immediately
   narrowing to the subset where signal strength is even a relevant factor.
3. For an Ethernet camera showing connectivity trouble, she knows to look at switch/cabling
   issues instead of chasing a WiFi red herring.

**What the user expects:** the fleet view helps her correctly scope her troubleshooting to the
right connectivity domain (wireless vs. wired) for each camera, at a glance across the whole
site.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display each camera's active network interface (WiFi or Ethernet) as a
  column in the fleet device table, and shall support filtering the fleet view by interface
  type.
- **[vms]** The VMS shall only display a WiFi signal-strength value for cameras currently active
  on WiFi, leaving the field empty (not zero) for Ethernet-connected cameras.

## Scenario: A batch of cameras unexpectedly falls back from Ethernet to WiFi

**Scenario ID:** SCN-362
**Feature ID:** FEAT-097

**Persona:** Dana notices several cameras that are normally wired show "WiFi" as their active
interface one morning, following overnight switch maintenance that briefly took down PoE ports.

1. The VMS's fleet table update makes this visible immediately — a batch of cameras whose
   interface column changed from their normal "Ethernet" to "WiFi" overnight — rather than Dana
   only discovering it if she happened to check each camera individually.
2. She correlates the timing with the known switch maintenance window and confirms this was
   expected fallback behavior, not a fault.
3. Once the switch ports are restored, she watches the affected cameras' interface columns
   revert back to "Ethernet" in the fleet table, confirming full recovery.

**What the user expects:** an unexpected interface change across multiple cameras is visible as
a fleet-wide pattern she can correlate against known events, not something she'd only notice by
accident on one camera at a time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall retain a per-camera history of active-interface changes (not just the
  current value), so an operator can identify when and how many cameras changed interface
  together.
- **[camera-firmware]** The camera shall automatically fail over to WiFi (if configured/paired)
  when its Ethernet link is lost, and shall fail back to Ethernet automatically once the wired
  link is restored, reporting each transition as an interface-change event.
