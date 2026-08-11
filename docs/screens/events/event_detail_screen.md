# EventDetailScreen

- **Dart file:** `lib/screens/events/event_detail_screen.dart`
- **Route:** `/events/detail` (pushed with a `RecordedEvent` via `extra`)
- **Purpose:** Detail view for a single recorded event/clip — thumbnail/playback, camera, timestamp, duration, and actions to jump to the live feed, play/fullscreen the recording, download the snapshot or clip, share the snapshot, delete the event, and browse other events from the same camera. Modeled on industry-standard VMS mobile app conventions (Ring, Nest, Hik-Connect, Reolink, Arlo, etc. — see research notes) and mirrors this app's existing `AlertDetailScreen` pattern for consistency. Mock/local data only (see CLAUDE.md — no real CCTV protocol chosen yet, so playback/downloads/shares use the same dummy video asset as `AlertDetailScreen`/`camera_live_screen.dart`).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| EVTDET-001 | App bar title | AppBar | Event type label, e.g. "Motion" |
| EVTDET-002 | Back button | BackButton | Returns to `EventsScreen` |
| EVTDET-003 | Thumbnail / video player | GlassCard + Image/VideoPlayer/placeholder | Shows the thumbnail (or a type-icon gradient placeholder when no `thumbnailUrl`) until playback starts, then swaps to an inline `VideoPlayer` wrapped in `InteractiveViewer` (`maxScale: 4`) for pinch-to-zoom — same pattern as `AlertDetailScreen`'s `ALERTDET-003` and `camera_live_screen.dart`'s `_VideoSurface`. Also applied in the fullscreen player (`_FullscreenVideo`, reached via EVTDET-009) |
| EVTDET-004 | Play button overlay | IconButton (over thumbnail) | Tapping starts inline playback of the dummy video asset |
| EVTDET-005 | Camera name | Text | e.g. "Front Door Cam" |
| EVTDET-006 | Event type chip | Chip, with icon | Icon + label from `EventTypeDisplay` (`lib/models/event_type_display.dart`) — unlike `AlertDetailScreen`'s equivalent chip, this one has a leading icon |
| EVTDET-007 | Timestamp | Text | Full date + time |
| EVTDET-008 | Duration | Text | e.g. "Duration: 0:34" — `RecordedEvent.duration` already exists on the model, no new field needed |
| EVTDET-009 | Fullscreen toggle | IconButton (over video player) | Shown once playback starts; opens a landscape-locked fullscreen video page, same pattern as `AlertDetailScreen`/`camera_live_screen.dart` |
| EVTDET-010 | "View live" button | FilledButton (full width) | Looks up the event's camera (`event.cameraId`) in `HomesController` and deep-links to [camera_live_screen.md](../camera_live/camera_live_screen.md) via `context.go('/dashboard/live/{cameraId}', extra: camera)` — switches to the Dashboard tab, landing directly on that camera's live view. Shows a "Camera unreachable" snackbar instead of navigating if no matching camera is found. Same pattern as `ALERTDET-008` |
| EVTDET-011 | "Download clip" button | OutlinedButton | Copies the dummy video asset to a temp file and saves to the device gallery via `Gal.putVideo`; loading spinner + success/error snackbar |
| EVTDET-012 | "Download snapshot" button | OutlinedButton | Fetches `thumbnailUrl` bytes and saves via `Gal.putImageBytes`; disabled when `thumbnailUrl == null` (unlike `AlertDetailScreen`, which doesn't guard this — flagged here since not every mock event necessarily has a thumbnail) |
| EVTDET-013 | Share button | IconButton (AppBar action) | Fetches `thumbnailUrl` bytes, writes a temp file, opens the OS share sheet via `share_plus` |
| EVTDET-014 | Delete button | IconButton (AppBar action) | Confirms via dialog, then calls `EventsController.deleteEvent` and pops back |
| EVTDET-015 | "More from {camera}" section | Text header + horizontal ListView of cards | Other events from the same `cameraId` (not filtered by type/unread, unlike `AlertDetailScreen`'s related-alerts row — Events has no read state). Tapping a card uses `context.pushReplacement` (not `push`) so navigating between related events doesn't pile up an ever-growing back stack |

### Research basis

Before designing this screen, researched common patterns across commercial VMS mobile apps (Ring, Nest, Hik-Connect, Reolink, Arlo, UniFi Protect, Milestone XProtect): video/playback (inline player, thumbnail-first, fullscreen), metadata (timestamp, camera, event type/AI tag), actions (download, share, delete/favorite), and related-event navigation. The proposal intentionally **excluded** a Favorite/star toggle (present in Arlo/Ring) since it would require a new `isFavorite` field on `RecordedEvent` not currently in the model — flagged rather than silently added; can be added later if wanted. Enterprise-specific concepts (Milestone's bookmark IDs/creating-user) were also excluded as not relevant to a consumer-style app.

### Fullscreen navigation fix

`_openFullscreen` originally used `Navigator.of(context).push(...)` — since this screen lives inside a `StatefulShellRoute` branch with its own nested `Navigator`, that pushed onto the branch's Navigator rather than the app's root one, leaving `MainShell`'s bottom nav bar visible underneath the "fullscreen" video. Fixed to `Navigator.of(context, rootNavigator: true).push(...)`. The same bug existed and was fixed in `AlertDetailScreen`, `camera_live_screen.dart`, and `AlertsScreen`'s snapshot fullscreen preview.

### Navigation change on EventsScreen

Previously, tapping an event (in the timeline ruler or the list) called `_playEvent` directly, pushing a bare fullscreen `VideoPlayer` via `MaterialPageRoute`. That method and its `_FullscreenEventPlayer` widget were removed — tapping now navigates to `EventDetailScreen` instead (`context.push('${EventsScreen.routeName}/${EventDetailScreen.routeName}', extra: event)`), matching how `AlertsScreen` → `AlertDetailScreen` already works. Playback itself now happens inside `EventDetailScreen` (`EVTDET-003`/`EVTDET-004`), not directly from the list/timeline tap.
