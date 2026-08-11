---
feature_id: FEAT-090
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Dirty Lens/Haze/Fogging Detection

Covers the homeowner-facing side of FEAT-090: detecting gradual image degradation from a dirty
lens, haze, or fogging — a slow-onset condition distinct from FEAT-086's sudden underexposure/
overexposure/focus-loss conditions.

## Scenario: Gradual haze builds up over several days from lens grime

**Scenario ID:** SCN-340
**Feature ID:** FEAT-090

**Persona:** Marcus's outdoor camera slowly accumulates dust and pollen film on its lens over a
couple of weeks, gradually softening and hazing the image.

1. Because the degradation is gradual, Marcus wouldn't have noticed it himself day to day — but
   once the camera's image has drifted enough from its known-clear baseline for a sustained
   period, he gets a "Lens May Need Cleaning" alert, distinct from a sudden-onset image-quality
   alert.
2. The alert includes a comparison between a recent clear reference frame and the current hazy
   one, so he can visually confirm it himself rather than take the alert on faith.
3. He wipes down the lens, and the next time the camera reassesses image clarity, the alert
   clears automatically.

**What the user expects:** the camera catches a degradation so slow he'd never notice it
himself, and tells him what to do about it, distinct from a sudden fault.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a distinct "lens may need cleaning" alert (separate
  from FEAT-086's sudden-onset image-quality alerts) when the camera detects a gradual,
  sustained drift in image clarity relative to its own recent baseline.
- **[mobile-app]** The app shall show a before/after comparison (recent clear baseline vs.
  current) for a haze/fogging alert so the user can visually confirm the condition.
- **[camera-firmware]** The camera shall maintain a rolling baseline of recent clear-image
  characteristics and detect a gradual, sustained drift toward haze/blur distinct from the
  abrupt threshold-crossing used for sudden image-quality faults.

## Scenario: Seasonal fogging that clears with weather, not cleaning

**Scenario ID:** SCN-341
**Feature ID:** FEAT-090

**Persona:** Marcus's camera fogs up internally on humid mornings during a particular season,
clearing on its own by mid-morning as temperatures rise, with no actual dirt on the lens.

1. Marcus gets the haze alert on the first foggy morning, cleans the lens (unnecessarily, since
   the cause was condensation not dirt), and the alert clears — but recurs the next humid
   morning.
2. After it happens a few mornings in a row and clears reliably on its own each time, the app
   suggests he mark it as a recurring, weather-driven condition, so it stops pushing a fresh
   "needs cleaning" alert each time it self-resolves within its usual window.
3. If a similar-looking fogging condition ever fails to clear on its own by early afternoon, the
   app treats that as a break from the established pattern and raises a fresh, active alert.

**What the user expects:** the app doesn't keep telling him to clean a lens that's actually fine
and just fogging up seasonally, but still catches it if the pattern changes to something that
doesn't clear.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user mark a recurring haze/fogging condition as
  weather-driven/self-clearing after observing it recur and self-resolve, suppressing repeat
  push notifications for subsequent occurrences within the established pattern.
- **[mobile-app]** The app shall re-alert if a marked recurring haze condition fails to
  self-clear within its established typical window, since that indicates a change from the
  known pattern.
- **[camera-firmware]** The camera shall report both onset and clear timestamps for each
  haze/fogging occurrence, enabling the app or cloud to learn and validate a recurring pattern's
  typical duration.
