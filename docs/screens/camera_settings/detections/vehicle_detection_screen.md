# VehicleDetectionScreen

- **Dart file:** `lib/screens/camera_settings/vehicle_detection_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/detections/vehicle-detection`
- **Purpose:** Reached from the "Vehicle Detection" row on [detections_screen.md](detections_screen.md). Lets the user enable AI-based vehicle detection and set its confidence threshold. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| VEHICLE-001 | Screen title (AppBar) | Text | "Vehicle Detection" |
| VEHICLE-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| VEHICLE-005 | Camera preview | `CameraPreviewThumbnail` (shared widget, `lib/widgets/camera_preview_thumbnail.dart`), fixed at the top via `FixedPreviewLayout` | reference only — no drawing/interaction |
| VEHICLE-007 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | calls `refreshCameraSnapshot` (`lib/app_state/camera_sync.dart`) over LAN using this camera's saved connection, persists the real fetched snapshot via `HomesController.updateCamera`, and refreshes this screen's own preview immediately (reads a live `_camera` lookup each build, not the static `widget.camera` snapshot); shows a snackbar if the camera has no saved connection yet or the fetch fails; same widget used by [privacy_mode_screen.md](../video_display/privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| VEHICLE-003 | Vehicle detection toggle | SwitchListTile | defaults off |
| VEHICLE-004 | Confidence threshold slider | Slider | 0–100, default 50; disabled when VEHICLE-003 is off |
| VEHICLE-008 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| VEHICLE-009 | Discard button (in VEHICLE-008) | TextButton | discards the change and leaves |
| VEHICLE-010 | Save button (in VEHICLE-008) | FilledButton | saves via `_save()` before leaving |

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
