---
feature_id: FEAT-054
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Per-Camera Detection Sensitivity Tuning

Covers the fleet-operator side of FEAT-054: tuning detection sensitivity per camera across a
multi-camera deployment from the VMS, and recovering from an over-tightened setting.

## Scenario: Operator tunes sensitivity per camera after a nuisance-alert complaint

**Scenario ID:** SCN-214
**Feature ID:** FEAT-054

**Persona:** Dana, a site operator managing a community's 30-camera deployment through the VMS,
after a resident complains one specific camera keeps firing alerts on nothing.

1. Dana opens that one camera's detection settings from the VMS camera list — not a
   fleet-wide setting.
2. She lowers its sensitivity and saves; the VMS confirms the change applied to that camera
   specifically.
3. Checking the camera list a moment later, every other camera's sensitivity setting is
   unchanged.
4. The nuisance alerts from that camera stop within the next few detection cycles, without
   Dana needing to touch any other camera on the site.

**What the user expects:** a fix to one problem camera doesn't require (or risk) touching every
other camera's behavior, and the VMS makes clear the change is scoped correctly.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall expose a per-camera detection sensitivity control in each camera's
  settings panel, and shall apply a change to only the selected camera, never as a fleet-wide
  default unless the operator explicitly chooses a bulk-apply action.
- **[camera-firmware]** The camera shall apply the confidence threshold most recently set for
  it via any authorized client (mobile app or VMS), independent of any other camera's setting.

## Scenario: Over-tightened sensitivity starts missing real detections

**Scenario ID:** SCN-215
**Feature ID:** FEAT-054

**Persona:** Dana, having lowered a camera's sensitivity aggressively to kill false alerts, later
learns from a resident that an actual prowler wasn't detected on that camera.

1. Dana reviews the camera's current sensitivity setting in the VMS and sees it's set well below
   the factory-recommended safe range.
2. The VMS flags that this camera's setting is outside the recommended range, or otherwise makes
   it easy for Dana to compare against the safe default.
3. Dana resets the camera to the safe default (or a value the VMS recommends) with a single
   action, rather than having to remember or reconstruct what "safe" was.
4. Following nights show the camera reliably detecting real activity again, at the cost of some
   nuisance alerts returning — an explicit trade-off Dana now understands.

**What the user expects:** it's easy to tell when a sensitivity setting has drifted into
unsafe territory, and easy to recover back to a known-good default without guesswork.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall visually flag a camera's detection sensitivity setting when it falls
  outside the manufacturer's recommended safe range, and shall provide a one-action "restore
  safe default" control.
- **[camera-firmware]** The camera shall ship with (and be able to be reset back to) a
  documented safe-default confidence threshold and persistence filter, distinct from any
  since-customized value.
