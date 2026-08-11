---
feature_id: FEAT-045
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Manual Clip Capture from Live Stream

Covers the fleet-operator-facing side of FEAT-045: operator-triggered ad-hoc clip capture from a
live stream in the VMS/NVR, not a camera-side capability.

## Scenario: Operator captures an ad-hoc clip from a live grid view

**Scenario ID:** SCN-157
**Feature ID:** FEAT-045

**Persona:** Marcus is watching a multi-camera live grid (see FEAT-046) and notices activity on
one camera worth saving, even though no rule fired.

1. Marcus selects the relevant camera tile in the grid and triggers "Capture Clip."
2. The VMS requests an ad-hoc clip from that camera's live buffer and confirms once captured.
3. The captured clip appears in the site's event/clip log tagged as a manual capture, along with
   which operator triggered it.

**What the user expects:** he can save something he personally spotted while monitoring live
feeds, with a record of who captured it and when.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a manual "Capture Clip" control per camera from a live grid
  view, independent of any rule/detection trigger.
- **[vms]** The VMS shall log a manually captured clip with which operator triggered it, tagged
  distinctly from automatically-detected event clips.

## Scenario: Manual capture requested for a camera that just went offline

**Scenario ID:** SCN-158
**Feature ID:** FEAT-045

**Persona:** Priya triggers a manual capture on a camera at the exact moment it drops offline.

1. The VMS attempts the capture request and, on failure to reach the camera, reports the
   capture did not succeed rather than logging a clip that doesn't actually exist.
2. Priya sees the affected camera's offline status alongside the failed capture, so the failure
   reason is clear rather than looking like an unexplained glitch.
3. Priya can retry once the camera is confirmed back online.

**What the user expects:** a failed capture is reported honestly and explained, not silently
dropped or falsely recorded as successful.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall report a manual clip capture failure explicitly when the target camera
  is unreachable, rather than logging a clip entry for a capture that didn't succeed.
- **[vms]** The VMS shall surface the camera's offline status alongside a failed capture attempt
  so the cause is clear to the operator.
