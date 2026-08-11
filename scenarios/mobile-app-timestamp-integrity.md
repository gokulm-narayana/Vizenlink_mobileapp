---
feature_id: FEAT-008
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Timestamp Integrity (NTP/RTC + Uncertain-Time Flag)

Covers the homeowner-facing side of FEAT-008 (Timestamp Integrity): the app trusting the
camera's recording timestamps by default, and surfacing a clear warning if the camera's clock
becomes unreliable.

## Scenario: Normal operation — timestamps just work

**Scenario ID:** SCN-021
**Feature ID:** FEAT-008

**Persona:** Priya reviews a recorded clip after a delivery to confirm exactly when it arrived.

1. Priya opens the clip in the app and sees a timestamp overlay/metadata that matches her own
   phone's clock.
2. She never has reason to question whether the time shown is accurate — it just is.

**What the user expects:** recording timestamps are simply correct, without her ever having to
think about how the camera keeps time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display recording/event timestamps as reported by the camera
  without alteration, assuming camera time is accurate unless flagged otherwise.
- **[camera-firmware]** The camera shall synchronize its clock via NTP on startup and
  periodically thereafter, falling back to its local RTC when NTP is unreachable.

## Scenario: Camera clock becomes uncertain after prolonged NTP failure

**Scenario ID:** SCN-022
**Feature ID:** FEAT-008

**Persona:** Priya's camera has been unable to reach any NTP server for an extended period (e.g.
a router misconfiguration cut off internet access while local network access continued), and its
local RTC has drifted.

1. Priya opens the app and notices a clear "time may be inaccurate" indicator on the camera's
   status or on affected recordings, rather than no indication at all.
2. She can tap it to see roughly since when the camera's clock has been unable to confirm itself
   against NTP.
3. Recordings taken during this period are visibly marked as having an uncertain timestamp, so she
   knows not to treat their exact time as reliable (e.g. for an insurance claim or dispute).
4. Once the camera resyncs, the indicator clears and new recordings are no longer marked.

**What the user expects:** if the camera's sense of time can't be trusted, she's told plainly —
rather than silently trusting a clock that's drifted, especially for anything she might need to
rely on later.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall surface an explicit "uncertain time" indicator for a camera whose
  clock has been unable to confirm against NTP for a prolonged period, visible from the camera's
  status view.
- **[mobile-app]** The app shall visually mark recordings/events captured during an uncertain-time
  period as having a potentially inaccurate timestamp.
- **[mobile-app]** The app shall clear the uncertain-time indicator once the camera reports it has
  resynchronized successfully.
- **[camera-firmware]** The camera shall track how long it has gone without a successful NTP sync
  and raise an uncertain-time flag after exceeding a defined threshold, clearing it once NTP sync
  succeeds again.
- **[camera-firmware]** The camera shall tag recordings/events made while the uncertain-time flag
  is active so downstream consumers (app, VMS) can distinguish them from normally-timestamped
  ones.
