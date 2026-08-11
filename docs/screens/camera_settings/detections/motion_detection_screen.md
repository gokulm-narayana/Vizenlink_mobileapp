# MotionDetectionScreen

- **Dart file:** `lib/screens/camera_settings/motion_detection_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/detections/motion-detection`
- **Purpose:** Reached from the "Motion Detection" row on [detections_screen.md](detections_screen.md). Lets the user enable motion detection and set its sensitivity. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| MOTION-001 | Screen title (AppBar) | Text | "Motion Detection" |
| MOTION-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| MOTION-005 | Camera preview | `CameraPreviewThumbnail` (shared widget, `lib/widgets/camera_preview_thumbnail.dart`), fixed at the top via `FixedPreviewLayout` | reference only — no drawing/interaction |
| MOTION-007 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | re-renders the preview (simulated ~600ms delay with a spinner in place of the icon); no real camera snapshot fetch exists yet; same widget used by [privacy_mode_screen.md](../video_display/privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| MOTION-003 | Motion detection toggle | SwitchListTile | defaults off |
| MOTION-004 | Sensitivity slider | Slider | 0–100, default 50; disabled when MOTION-003 is off |
| MOTION-008 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| MOTION-009 | Discard button (in MOTION-008) | TextButton | discards the change and leaves |
| MOTION-010 | Save button (in MOTION-008) | FilledButton | saves via `_save()` before leaving |

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
