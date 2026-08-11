---
feature_id: FEAT-122
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md]
---

# Scenario: Mobile App — Data-Freshness Indicator

Covers the mobile-app side of FEAT-122: a visible indicator on any stream/thumbnail
distinguishing live, delayed, last-known, local-only (unsynced), and unavailable data.

## Scenario: Live view clearly marked as live

**Scenario ID:** SCN-451
**Feature ID:** FEAT-122

**Persona:** Priya opens live view on her front-door camera over a good WiFi connection.

1. The live-view screen shows a clear "Live" indicator (e.g. a small badge with a pulsing dot)
   confirming what she's watching is the camera's real-time feed.
2. If network conditions degrade and the stream starts buffering noticeably behind real time,
   the indicator changes to "Delayed" rather than continuing to claim "Live."

**What the user expects:** the "Live" label is trustworthy — it only appears when what she's
watching genuinely is close to real time.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The live-view screen shall display a "Live" freshness indicator only while
  the displayed stream is within a defined small delay of real time, switching to "Delayed"
  once that threshold is exceeded.
- **[cloud-components]** The streaming relay shall expose enough timing information (e.g.
  current buffer/delay) for the client to determine and display accurate freshness state.

## Scenario: Viewing a thumbnail while the camera is offline shows "last known"

**Scenario ID:** SCN-452
**Feature ID:** FEAT-122

**Persona:** Priya glances at the dashboard while her garage camera is offline.

1. The garage camera's thumbnail shows the last frame successfully captured before it went
   offline, labeled clearly as "Last known — [time]" rather than presented as current.
2. Tapping into that camera's live view shows the same last-known image with the same label,
   plus the camera-unreachable state, rather than a blank screen.

**What the user expects:** stale imagery is always labeled as stale, with a timestamp, never
presented ambiguously as if it might be current.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Any thumbnail or live-view frame sourced from before the camera's current
  session shall display a "Last known" label with the timestamp of that frame, distinct from a
  live frame.
- **[mobile-app]** The freshness label shall persist consistently across every surface showing
  that frame (dashboard thumbnail, live-view screen), not vary by screen.

## Scenario: Recently-captured clip is local-only and not yet synced to the cloud

**Scenario ID:** SCN-453
**Feature ID:** FEAT-122

**Persona:** Priya's camera recorded an event to its local SD card while the home's internet was
briefly down, before the clip has finished uploading to the cloud.

1. The event's clip is playable from the app (fetched directly from the camera on the local
   network) but is labeled "Local only — not yet backed up," distinct from a fully-synced
   cloud-backed clip.
2. Once the clip finishes uploading, the label updates to reflect it's now cloud-backed, without
   Priya needing to do anything.
3. If Priya is away from home (WAN-only) while the clip is still local-only, the app makes
   clear the clip isn't retrievable remotely yet, rather than showing a broken player.

**What the user expects:** she can tell whether a piece of footage exists safely in the cloud or
only on the camera itself, which matters if the camera is later lost, stolen, or damaged.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** A clip available only from local camera storage and not yet uploaded to the
  cloud shall be labeled "Local only" distinctly from a cloud-synced clip, and shall update
  automatically once the upload completes.
- **[mobile-app]** When a local-only clip cannot currently be reached remotely (no local
  network path), the app shall show an explicit "not available remotely yet" state instead of a
  generic playback error.
- **[camera-firmware]** The camera shall report each clip's sync status (local-only vs.
  cloud-backed) so clients can display accurate freshness/durability information.
