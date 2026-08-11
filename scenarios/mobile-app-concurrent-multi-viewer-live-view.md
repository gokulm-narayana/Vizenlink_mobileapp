---
feature_id: FEAT-142
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Concurrent Multi-Viewer Live View with Limits

Covers the household-facing side of FEAT-142: more than one authorized person can watch a
camera's live stream at the same time, capped at an explicit per-camera limit rather than
unlimited.

## Scenario: Two family members watch the same camera at once

**Scenario ID:** SCN-509
**Feature ID:** FEAT-142

**Persona:** Priya, a homeowner, and her husband Arjun, both with Viewer access to the same
front-door camera.

1. Priya opens live view on the front-door camera from her phone.
2. A few minutes later, Arjun, on his own phone, opens live view on the same camera.
3. Both streams play normally and independently — neither app shows a warning, and Priya's
   stream doesn't pause or drop when Arjun's starts.
4. Each of them can watch (and pan/zoom, if supported) without affecting what the other sees.

**What the user expects:** family members can each check the same camera whenever they want,
without "locking" the others out.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall allow more than one authorized user to open an independent
  live-view session on the same camera concurrently, up to the camera's configured viewer
  limit, without disrupting sessions already in progress.
- **[camera-firmware]** The camera shall support serving multiple concurrent live-view sessions
  of the same stream, up to a configured maximum, without measurably degrading existing
  viewers' stream quality.
- **[cloud-components]** For WAN sessions, the streaming session broker shall fan out a single
  camera's stream to multiple concurrently-connected mobile clients, up to the camera's
  configured limit.

## Scenario: A new viewer is turned away once the per-camera limit is reached

**Scenario ID:** SCN-510
**Feature ID:** FEAT-142

**Persona:** The same household, now with four people (Priya, Arjun, and their two teenagers)
all watching the front-door camera at once, whose configured limit is 4 concurrent viewers.

1. All four family members already have the camera's live view open on their own phones.
2. A visiting grandparent, also granted Viewer access, taps live view on the same camera.
3. Instead of a blank screen or a silent failure, the app tells the grandparent plainly that
   the maximum number of simultaneous viewers for this camera has been reached, and suggests
   trying again shortly.
4. None of the four existing viewers are disconnected to make room for the new request.
5. A few minutes later, once one of the teenagers closes live view, the grandparent retries and
   connects successfully.

**What the user expects:** hitting the limit produces a clear, honest message — never a
mysterious failure, and never someone else getting silently kicked off to make room.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display an explicit "viewer limit reached" message, distinct
  from a generic connection error, when a live-view request is rejected because the camera's
  concurrent-viewer cap is already met.
- **[mobile-app]** The app shall never disconnect an existing live-view viewer to accommodate a
  newer viewer request that would exceed the limit.
- **[camera-firmware]** The camera shall reject a live-view session request once its configured
  concurrent-viewer limit is reached, returning a distinguishable "limit reached" response
  rather than silently dropping the request or an existing session.
</content>
