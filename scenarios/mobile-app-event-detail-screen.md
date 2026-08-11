---
feature_id: FEAT-116
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Event Detail Screen

Covers the mobile-app single-event detail view for FEAT-116: event type, camera, zone, local
time, snapshot, clip, confidence presentation, and rule context.

## Scenario: Reviewing a flagged event's full detail

**Scenario ID:** SCN-420
**Feature ID:** FEAT-116

**Persona:** Priya taps into an event from her notification list — a person detected in her
driveway zone.

1. The event detail screen shows: the event type ("Person Detected"), which camera captured it,
   which named zone it occurred in ("Driveway"), and the local date/time it happened — in her
   phone's local time zone, not UTC or the camera's time zone.
2. A snapshot image of the moment is shown immediately; a short video clip is available to play.
3. The detection's confidence is shown in plain, non-alarming terms (e.g. "Likely" rather than
   a raw percentage like "87.3%"), so Priya isn't left interpreting a raw number.
4. If a security rule (e.g. a scheduled zone) is what caused this event to be flagged, the
   screen states which rule matched, so Priya understands why this specific event was surfaced.

**What the user expects:** everything she needs to understand what happened, where, and why
it was flagged is on one screen, in plain language, without cross-referencing zone/rule
settings elsewhere.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The event detail screen shall display event type, camera name, zone name,
  and local (device time zone) date/time for every event.
- **[mobile-app]** The event detail screen shall show a representative snapshot image
  immediately and provide playback of the associated video clip.
- **[mobile-app]** Detection confidence shall be presented as a plain-language qualitative
  label rather than a raw numeric score, so it reads as an estimate rather than false
  precision.
- **[mobile-app]** When the event was surfaced because it matched a configured security rule
  (zone, schedule, object class), the detail screen shall name that rule so the user understands
  why this event was flagged.
- **[camera-firmware]** The camera shall attach zone, rule-match, and confidence metadata to
  each detection event at the time it's generated, so the detail screen never has to
  reconstruct that context after the fact.

## Scenario: Viewing a low-confidence, borderline detection

**Scenario ID:** SCN-421
**Feature ID:** FEAT-116

**Persona:** Priya opens an event where the AI detection was borderline (e.g. a shadow or a
pet that was tentatively flagged as a person).

1. The detail screen presents the lower-confidence result with correspondingly cautious wording
   (e.g. "Possible activity detected" rather than "Person Detected"), never overstating
   certainty the system doesn't have.
2. The snapshot/clip is still shown in full so Priya can judge for herself, since the system's
   own confidence is uncertain.

**What the user expects:** the wording never claims more certainty than the detection actually
has — she's given the evidence and an honest, hedged label, not a false-confident claim.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The event detail screen shall scale its confidence wording to the actual
  detection confidence tier (e.g. "Possible" for low confidence vs. a firmer label for high
  confidence), never presenting a low-confidence detection with high-confidence language.
- **[camera-firmware]** The camera shall report a confidence tier or score alongside every
  detection event so the client can present appropriately hedged wording rather than a single
  fixed label regardless of certainty.

## Scenario: Clip still processing when the event is opened

**Scenario ID:** SCN-422
**Feature ID:** FEAT-116

**Persona:** Priya taps into an event within seconds of the notification arriving, before the
camera has finished uploading the full clip.

1. The snapshot is already available and shown immediately.
2. The clip area shows a clear "processing" / "clip uploading" state instead of a broken
   player or an indefinite spinner.
3. Once the clip finishes uploading, the screen updates to make it playable without Priya
   needing to leave and reopen the event.

**What the user expects:** an event she opens early doesn't look broken — it's clear the clip
is simply still on its way, and it becomes available without her having to retry manually.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The event detail screen shall show a distinct "clip processing/uploading"
  state when the clip isn't yet available, rather than a generic loading spinner or broken
  player.
- **[mobile-app]** The event detail screen shall automatically transition to a playable clip
  once upload completes, without requiring the user to navigate away and back.
- **[cloud-components]** The cloud relay shall notify the app when a pending clip upload
  completes, so the detail screen can update without polling indefinitely.
