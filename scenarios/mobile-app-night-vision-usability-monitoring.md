---
feature_id: FEAT-087
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Night Vision Usability Monitoring

Covers the homeowner-facing side of FEAT-087: flagging when night vision quality stays unusable
for a sustained period, distinct from a routine day/night switch.

## Scenario: Night vision stays unusably dim after switching to night mode

**Scenario ID:** SCN-328
**Feature ID:** FEAT-087

**Persona:** Priya's camera switches to night mode as usual at dusk, but its IR illuminator has
degraded and the resulting image stays too dark to make out anything useful.

1. After the night image has stayed below a usable quality threshold for a sustained period
   (not just the normal few seconds of adjustment right after switching), Priya gets a "Night
   Vision Unusable" alert, distinct from the ordinary day/night mode-change notice.
2. The alert includes a sample frame showing just how dark/unusable the current night image is.
3. The camera's status badge shows an attention state at night specifically, while still showing
   healthy status during the day (since the image is fine in daylight).
4. Priya has the illuminator/lens checked, and once night vision quality is confirmed usable
   again the following night, the alert clears automatically.

**What the user expects:** the app tells her clearly that her night-time coverage specifically
has degraded, not just a vague "image quality" complaint, since a camera that's fine by day but
useless at night is a distinct, actionable problem.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a distinct "night vision unusable" alert (separate from
  the general image-quality alert and from the routine day/night mode-change notification) when
  the camera's night-mode image quality stays below a usable threshold for a sustained period.
- **[mobile-app]** The app shall clear the night-vision-unusable alert automatically once the
  camera confirms usable night-mode quality across a subsequent night cycle.
- **[camera-firmware]** The camera shall evaluate night-mode image usability (e.g. brightness,
  contrast, discernible detail) independently from day-mode evaluation, and raise a distinct
  event only once poor night quality persists past a minimum sustained duration.

## Scenario: Night vision degrades only on cloudy/moonless nights

**Scenario ID:** SCN-329
**Feature ID:** FEAT-087

**Persona:** Priya's camera relies partly on ambient light plus IR, and its night image is
borderline-usable on clear nights but drops below the usable threshold on unusually dark,
overcast nights.

1. Priya gets the "Night Vision Unusable" alert only on the nights where it's actually below
   threshold, not every single night — since the camera's own IR-based capture doesn't
   generally depend on moonlight the way this scenario surfaces the app's own conservative
   handling of borderline cases.
2. The app doesn't repeatedly alert every borderline night once Priya has already flagged this as
   a known intermittent condition — she can mark it as "monitoring" so it logs quietly rather
   than notifying her on every recurrence, similar to how a recurring image-quality condition is
   handled.
3. If the condition becomes the norm rather than the occasional exception (e.g. every night
   going forward), the app escalates back to an active alert since that indicates a real,
   worsening fault rather than an occasional environmental edge case.

**What the user expects:** an occasional, environment-driven dip in night quality doesn't turn
into nightly alert fatigue, but a persistent worsening trend still gets her attention.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user mark a recurring, intermittent night-vision-unusable
  condition as "monitoring" so subsequent occurrences are logged without a fresh push
  notification each time.
- **[mobile-app]** The app shall re-escalate a monitored, intermittent night-vision condition to
  an active alert if it starts occurring on a majority of nights rather than occasionally,
  since that suggests a worsening underlying fault.
- **[camera-firmware]** The camera shall report each night-vision-unusable occurrence with
  enough frequency/pattern data (e.g. occurrence count over a rolling window) for the app or
  cloud to distinguish an occasional environmental dip from a persistent, worsening trend.
