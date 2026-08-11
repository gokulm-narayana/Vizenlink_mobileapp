---
feature_id: FEAT-223
status: draft
target_fr_docs: [FR-mobile-app.md, FR-wifi-provisioning.md]
---

# Scenario: Mobile App — WiFi/BLE Provisioning Completion-Time Target

Covers FEAT-223: initial WiFi provisioning via the primary BLE path completing within 30 seconds
of opening the app, and the firmware starting a Soft-AP fallback if BLE hasn't completed within
60 seconds — as experienced by someone setting up a brand-new camera.

## Scenario: Fast BLE provisioning on the happy path

**Scenario ID:** SCN-678
**Feature ID:** FEAT-223

**Persona:** Priya unboxes a new camera and opens the app to add it.

1. Priya taps "Add Camera," the app finds the new camera over BLE, and she enters her home WiFi
   credentials.
2. Within about 30 seconds of starting this flow, the app confirms the camera has joined her
   WiFi network and is ready to use.

**What the user expects:** setup feels quick and doesn't leave her standing around wondering if
it's stuck.

> **Review:** ⏳ Pending

### Derived Requirements

- **[wifi-provisioning]** Initial WiFi provisioning via the primary BLE path shall complete
  within 30 seconds of the user beginning the in-app setup flow, under normal conditions.
- **[mobile-app]** The setup flow shall show active progress (not a static "connecting…" with no
  feedback) while BLE provisioning is in progress.

## Scenario: BLE provisioning stalls and the camera falls back to Soft-AP

**Scenario ID:** SCN-679
**Feature ID:** FEAT-223

**Persona:** Priya's phone's Bluetooth has a flaky connection to the new camera, and BLE
provisioning is taking much longer than usual.

1. After 60 seconds without completing BLE provisioning, the camera itself starts broadcasting
   its own Soft-AP network, without needing any restart or button-press from Priya.
2. The app detects this and guides Priya through connecting to the camera's Soft-AP network
   instead, continuing setup from there rather than leaving her stuck on a failed BLE attempt.

**What the user expects:** setup doesn't just hang indefinitely on a flaky BLE connection — the
camera and app cooperate to offer a working fallback path automatically.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall automatically start its Soft-AP fallback network if BLE
  provisioning has not completed within 60 seconds of BLE provisioning beginning, without
  requiring manual intervention.
- **[mobile-app]** The app shall detect that BLE provisioning has stalled and guide the user
  through connecting via the camera's Soft-AP fallback rather than leaving the BLE attempt open
  indefinitely with no next step offered.

## Scenario: Both BLE and Soft-AP provisioning fail

**Scenario ID:** SCN-680
**Feature ID:** FEAT-223

**Persona:** Priya is in a location with heavy RF interference and even the Soft-AP fallback
fails to complete provisioning.

1. The app reports a clear provisioning failure with actionable next steps (e.g. move closer to
   the router, restart the camera, contact support) rather than an indefinite spinner or a
   generic unexplained error.
2. Priya can retry the whole flow from the start without needing to fully reset the camera
   first, unless the failure specifically requires that.

**What the user expects:** even in the worst case, she gets useful guidance rather than being
stuck with no explanation of what went wrong or what to try next.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall report a clear, actionable failure message if both BLE and
  Soft-AP provisioning fail to complete, rather than leaving an indefinite loading state.
