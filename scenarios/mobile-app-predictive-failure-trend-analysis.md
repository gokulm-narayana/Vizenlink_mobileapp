---
feature_id: FEAT-095
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md]
---

# Scenario: Mobile App — Predictive Failure Trend Analysis

Covers the homeowner-facing side of FEAT-095: proactively warning when storage-wear or
image-quality trend data suggests a failure is likely soon, ahead of an actual hard failure.

## Scenario: SD card write-wear trend predicts a failure within weeks

**Scenario ID:** SCN-351
**Feature ID:** FEAT-095

**Persona:** Priya's camera's microSD card has been steadily accumulating write-wear indicators
for months, now trending toward its expected end of life.

1. Priya receives a proactive notification: "Your camera's storage may fail within about 2
   weeks at its current usage rate — consider replacing the SD card soon," well before any
   actual recording failure has happened.
2. The alert is clearly framed as a prediction, not a current fault — her camera is still
   recording fine today.
3. She can tap through to see the underlying trend (e.g. a simple wear-indicator graph over
   recent weeks) if she wants to understand why, not just take the estimate on faith.
4. After she replaces the card, the trend resets and the predictive warning clears.

**What the user expects:** she gets a heads-up while she still has time to act, instead of only
finding out when the storage has already failed and she's lost the ability to record.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display a proactive, clearly-labeled predictive warning (e.g.
  estimated time-to-failure) when storage-wear or image-quality trend data suggests a failure is
  likely soon, distinct from an alert about a condition that has already occurred.
- **[mobile-app]** The app shall show the underlying trend data behind a predictive warning on
  request, not just the final estimate.
- **[camera-firmware]** The camera shall track storage-wear indicators over time and report
  trend data (not just current pass/fail health) sufficient to support a time-to-failure
  estimate.

## Scenario: Predicted failure window passes without an actual failure

**Scenario ID:** SCN-352
**Feature ID:** FEAT-095

**Persona:** Priya ignored the 2-week storage warning, and three weeks later the storage still
hasn't actually failed.

1. The app doesn't claim the prediction was simply wrong and go silent — since storage wear is
   inherently probabilistic, it keeps the warning active (perhaps updating the estimate as more
   data comes in) rather than either falsely declaring victory or crying wolf with a stale
   estimate.
2. If new data suggests the risk has actually increased further, the app updates the estimate
   (e.g. "may now fail within days") rather than leaving the original stale "2 weeks" text
   sitting there indefinitely.
3. Priya can still see this is the same ongoing warning, not a brand new unrelated alert.

**What the user expects:** a predictive estimate that turns out cautious doesn't erode her trust
in the feature — the app is honest that it's an estimate and keeps it current rather than either
over- or under-stating risk as time passes.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall update an active predictive-failure warning's estimate as new
  trend data arrives, rather than leaving a stale, one-time estimate displayed indefinitely.
- **[mobile-app]** The app shall treat an updated predictive estimate as a continuation of the
  same warning (not a new, separate alert), so the user isn't confused by what looks like an
  unrelated repeat notification.
