# ImagingScreen

- **Dart file:** `lib/screens/camera_settings/imaging_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/imaging`
- **Purpose:** Reached from the "Imaging" row on [video_display_screen.md](video_display_screen.md). Lets the user adjust image characteristics: mirror/flip orientation, brightness/contrast/saturation/sharpness, WDR, white balance, and exposure, plus a preview thumbnail and a reset-to-default action. State is staged locally and only applied when Save is tapped. Backed by real `camera_api` when the camera has a saved connection: `OnvifImagingClient.getImagingSettings`/`getImagingOptions` load brightness/contrast/saturation/sharpness/WDR/white-balance/exposure and their real bounds/choice lists on screen open, and `setImagingSettings` pushes them on Save. Mirror/Flip is a separate NuraEye setting (`MirrorFlipClient.getMirrorFlip`/`setMirrorFlip`), loaded and saved alongside the imaging fields in the same round trip. Falls back to local-only `HomesController` state (`simulateCameraSave`) for a camera with no saved connection yet. WAN fallback isn't wired up yet.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| IMG-001 | Screen title (AppBar) | Text | "Imaging" |
| IMG-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while calling `OnvifImagingClient.setImagingSettings` + `MirrorFlipClient.setMirrorFlip` (real, when connected) or `simulateCameraSave` (local-only fallback), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| IMG-003 | Camera preview/thumbnail | `CameraPreviewThumbnail` (shared widget, `lib/widgets/camera_preview_thumbnail.dart`) | 16:9, same pattern as [video_mode_screen.md](video_mode_screen.md) |
| IMG-011 | Reset to Default button | OutlinedButton | top of the scrollable controls, right-aligned; resets all fields on this screen (IMG-004–010, IMG-012, IMG-013) to their hardcoded defaults (not the camera's own values); marks the screen dirty |
| IMG-004 | Mirror / Flip selector | SegmentedButton | options: Off (default), Mirror, Flip, Both — a fixed 4-value NuraEye enum with no ONVIF Options concept, so all 4 always show (no gating) |
| IMG-005 | Brightness slider | Slider | real min/max from `getImagingOptions().brightness` when connected, else 0–100 fallback |
| IMG-006 | Contrast slider | Slider | real min/max from `getImagingOptions().contrast`, else 0–100 fallback |
| IMG-007 | Saturation slider | Slider | real min/max from `getImagingOptions().colorSaturation`, else 0–100 fallback |
| IMG-008 | Sharpness slider | Slider | real min/max from `getImagingOptions().sharpness`, else 0–100 fallback |
| IMG-012 | WDR toggle | SwitchListTile | hidden outright (not just disabled) when `getImagingOptions().wdrSupported` is `false` — non-HDR sensors have no WDR element at all |
| IMG-013 | WDR level slider | Slider | 1–100, default 50; only rendered when IMG-012 is enabled and shown |
| IMG-009 | White balance selector | SegmentedButton | only shows the modes `getImagingOptions().whiteBalanceModes` actually reports (both Auto/Manual when unverified) |
| IMG-010 | Exposure selector | SegmentedButton | only shows the modes `getImagingOptions().exposureModes` actually reports (both Auto/Manual when unverified); manual exposure's numeric time/gain fields have no UI here yet |
| IMG-014 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | calls `refreshCameraSnapshot` (`lib/app_state/camera_sync.dart`) over LAN using this camera's saved connection, persists the real fetched snapshot via `HomesController.updateCamera`, and refreshes this screen's own preview immediately (reads a live `_camera` lookup each build, not the static `widget.camera` snapshot); shows a snackbar if the camera has no saved connection yet or the fetch fails; same widget used by [privacy_mode_screen.md](privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| IMG-015 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| IMG-016 | Discard button (in IMG-015) | TextButton | discards the change and leaves |
| IMG-017 | Save button (in IMG-015) | FilledButton | saves via `_save()` before leaving |

Body uses `FixedPreviewLayout` (shared widget, `lib/widgets/fixed_preview_layout.dart`): the preview stays pinned at the top of the screen while only the controls below it scroll — the same layout used by every camera-settings screen with a preview (Video Mode, Night Mode, On-Screen Display, Tags).

On successful save, values are persisted through `HomesController.updateCamera` — reopening this screen reflects whatever was last saved. For a camera with a saved connection, that save is now real ONVIF/NuraEye calls, and the local copy only updates once the camera confirms both.
