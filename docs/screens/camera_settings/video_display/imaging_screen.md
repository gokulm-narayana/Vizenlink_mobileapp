# ImagingScreen

- **Dart file:** `lib/screens/camera_settings/imaging_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/imaging`
- **Purpose:** Reached from the "Imaging" row on [video_display_screen.md](video_display_screen.md). Lets the user adjust image characteristics: mirror/flip orientation, brightness/contrast/saturation/sharpness, WDR, white balance, and exposure, plus a preview thumbnail and a reset-to-default action. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| IMG-001 | Screen title (AppBar) | Text | "Imaging" |
| IMG-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| IMG-003 | Camera preview/thumbnail | `CameraPreviewThumbnail` (shared widget, `lib/widgets/camera_preview_thumbnail.dart`) | 16:9, same pattern as [video_mode_screen.md](video_mode_screen.md) |
| IMG-011 | Reset to Default button | OutlinedButton | top of the scrollable controls, right-aligned; resets all fields on this screen (IMG-004–010, IMG-012, IMG-013) to their defaults; marks the screen dirty |
| IMG-004 | Mirror / Flip selector | SegmentedButton | options: Off (default), Mirror, Flip, Both |
| IMG-005 | Brightness slider | Slider | 0–100, default 50 |
| IMG-006 | Contrast slider | Slider | 0–100, default 50 |
| IMG-007 | Saturation slider | Slider | 0–100, default 50 |
| IMG-008 | Sharpness slider | Slider | 0–100, default 50 |
| IMG-012 | WDR toggle | SwitchListTile | defaults off |
| IMG-013 | WDR level slider | Slider | 1–100, default 50; only rendered when IMG-012 is enabled |
| IMG-009 | White balance selector | SegmentedButton | Auto (default) / Manual |
| IMG-010 | Exposure selector | SegmentedButton | Auto (default) / Manual |
| IMG-014 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | re-renders the preview (simulated ~600ms delay with a spinner in place of the icon); no real camera snapshot fetch exists yet; same widget used by [privacy_mode_screen.md](privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| IMG-015 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| IMG-016 | Discard button (in IMG-015) | TextButton | discards the change and leaves |
| IMG-017 | Save button (in IMG-015) | FilledButton | saves via `_save()` before leaving |

Body uses `FixedPreviewLayout` (shared widget, `lib/widgets/fixed_preview_layout.dart`): the preview stays pinned at the top of the screen while only the controls below it scroll — the same layout used by every camera-settings screen with a preview (Video Mode, Night Mode, On-Screen Display, Tags).

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
