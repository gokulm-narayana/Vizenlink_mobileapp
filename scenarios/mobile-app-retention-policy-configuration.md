---
feature_id: FEAT-037
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Retention Policy Configuration

Covers the homeowner-facing side of FEAT-037: a simplified retention-duration control for local
SD footage, as the app-facing slice of the broader retention-policy engine (which spans camera,
stream, event severity, and storage destination on the VMS side).

## Scenario: Homeowner sets a simple local retention duration

**Scenario ID:** SCN-127
**Feature ID:** FEAT-037

**Persona:** Marcus wants his SD card to hold about two weeks of footage before older recordings
get overwritten.

1. Marcus opens the storage settings and sets a retention duration (e.g. "14 days") using a
   simple slider or preset list, rather than a complex policy builder.
2. The app confirms the value was applied and shows an estimate of whether the current SD card
   size can actually sustain that duration at current recording settings.
3. If the card can't realistically hold that much footage at the current bitrate, the app warns
   Marcus rather than silently accepting an unachievable setting.

**What the user expects:** a simple "how long do I want to keep this" control that also tells
him honestly whether that's realistic for his hardware.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a simplified retention-duration control (preset options
  or a slider) for local SD footage, distinct from the VMS's full multi-dimensional retention
  policy engine.
- **[mobile-app]** The app shall warn the user, at configuration time, when the selected
  retention duration is not realistically achievable given current SD card size and recording
  bitrate.
- **[camera-firmware]** The camera shall apply a local retention duration by overwriting the
  oldest unprotected footage once storage nears capacity, respecting the duration where storage
  allows.

## Scenario: Retention would delete a locked/protected event

**Scenario ID:** SCN-128
**Feature ID:** FEAT-037

**Persona:** Priya has an important incident clip locked (see FEAT-041) that is now older than
her configured retention duration.

1. As the SD card fills and normal retention would overwrite footage older than the configured
   duration, the camera skips the locked clip rather than deleting it.
2. The app, if Priya checks, shows that the locked clip is being retained beyond the normal
   retention window specifically because it's protected, not due to a bug or inconsistency.

**What the user expects:** locking a clip actually means it survives normal retention, and the
app is clear about why an "expired" clip is still there.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera's retention-driven overwrite process shall skip any
  locked/protected recording regardless of its age relative to the configured retention
  duration.
- **[mobile-app]** The app shall indicate, for a recording older than the configured retention
  duration, that it is being retained because it is locked, rather than presenting it as sitting
  in retention exceptionally without explanation.
