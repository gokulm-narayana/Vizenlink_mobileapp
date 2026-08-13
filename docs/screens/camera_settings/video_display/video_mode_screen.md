# VideoModeScreen

- **Dart file:** `lib/screens/camera_settings/video_mode_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/video-mode`
- **Purpose:** Reached from the "Video Mode" row on [video_display_screen.md](video_display_screen.md). Shows a preview/thumbnail of the camera's current feed and lets the user choose its video mode (Day / Auto / Night). State is staged locally and only applied when Save is tapped. Backed by real `camera_api` when the camera has a saved connection: `OnvifImagingClient.getImagingSettings`/`getImagingOptions` load the camera's actual `IrCutFilter` value and supported-mode list on screen open, and `setImagingSettings` pushes the choice on Save (`ON` = Day, `OFF` = Night, `AUTO` = Auto). Falls back to local-only `HomesController` state (`simulateCameraSave`) for a camera with no saved connection yet. WAN fallback (`WanImagingClient.getDayNightMode`/`setDayNightMode`) isn't wired up yet.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| VIDMODE-001 | Screen title (AppBar) | Text | "Video Mode" |
| VIDMODE-005 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until the mode selection changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while calling `OnvifImagingClient.setImagingSettings` (real, when connected) or `simulateCameraSave` (local-only fallback), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| VIDMODE-003 | Camera preview/thumbnail | `CameraPreviewThumbnail` (shared widget, `lib/widgets/camera_preview_thumbnail.dart`) | 16:9, same placeholder gradient/icon pattern as `CameraTile` for null/loading/error states; also used by [night_mode_screen.md](night_mode_screen.md) |
| VIDMODE-007 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | calls `refreshCameraSnapshot` (`lib/app_state/camera_sync.dart`) over LAN using this camera's saved connection, persists the real fetched snapshot via `HomesController.updateCamera`, and refreshes this screen's own preview immediately (reads a live `_camera` lookup each build, not the static `widget.camera` snapshot); shows a snackbar if the camera has no saved connection yet or the fetch fails; same widget used by [privacy_mode_screen.md](privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| VIDMODE-004 | Mode selector | Row of up to 3 `ModeTile` (shared widget, `lib/widgets/mode_tile.dart`) | options: Day (sun icon), Auto (default, autorenew icon), Night (moon icon); only renders a mode the camera's own `getImagingOptions().irCutFilterModes` actually reports (shows all 3 if unverified — no connection yet); selected tile is highlighted with a primary-color border/background; changing marks the screen dirty |

| VIDMODE-008 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| VIDMODE-009 | Discard button (in VIDMODE-008) | TextButton | discards the change and leaves |
| VIDMODE-010 | Save button (in VIDMODE-008) | FilledButton | saves via `_save()` before leaving |

VIDMODE-002 (previously Live/Recorded/Motion-triggered) is retired — replaced by VIDMODE-003/004 above.

Body uses `FixedPreviewLayout` (shared widget, `lib/widgets/fixed_preview_layout.dart`): the preview stays pinned at the top of the screen while only the controls below it scroll — the same layout used by every camera-settings screen with a preview (Night Mode, Imaging, On-Screen Display, Tags).

On successful save, values are persisted through `HomesController.updateCamera` — reopening this screen reflects whatever was last saved. For a camera with a saved connection, that save is now a real ONVIF `SetImagingSettings` call, and the local copy only updates once the camera confirms it.
