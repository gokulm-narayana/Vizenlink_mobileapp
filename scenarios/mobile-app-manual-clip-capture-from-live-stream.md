---
feature_id: FEAT-045
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Manual Clip Capture from Live Stream

Covers the homeowner-facing side of FEAT-045: operator-triggered ad-hoc clip capture from a
live stream, on the mobile app only — not a camera-side automatic capability.

## Scenario: Homeowner captures an ad-hoc clip while watching live view

**Scenario ID:** SCN-155
**Feature ID:** FEAT-045

**Persona:** Marcus is watching his driveway camera's live view and notices something worth
saving that isn't tied to any automatic detection event (e.g. a neighbor's dog wandering
through).

1. Marcus taps a "Capture Clip" control while watching live view.
2. The app requests a clip covering a short window around the moment he tapped (leveraging the
   camera's live buffer, similar in spirit to event pre-roll) plus a bit of time going forward.
3. The app confirms the clip was captured and saved, and Marcus can find it in his footage list
   marked as a manually captured clip, distinct from an automatically detected event.

**What the user expects:** he can save a moment he personally noticed, not just ones the camera
happened to flag on its own.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a manual "Capture Clip" control during live view,
  independent of any automatic detection.
- **[mobile-app]** The app shall mark a manually captured clip as distinct from an
  automatically-detected event clip wherever it appears in footage lists.
- **[camera-firmware]** The camera shall support producing an ad-hoc clip from its live buffer
  on explicit client request, covering a window around the request moment.

## Scenario: Clip capture attempted during a network hiccup

**Scenario ID:** SCN-156
**Feature ID:** FEAT-045

**Persona:** Priya taps "Capture Clip" just as her connection to the camera briefly drops.

1. The app attempts the capture request and, after a reasonable timeout, reports that the
   capture could not be confirmed rather than silently showing it as saved.
2. Priya can retry once the connection is restored.
3. If the camera actually completed the capture despite the app not receiving confirmation, the
   clip still appears in her footage list once she retries or refreshes — the app's uncertainty
   doesn't mean the clip is lost, only that it couldn't confirm success at that moment.

**What the user expects:** the app never falsely claims a capture succeeded, but a genuine
network blip doesn't have to mean losing the moment either.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall not confirm a manual clip capture as successful until the
  camera acknowledges it, showing an explicit retry-able error on timeout/failure instead.
- **[camera-firmware]** The camera shall complete and store a requested ad-hoc clip capture even
  if the requesting client's connection drops before acknowledgment is received, so the clip is
  not lost due to a client-side network issue.
