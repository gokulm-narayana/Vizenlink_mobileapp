# EventDetailScreen

- **Dart file:** `lib/screens/events/event_detail_screen.dart`
- **Route:** `/events/detail` (pushed with a `RecordedEvent` via `extra`)
- **Purpose:** Detail view for a single recorded event/clip — thumbnail, camera, timestamp, duration, and actions to jump to the live feed, download the snapshot, share the snapshot, delete the event, and browse other events from the same camera. Modeled on industry-standard VMS mobile app conventions (Ring, Nest, Hik-Connect, Reolink, Arlo, etc. — see research notes) and mirrors this app's existing `AlertDetailScreen` pattern for consistency. **Thumbnail-only — no clip playback/download** (removed 2026-09-07 per direct user request, "remove the dummy video in the app completely": there's no real per-event clip API yet, and this screen used to stand in with the same bundled dummy video asset `AlertDetailScreen`/`camera_live_screen.dart` used; rather than keep showing fake footage, the Play/Fullscreen/Download-clip controls were removed entirely — add real inline clip playback back once a real clip URL exists on `RecordedEvent`).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| EVTDET-001 | App bar title | AppBar | Event type label, e.g. "Motion" |
| EVTDET-002 | Back button | BackButton | Returns to `EventsScreen` |
| EVTDET-003 | Thumbnail view | GlassCard + Image/placeholder (`_MediaView`) | Shows the thumbnail (`Image.network(event.thumbnailUrl)`), or a type-icon gradient placeholder when there's no `thumbnailUrl`/it fails to load. No video, real or fake — see this screen's own Purpose note above |
| ~~EVTDET-004~~ | ~~Play button overlay~~ | — | Retired 2026-09-07 — played the bundled dummy video asset as a stand-in for "the recording"; removed rather than keep showing fake footage (see this screen's own Purpose note) |
| EVTDET-005 | Camera name | Text | e.g. "Front Door Cam" |
| EVTDET-006 | Event type chip | Chip, with icon | Icon + label from `EventTypeDisplay` (`lib/models/event_type_display.dart`) — unlike `AlertDetailScreen`'s equivalent chip, this one has a leading icon |
| EVTDET-007 | Timestamp | Text | Full date + time |
| EVTDET-008 | Duration | Text | e.g. "Duration: 0:34" — `RecordedEvent.duration` already exists on the model, no new field needed |
| ~~EVTDET-009~~ | ~~Fullscreen toggle~~ | — | Retired 2026-09-07, same reason as EVTDET-004 — only ever fullscreened the dummy video |
| EVTDET-010 | "View live" button | FilledButton (full width) | Looks up the event's camera (`event.cameraId`) in `HomesController` and deep-links to [camera_live_screen.md](../camera_live/camera_live_screen.md) via `context.go('/dashboard/live/{cameraId}', extra: camera)` — switches to the Dashboard tab, landing directly on that camera's live view. Shows a "Camera unreachable" snackbar instead of navigating if no matching camera is found. Same pattern as `ALERTDET-008` |
| ~~EVTDET-011~~ | ~~"Download clip" button~~ | — | Retired 2026-09-07, same reason as EVTDET-004 — copied the bundled dummy video asset to the gallery as a stand-in "clip"; removed entirely rather than keep faking it |
| EVTDET-012 | "Download snapshot" button | OutlinedButton (full width) | Fetches `thumbnailUrl` bytes and saves via `Gal.putImageBytes`; disabled when `thumbnailUrl == null` (unlike `AlertDetailScreen`, which doesn't guard this — flagged here since not every mock event necessarily has a thumbnail). Was previously the right half of a two-button row with EVTDET-011; now full width alone |
| EVTDET-013 | Share button | IconButton (AppBar action) | Fetches `thumbnailUrl` bytes, writes a temp file, opens the OS share sheet via `share_plus` |
| EVTDET-014 | Delete button | IconButton (AppBar action) | Confirms via dialog, then calls `EventsController.deleteEvent` and pops back |
| EVTDET-015 | "More from {camera}" section | Text header + horizontal ListView of cards | Other events from the same `cameraId` (not filtered by type/unread, unlike `AlertDetailScreen`'s related-alerts row — Events has no read state). Tapping a card uses `context.pushReplacement` (not `push`) so navigating between related events doesn't pile up an ever-growing back stack |

### Research basis

Before designing this screen, researched common patterns across commercial VMS mobile apps (Ring, Nest, Hik-Connect, Reolink, Arlo, UniFi Protect, Milestone XProtect): video/playback (inline player, thumbnail-first, fullscreen), metadata (timestamp, camera, event type/AI tag), actions (download, share, delete/favorite), and related-event navigation. The proposal intentionally **excluded** a Favorite/star toggle (present in Arlo/Ring) since it would require a new `isFavorite` field on `RecordedEvent` not currently in the model — flagged rather than silently added; can be added later if wanted. Enterprise-specific concepts (Milestone's bookmark IDs/creating-user) were also excluded as not relevant to a consumer-style app.

### Fullscreen navigation fix

`_openFullscreen` originally used `Navigator.of(context).push(...)` — since this screen lives inside a `StatefulShellRoute` branch with its own nested `Navigator`, that pushed onto the branch's Navigator rather than the app's root one, leaving `MainShell`'s bottom nav bar visible underneath the "fullscreen" video. Fixed to `Navigator.of(context, rootNavigator: true).push(...)`. The same bug existed and was fixed in `AlertDetailScreen`, `camera_live_screen.dart`, and `AlertsScreen`'s snapshot fullscreen preview.

### Navigation change on EventsScreen

Previously, tapping an event (in the timeline ruler or the list) called `_playEvent` directly, pushing a bare fullscreen `VideoPlayer` via `MaterialPageRoute`. That method and its `_FullscreenEventPlayer` widget were removed — tapping now navigates to `EventDetailScreen` instead (`context.push('${EventsScreen.routeName}/${EventDetailScreen.routeName}', extra: event)`), matching how `AlertsScreen` → `AlertDetailScreen` already works. This screen shows `EVTDET-003`'s thumbnail, not directly from the list/timeline tap (there is no inline playback here any more — see the Purpose note above).
