---
feature_id: FEAT-144
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Direct Camera-to-Cloud Live View (Standalone SKUs)

Covers FEAT-144: for standalone (non-NVR) SKUs, the camera establishes a live-view cloud
session directly with the app rather than via an NVR. This capability is explicitly gated
pending its own future firmware/security validation pass — the scenarios below cover both the
intended happy path and how the app should behave while the capability remains gated.

## Scenario: Standalone camera streams live view directly to the app without an NVR

**Scenario ID:** SCN-516
**Feature ID:** FEAT-144

**Persona:** Sam, who owns a single standalone camera SKU with no NVR at his home.

1. Sam opens the app and taps live view on his standalone camera.
2. Instead of going through a site NVR (which he doesn't have), the app establishes a live-view
   session directly against the camera's cloud channel.
3. The stream starts within the same expected latency as an NVR-mediated session, so Sam
   notices no difference in experience.
4. Because Sam has no NVR at all, this direct path is the only path — there is no fallback he
   needs to think about or choose.

**What the user expects:** owning a single standalone camera "just works" for remote viewing,
without needing to know or care that there's no NVR in the picture.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall support opening a live-view session directly against a
  standalone (non-NVR) camera's cloud channel when no NVR mediates that camera.
- **[camera-firmware]** The camera shall be capable of establishing a live-view cloud session
  directly with an authorized mobile client, without requiring an NVR intermediary.
- **[cloud-components]** The session broker shall support direct camera-to-app session
  establishment for standalone SKUs, as a distinct path from NVR-mediated sessions.

## Scenario: Capability is gated off pending validation, and the app says so plainly

**Scenario ID:** SCN-517
**Feature ID:** FEAT-144

**Persona:** Sam, same standalone-camera owner, on a firmware/app version where direct
camera-to-cloud live view has not yet cleared its security validation and remains gated off.

1. Sam taps live view on his standalone camera.
2. The app recognizes that direct camera-to-cloud live view is currently gated (not enabled)
   for his camera/firmware combination.
3. Rather than attempting the connection and failing with a confusing error, the app tells Sam
   plainly that this capability isn't available yet on his device, and suggests checking for a
   firmware update.
4. Sam is not left thinking his camera or account is broken.

**What the user expects:** a feature that isn't turned on yet is communicated as "not yet
available," never experienced as a mysterious failure.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall detect when direct camera-to-cloud live view is gated/disabled
  for a given camera and communicate that plainly, rather than attempting the connection and
  failing silently.
- **[camera-firmware]** The camera shall expose whether direct-to-cloud live view is enabled
  for its current firmware/validation state, so the app can react accordingly instead of
  guessing from a failed connection attempt.
</content>
