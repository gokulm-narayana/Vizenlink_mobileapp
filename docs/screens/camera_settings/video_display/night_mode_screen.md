# NightModeScreen

- **Dart file:** `lib/screens/camera_settings/night_mode_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/night-mode`
- **Purpose:** Reached from the "Night Mode" row on [video_display_screen.md](video_display_screen.md). Shows a preview/thumbnail of the camera's current feed and lets the user choose its night mode (Infrared / Smart / Full Color). State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| NIGHT-001 | Screen title (AppBar) | Text | "Night Mode" |
| NIGHT-004 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until the mode selection changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| NIGHT-005 | Camera preview/thumbnail | `CameraPreviewThumbnail` (shared widget, `lib/widgets/camera_preview_thumbnail.dart`) | 16:9, same placeholder gradient/icon pattern as `CameraTile` for null/loading/error states; also used by [video_mode_screen.md](video_mode_screen.md) |
| NIGHT-007 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | re-renders the preview (simulated ~600ms delay with a spinner in place of the icon); no real camera snapshot fetch exists yet; same widget used by [privacy_mode_screen.md](privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| NIGHT-006 | Mode selector | Row of 3 `ModeTile` (shared widget, `lib/widgets/mode_tile.dart`) | options: Infrared (moon icon), Smart (default, auto-awesome icon), Full Color (palette icon); selected tile is highlighted with a primary-color border/background; local state only; changing marks the screen dirty |
| NIGHT-008 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| NIGHT-009 | Discard button (in NIGHT-008) | TextButton | discards the change and leaves |
| NIGHT-010 | Save button (in NIGHT-008) | FilledButton | saves via `_save()` before leaving |

NIGHT-002 (previously Auto/On/Off) and NIGHT-003 (previously IR LED brightness slider) are retired — replaced by NIGHT-005/006 above.

Body uses `FixedPreviewLayout` (shared widget, `lib/widgets/fixed_preview_layout.dart`): the preview stays pinned at the top of the screen while only the controls below it scroll — the same layout used by every camera-settings screen with a preview (Video Mode, Imaging, On-Screen Display, Tags).

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
