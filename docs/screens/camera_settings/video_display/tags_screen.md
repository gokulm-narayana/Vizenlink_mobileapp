# TagsScreen

- **Dart file:** `lib/screens/camera_settings/tags_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/tags`
- **Purpose:** Reached from the "Tags" row on [video_display_screen.md](video_display_screen.md). Lets the user toggle three status badges composited by the mobile app on top of the stream (not sent to or rendered by the camera): Live tag (fixed top-left), Bitrate, and Signal Strength — the latter two each independently positioned at one of four fixed preview corners. Unlike most camera-settings sub-screens, Save here is written through `HomesController.updateCameraOsdSettings`, so the toggles/positions take effect immediately on [camera_live_screen.md](../../camera_live/camera_live_screen.md) (LIVE-004/LIVE-029/LIVE-030) — not just this screen's own preview. No CCTV protocol/backend is wired up yet (see CLAUDE.md).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| TAG-001 | Screen title (AppBar) | Text | "Tags" |
| TAG-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now); on success commits all fields to `HomesController`, then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| TAG-003 | Live preview | Custom widget (`_TagsPreview`), 16:9 over `CameraPreviewThumbnail` | renders the shared `LiveStatusBadge`/`BitrateBadge`/`SignalStrengthBadge` widgets (when enabled) via `osdPositioned` (`lib/widgets/live_status_badges.dart`) — same widgets/helper used by [camera_live_screen.md](../../camera_live/camera_live_screen.md); no background box, plain white text/icons laid directly over the video. If two or more enabled tags share the same corner, `osdStackIndices` lines them up side by side, growing inward from that corner's horizontal edge (in Live tag → Bitrate → Signal Strength priority), so they don't render on top of each other |
| TAG-012 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | calls `refreshCameraSnapshot` (`lib/app_state/camera_sync.dart`) over LAN using this camera's saved connection, persists the real fetched snapshot via `HomesController.updateCamera`, and refreshes this screen's own preview immediately (reads a live `_camera` lookup each build, not the static `widget.camera` snapshot); shows a snackbar if the camera has no saved connection yet or the fetch fails; same widget used by [privacy_mode_screen.md](privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| TAG-005 | Live tag toggle | SwitchListTile | defaults on (mirrors `Camera.liveTagOsdEnabled`); always pinned to the top-left corner, no position control |
| TAG-004 | Bitrate toggle | SwitchListTile | defaults off (mirrors `Camera.bitrateOsdEnabled`) |
| TAG-006 | Bitrate position dropdown | DropdownButtonFormField (`OsdCorner`) | options: Top left, Top right, Bottom left, Bottom right (default); disabled when TAG-004 is off |
| TAG-007 | Signal strength toggle | SwitchListTile | defaults off (mirrors `Camera.signalStrengthOsdEnabled`); badge shows only bars icon (colored red at 0–1 bars/amber at 2/green at 3–4, from `camera.signalStrength`) plus the network speed auto-scaled to KB/s or MB/s (from `camera.networkSpeedKbps`, via `formatBitrate`) — no numeric bar count |
| TAG-008 | Signal strength position dropdown | DropdownButtonFormField (`OsdCorner`) | options: Top left, Top right (default), Bottom left, Bottom right; disabled when TAG-007 is off |
| TAG-013 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| TAG-014 | Discard button (in TAG-013) | TextButton | discards the change and leaves |
| TAG-015 | Save button (in TAG-013) | FilledButton | saves via `_save()` before leaving |

Body uses `FixedPreviewLayout` (shared widget, `lib/widgets/fixed_preview_layout.dart`): the preview stays pinned at the top of the screen while only the controls below it scroll — the same layout used by every camera-settings screen with a preview (Video Mode, Night Mode, Imaging, On-Screen Display).
