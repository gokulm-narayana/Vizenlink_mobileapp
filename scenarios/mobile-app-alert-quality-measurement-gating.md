---
feature_id: FEAT-218
status: draft
target_fr_docs: [FR-camera-firmware.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Alert Quality Measurement & Release Gating (perceived accuracy)

Covers FEAT-218's user-perceptible manifestation: a homeowner rating an alert as accurate or
not, feeding the ongoing precision/recall/nuisance-alert measurement that gates whether a
detection-model update is allowed to ship — without inventing a UI control the user wouldn't
plausibly see for a pure backend release-gating metric.

## Scenario: Priya rates an alert as a false alarm

**Scenario ID:** SCN-670
**Feature ID:** FEAT-218

**Persona:** Priya gets a "Person detected" alert that turns out to be a shadow moving, not an
actual person.

1. Priya opens the alert and finds a lightweight "Was this alert accurate?" thumbs-up/thumbs-down
   control alongside it.
2. She taps thumbs-down; the app briefly confirms the feedback was recorded, with no further
   friction (no mandatory follow-up questionnaire).
3. Over time, if Priya (and other users on the same deployment preset) mark enough alerts as
   inaccurate, that contributes to the ongoing nuisance-alert-rate measurement used to gate
   whether the next detection-model update actually ships.

**What the user expects:** a simple, low-effort way to say "that alert wasn't right," trusting
that this feedback actually feeds into making future alerts better — not a control that
disappears into a void.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a lightweight thumbs-up/thumbs-down accuracy control on
  each alert, requiring no more than one tap to record feedback.
- **[cloud-components]** Per-alert accuracy feedback shall feed the per-camera-day
  precision/recall/nuisance-alert-rate measurement used for release gating, aggregated by
  deployment preset.

## Scenario: A detection-model update is held back because it fails the quality gate

**Scenario ID:** SCN-671
**Feature ID:** FEAT-218

**Persona:** A pilot rollout of a new detection model shows a higher nuisance-alert rate than the
numeric release gate allows, based on pilot-baseline feedback data.

1. Priya, on the general release track, never receives this model update — she continues
   receiving the previous, already-gated model version. She experiences no visible change at
   all; specifically, she does not experience a regression in alert quality.
2. There is no user-facing indication that a release was held back — this is an internal
   release-engineering decision — but the practical effect she experiences is that her alerts
   never got noticeably worse after an update.

**What the user expects (implicitly, never explicitly seen):** VizenLink doesn't ship her a
detection-model change that would make her alerts less trustworthy, even though she never sees
the gating decision itself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[cloud-components]** A detection-model update shall not be released to general availability
  when its pilot-baseline precision/recall/missed-event/nuisance-alert measurements fail the
  defined numeric release gates for the relevant deployment preset.
