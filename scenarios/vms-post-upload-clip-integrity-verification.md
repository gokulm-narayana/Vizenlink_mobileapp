---
feature_id: FEAT-103
status: draft
target_fr_docs: [FR-vms.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: VMS — Post-Upload Clip Integrity Verification

Covers the fleet-operator-facing side of FEAT-103: relying on integrity-verified clips as
trustworthy evidence across a multi-camera site.

## Scenario: Operator relies on verification status before using a clip as incident evidence

**Scenario ID:** SCN-381
**Feature ID:** FEAT-103

**Persona:** Dana is compiling video evidence for a legal/insurance request following an
incident.

1. Dana filters the relevant camera's timeline to only "Verified" clips before compiling her
   evidence package, deliberately excluding anything still pending, failed, or unverified.
2. The VMS's export function itself refuses to include a non-"Verified" clip in a formal evidence
   package without an explicit override and warning, since she needs to be certain about
   integrity given the legal stakes.
3. She completes her package confident every included clip has passed an actual integrity check.

**What the user expects:** for anything used as formal evidence, the system actively protects
her from including a clip whose integrity hasn't actually been confirmed, rather than leaving
that check entirely up to her memory.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall let an operator filter a camera's timeline to "Verified" clips only,
  and shall warn (requiring explicit override) before including a non-"Verified" clip in a
  formal evidence export.
- **[vms]** The VMS shall display each clip's verification status prominently enough for an
  operator to confirm before relying on it as evidence.

## Scenario: A batch of clips from one camera repeatedly fails integrity verification

**Scenario ID:** SCN-382
**Feature ID:** FEAT-103

**Persona:** Dana notices one camera's clips keep failing integrity verification even after
automatic re-upload, unlike the rest of the fleet.

1. The VMS's fleet sync-state summary (per FEAT-101) shows this camera's failed-verification
   count is unusually high and persistent, standing out from the fleet baseline.
2. Dana investigates and finds the camera's local storage is likely degrading (corrupting clips
   before they're even uploaded), rather than the failures being a transient network issue.
3. She flags the camera for storage replacement, using the persistent verification-failure
   pattern as the diagnostic signal that pointed her there.

**What the user expects:** a camera with a real underlying storage problem is discoverable
through its abnormal integrity-failure rate, rather than each failure looking like an isolated,
unremarkable retry.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall track each camera's integrity-verification failure rate over time and
  flag a camera whose rate is abnormally high/persistent relative to the fleet baseline, as a
  possible local-storage health signal.
