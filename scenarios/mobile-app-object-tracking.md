---
feature_id: FEAT-062
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Short-Term Object Tracking

Covers the homeowner-facing side of FEAT-062: fewer duplicate alerts for the same object
lingering or moving through frame, as perceived through the mobile app's notification stream.

## Scenario: Person lingering in frame produces one alert, not several

**Scenario ID:** SCN-219
**Feature ID:** FEAT-062

**Persona:** Sofia, a homeowner whose entryway camera would previously buzz her phone repeatedly
while a visitor stood at the door.

1. A delivery person stands at Sofia's door for about thirty seconds while she comes to answer.
2. Sofia's phone receives exactly one "Person detected" notification for that whole visit, not
   one every few seconds as the same person continues to be visible.
3. Opening the alert, the linked clip covers the whole visit, not just the first instant.

**What the user expects:** a single person standing around doesn't spam her phone — one
notification correctly represents one continuous event.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera shall track a detected object across consecutive frames for a
  short window and treat continued presence of the same object as part of the same event,
  rather than generating a new alert-worthy detection each time it reappears in a frame.
- **[mobile-app]** The app shall present a single notification and a single alert entry for one
  continuous tracked-object event, even if that event spans many frames/seconds.

## Scenario: Object leaves and re-enters after a gap is treated as a new event

**Scenario ID:** SCN-220
**Feature ID:** FEAT-062

**Persona:** Sofia, whose delivery person leaves the porch, walks back to their van, and returns
a couple of minutes later.

1. The person leaves the camera's view entirely for longer than the short tracking window.
2. Sofia gets an alert for the first visit as usual.
3. When the same person returns a couple of minutes later, it's outside the tracking window's
   memory, so the camera treats it as a new detection and Sofia gets a second, separate alert.

**What the user expects:** the "don't re-alert on the same object" behavior only suppresses
genuinely continuous presence — it doesn't silently swallow a second, meaningfully separate
visit just because it's the same person.

> **Review:** ⏳ Pending

### Derived Requirements

- **[camera-firmware]** The camera's short-term tracking window shall have a bounded duration,
  after which a reappearing object (even the same individual) is treated as a new,
  independently alertable event rather than being suppressed as a continuation of the earlier
  one.
- **[mobile-app]** The app shall show each such re-detected event as its own distinct alert
  entry in the timeline, so the user can tell a visitor came back rather than assuming it's the
  same notification repeated.
