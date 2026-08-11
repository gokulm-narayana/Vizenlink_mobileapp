# AlertDetailScreen

- **Dart file:** `lib/screens/alerts/alert_detail_screen.dart`
- **Route:** `/alerts/detail` (pushed with an `Alert` via `extra`)
- **Purpose:** Detail view for a single notification/alert — snapshot/playback, camera, timestamp, description, and actions to jump to the live feed, play/fullscreen the recording, download or share the snapshot/clip, delete the notification, snooze the camera's alerts, and jump to other unread motion alerts from the same camera (surfaced under an "Unread notifications" heading). Mock/local data only (see CLAUDE.md — no real CCTV protocol chosen yet, so playback and clip downloads/shares use the same dummy video asset `camera_live_screen.dart` uses).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| ALERTDET-001 | App bar title | AppBar | Alert type label, e.g. "Motion" |
| ALERTDET-002 | Back button | BackButton | Returns to AlertsScreen |
| ALERTDET-003 | Snapshot / video player | GlassCard + Image/VideoPlayer/placeholder | Shows the snapshot (or a type-icon placeholder when no `snapshotUrl`) until playback starts, then swaps to an inline `VideoPlayer` wrapped in `InteractiveViewer` (`maxScale: 4`) for pinch-to-zoom — same pattern as `camera_live_screen.dart`'s `_VideoSurface` and `EventDetailScreen`'s `EVTDET-003`. Also applied in the fullscreen player (`_FullscreenVideo`, reached via ALERTDET-016) |
| ALERTDET-004 | Camera name | Text | e.g. "Front Door Cam" |
| ALERTDET-005 | Event type chip | Chip | See `AlertType` in `lib/models/alert.dart` for the full set; label/icon mapping lives in `lib/models/alert_type_display.dart` |
| ALERTDET-006 | Timestamp | Text | Full date + time |
| ALERTDET-007 | Description text | Text | Falls back to `message` when no `description` |
| ALERTDET-008 | "View live" button | FilledButton (full width) | Looks up the alert's camera (`alert.cameraId`) in `HomesController` and deep-links to [camera_live_screen.md](../camera_live/camera_live_screen.md) via `context.go('/dashboard/live/{cameraId}', extra: camera)` — switches to the Dashboard tab, landing directly on that camera's live view. Shows a "Camera unreachable" snackbar instead of navigating if no matching camera is found |
| ~~ALERTDET-009~~ | ~~"View recording" button~~ | — | Retired — duplicated ALERTDET-011's playback action; removed rather than kept disabled |
| ALERTDET-010 | Mark as read/unread toggle | IconButton (AppBar action) | Toggles `Alert.isRead` via `AlertsController` |
| ALERTDET-011 | Play button overlay | IconButton (over snapshot) | Tapping starts inline playback of the dummy video asset — the only way to start playback now |
| ALERTDET-012 | "Download snapshot" button | OutlinedButton | Fetches `snapshotUrl` bytes and saves to the device gallery via `Gal.putImageBytes`; shows a loading spinner and success/error snackbar |
| ALERTDET-013 | "Download clip" button | OutlinedButton | Copies the dummy video asset to a temp file and saves to the device gallery via `Gal.putVideo`; shows a loading spinner and success/error snackbar |
| ALERTDET-014 | Delete button | IconButton (AppBar action) | Confirms via dialog, then calls `AlertsController.deleteAlert` and pops back |
| ALERTDET-015 | Share button | IconButton (AppBar action) | Fetches `snapshotUrl` bytes, writes a temp file, and opens the OS share sheet via `share_plus` |
| ALERTDET-016 | Fullscreen toggle | IconButton (over video player) | Shown once playback starts; opens a landscape-locked fullscreen video page, same pattern as `camera_live_screen.dart`'s `_openFullscreen` |
| ALERTDET-017 | Snooze camera alerts button | OutlinedButton (full width) | Toggles `AlertsController.toggleCameraSnooze(cameraId)`; snoozed cameras' alerts are hidden from `AlertsScreen` (see `AlertsController.isCameraSnoozed`) |
| ALERTDET-018 | "Unread notifications — {camera}" section header | Text | Introduces the related-alerts row (renamed from "Unread motion — {camera}"; the row's content filter itself is still motion-only, only the label changed) |
| ALERTDET-019 | Related alerts list | Horizontal ListView of cards | Filtered to `AlertType.motion` **and** unread only (per explicit request — the list shrinks/empties as the user reads items, which was a deliberate tradeoff, not a bug). Unread cards get a cyan border + glow dot + bold label (in practice every card here is unread, since the row is unread-only). Tapping a card navigates to `AlertsScreen` pre-filtered to that camera, `AlertType.motion`, **and** the Unread read-state toggle, via `context.go('/alerts', extra: (cameraName, AlertType.motion, true))` — a 3-element Dart record (camera, type, unreadOnly), not a bare `String`. (Two earlier iterations of this wiring passed less: first just the camera name, then camera+type but not the read-state toggle — see AlertsScreen's `initialCameraFilter`/`initialTypeFilter`/`initialUnreadOnly`/`didUpdateWidget` notes.) It does **not** open that alert's own detail screen |
