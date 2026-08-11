---
feature_id: FEAT-096
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — WiFi Signal Strength Indicator

Covers the homeowner/installer-facing side of FEAT-096: live WiFi RSSI shown for placement
judgment and troubleshooting, valid only when connected via WiFi.

## Scenario: Installer judges camera placement using live signal strength

**Scenario ID:** SCN-355
**Feature ID:** FEAT-096

**Persona:** An installer mounting Priya's camera in her garage, unsure if the WiFi signal will
be strong enough at that exact spot.

1. During setup, the app shows a live WiFi signal-strength indicator (e.g. a bar meter or dBm
   value) for the camera's current position.
2. The installer moves the camera a few inches, and the indicator updates within a couple of
   seconds, letting them iterate on placement before finalizing the mount.
3. Once they find a spot with a comfortably strong signal, they lock in that placement and
   finish mounting.

**What the user expects:** a live, responsive signal reading they can use to make a real-time
placement decision, not a stale or delayed number that doesn't reflect the current position.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display the camera's current WiFi signal strength as a live,
  frequently-updating indicator (e.g. bar meter or dBm value) during setup and in ongoing device
  status.
- **[camera-firmware]** The camera shall report its current WiFi RSSI on request, refreshed
  frequently enough to reflect near-real-time changes in physical position or interference.

## Scenario: Weak signal explains a later streaming problem

**Scenario ID:** SCN-356
**Feature ID:** FEAT-096

**Persona:** Priya notices her live view keeps buffering weeks after installation and checks the
app for a possible cause.

1. Priya opens her camera's device details and sees its WiFi signal strength is marked "Weak,"
   giving her an immediate, plausible explanation for the buffering without needing to guess.
2. The app suggests moving the camera closer to her router or adding a WiFi extender, tying the
   corrective guidance (FEAT-094) directly to the specific weak-signal condition.
3. After she relocates the camera, the signal indicator updates to "Good" and she notices
   streaming has improved.

**What the user expects:** a visible, plain signal-strength reading she can check herself when
something feels off, without needing to contact support just to learn her WiFi signal is weak.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall label WiFi signal strength using a plain qualitative scale
  (e.g. Weak/Fair/Good/Excellent) alongside or instead of a raw dBm value, so a non-technical
  user can interpret it without guidance.
- **[mobile-app]** The app shall pair a weak-signal reading with a corrective-action suggestion
  (e.g. reposition camera, add WiFi extender), consistent with FEAT-094's guidance pattern.
