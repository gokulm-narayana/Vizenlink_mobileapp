# AlertDetailScreen

- **Dart file:** `lib/screens/alerts/alert_detail_screen.dart`
- **Route:** `/alerts/detail` (pushed with an `Alert` via `extra`)
- **Purpose:** Detail view for a single notification/alert — snapshot, camera, timestamp, description, and actions to jump to the live feed, download or share the snapshot, delete the notification, snooze the camera's alerts, and jump to other unread motion alerts from the same camera (surfaced under an "Unread notifications" heading). **Snapshot-only — no clip playback/download** (removed 2026-09-07 per direct user request, "remove the dummy video in the app completely": there's no real per-alert clip API yet, and this screen used to stand in with the same bundled dummy video asset `camera_live_screen.dart` used for its own Live-tab fallback; rather than keep showing fake footage, the Play/Fullscreen/Download-clip controls were removed entirely — add real inline clip playback back once a real clip URL exists on `Alert`).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| ALERTDET-001 | App bar title | AppBar | Alert type label, e.g. "Motion" |
| ALERTDET-002 | Back button | BackButton | Returns to AlertsScreen |
| ALERTDET-003 | Snapshot view | GlassCard + Image/placeholder (`_MediaView`) | Shows the snapshot (`Image.network(alert.snapshotUrl)`), or a type-icon gradient placeholder when there's no `snapshotUrl`/it fails to load. No video, real or fake — see this screen's own Purpose note above |
| ALERTDET-004 | Camera name | Text | e.g. "Front Door Cam" |
| ALERTDET-005 | Event type chip | Chip | See `AlertType` in `lib/models/alert.dart` for the full set; label/icon mapping lives in `lib/models/alert_type_display.dart` |
| ALERTDET-006 | Timestamp | Text | Full date + time |
| ALERTDET-007 | Description text | Text | Falls back to `message` when no `description` |
| ALERTDET-008 | "View live" button | FilledButton (full width) | Looks up the alert's camera (`alert.cameraId`) in `HomesController` and deep-links to [camera_live_screen.md](../camera_live/camera_live_screen.md) via `context.go('/dashboard/live/{cameraId}', extra: camera)` — switches to the Dashboard tab, landing directly on that camera's live view. Shows a "Camera unreachable" snackbar instead of navigating if no matching camera is found |
| ~~ALERTDET-009~~ | ~~"View recording" button~~ | — | Retired — duplicated ALERTDET-011's playback action; removed rather than kept disabled |
| ALERTDET-010 | Mark as read/unread toggle | IconButton (AppBar action) | Toggles `Alert.isRead` via `AlertsController` |
| ~~ALERTDET-011~~ | ~~Play button overlay~~ | — | Retired 2026-09-07 — played the bundled dummy video asset as a stand-in for "the recording"; removed rather than keep showing fake footage (see this screen's own Purpose note) |
| ALERTDET-012 | "Download snapshot" button | OutlinedButton (full width) | Fetches `snapshotUrl` bytes and saves to the device gallery via `Gal.putImageBytes`; shows a loading spinner and success/error snackbar. Was previously the left half of a two-button row with ALERTDET-013; now full width alone |
| ~~ALERTDET-013~~ | ~~"Download clip" button~~ | — | Retired 2026-09-07, same reason as ALERTDET-011 — copied the bundled dummy video asset to the gallery as a stand-in "clip"; removed entirely rather than keep faking it |
| ALERTDET-014 | Delete button | IconButton (AppBar action) | Confirms via dialog, then calls `AlertsController.deleteAlert` and pops back |
| ALERTDET-015 | Share button | IconButton (AppBar action) | Fetches `snapshotUrl` bytes, writes a temp file, and opens the OS share sheet via `share_plus` |
| ~~ALERTDET-016~~ | ~~Fullscreen toggle~~ | — | Retired 2026-09-07, same reason as ALERTDET-011 — only ever fullscreened the dummy video |
| ALERTDET-017 | Snooze camera alerts button | OutlinedButton (full width) | Toggles `AlertsController.toggleCameraSnooze(cameraId)`; snoozed cameras' alerts are hidden from `AlertsScreen` (see `AlertsController.isCameraSnoozed`) |
| ALERTDET-018 | "Unread notifications — {camera}" section header | Text | Introduces the related-alerts row (renamed from "Unread motion — {camera}"; the row's content filter itself is still motion-only, only the label changed) |
| ALERTDET-019 | Related alerts list | Horizontal ListView of cards | Filtered to `AlertType.motion` **and** unread only (per explicit request — the list shrinks/empties as the user reads items, which was a deliberate tradeoff, not a bug). Unread cards get a cyan border + glow dot + bold label (in practice every card here is unread, since the row is unread-only). Tapping a card navigates to `AlertsScreen` pre-filtered to that camera, `AlertType.motion`, **and** the Unread read-state toggle, via `context.go('/alerts', extra: (cameraName, AlertType.motion, true))` — a 3-element Dart record (camera, type, unreadOnly), not a bare `String`. (Two earlier iterations of this wiring passed less: first just the camera name, then camera+type but not the read-state toggle — see AlertsScreen's `initialCameraFilter`/`initialTypeFilter`/`initialUnreadOnly`/`didUpdateWidget` notes.) It does **not** open that alert's own detail screen |
