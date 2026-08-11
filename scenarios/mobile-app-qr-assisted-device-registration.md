---
feature_id: FEAT-160
status: draft
target_fr_docs: [FR-mobile-app.md, FR-wifi-provisioning.md]
---

# Scenario: Mobile App — QR-Assisted Device Registration

Covers FEAT-160: the user's phone scans a QR code printed on the camera's box/label to
auto-fill its serial number and pairing info into the app, skipping manual entry.

## Scenario: New owner scans the QR code on the box to register the camera

**Scenario ID:** SCN-576
**Feature ID:** FEAT-160

**Persona:** Tom, unboxing a new camera for the first time.

1. Tom opens the app and taps "Add a camera."
2. Instead of typing in a long serial number, he's prompted to scan a QR code, and points his
   phone at the label on the camera's box.
3. The app reads the code and auto-fills the camera's serial number and pairing information,
   skipping manual entry entirely.
4. Tom proceeds directly to the next step of provisioning (e.g. WiFi setup) with the device
   already correctly identified.

**What the user expects:** getting a new camera added starts with a quick scan, not
painstakingly typing a long alphanumeric serial number correctly.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall support scanning a QR code printed on the camera's
  packaging/label to auto-fill its serial number and pairing information during device
  registration.
- **[mobile-app]** The app shall proceed directly from a successful scan into the next
  provisioning step, without requiring the user to re-enter the scanned information.

## Scenario: QR code is unreadable and the app falls back to manual entry

**Scenario ID:** SCN-577
**Feature ID:** FEAT-160

**Persona:** Tom, whose camera box's QR code label is smudged/damaged in shipping.

1. Tom points his phone at the QR code but the app can't get a clean read after a few tries.
2. The app offers a clear fallback — "Enter serial number manually" — rather than getting stuck
   repeating a failing scan indefinitely.
3. Tom types the serial number found printed nearby in plain text, and registration continues
   normally from there.

**What the user expects:** a damaged QR code is an inconvenience, not a dead end — there's
always a way to finish registering the camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a manual serial-number entry fallback when QR scanning
  fails or is unavailable, so registration is never blocked solely by an unreadable code.
</content>
