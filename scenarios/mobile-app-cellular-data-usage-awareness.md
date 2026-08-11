---
feature_id: FEAT-145
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Cellular Data Usage Awareness for Remote Live View

Covers FEAT-145: the app indicates connection type (WiFi/cellular) and warns about mobile data
usage before/during a remote live-view session over cellular.

## Scenario: Warning before starting a remote live view over cellular

**Scenario ID:** SCN-518
**Feature ID:** FEAT-145

**Persona:** Dana, checking her home camera from her phone while out running errands, connected
via cellular data.

1. Dana opens live view on a camera while away from WiFi.
2. Before the stream starts, the app shows a brief indicator that she's on cellular data, since
   live video can use meaningful data.
3. Because Dana has previously indicated she's on a limited data plan, the app shows a short
   confirmation prompt before starting the stream.
4. Dana can proceed knowing what she's about to use, or back out and wait until she's on WiFi.

**What the user expects:** she is never using mobile data for a bandwidth-heavy stream without
at least a heads-up.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall detect and display the current connection type (WiFi vs.
  cellular) whenever a live-view session is active.
- **[mobile-app]** The app shall show a brief warning/confirmation before starting a remote
  live-view session over cellular, at least once per session, when the user has indicated
  data-usage sensitivity.

## Scenario: Connection type changes mid-session (WiFi drops to cellular)

**Scenario ID:** SCN-519
**Feature ID:** FEAT-145

**Persona:** Dana, watching live view at home, then walking out to her car while the stream is
still open, causing her phone to hand off from home WiFi to cellular.

1. Dana is watching live view over WiFi and starts walking out to her car.
2. Her phone's connection silently switches from WiFi to cellular partway through the session.
3. The app's connection-type indicator updates to reflect she's now on cellular, without
   interrupting the stream itself.
4. If she keeps watching for an extended period, the app gives a gentle ongoing reminder that
   she's consuming cellular data, rather than warning once at the start and then going silent.

**What the user expects:** the app keeps her honestly informed about what network she's
actually using right now, not just what she started on.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall update its displayed connection-type indicator live during an
  active session if the underlying network changes from WiFi to cellular (or vice versa),
  without interrupting playback.
- **[mobile-app]** The app should periodically remind the user of ongoing cellular data usage
  during a long-running remote live-view session, distinct from the one-time
  start-of-session warning.
</content>
