# LineCrossingScreen

- **Dart file:** `lib/screens/camera_settings/line_crossing_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/detections/line-crossing`
- **Purpose:** Reached from the "Line Crossing" row on [detections_screen.md](detections_screen.md). Lets the user enable line-crossing detection, set its sensitivity, draw a single detection line on the preview, and choose which crossing direction(s) trigger it. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| LINE-001 | Screen title (AppBar) | Text | "Line Crossing" |
| LINE-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| LINE-003 | Camera preview with line overlay | Custom widget (`_LineCrossingPreview`), 16:9, fixed at the top via `FixedPreviewLayout` | renders a single line (`_LineOverlay`/`_LinePainter`) between two draggable circular handles; each handle drags independently, clamped to stay within the preview bounds; position stored as fractional (0–1) start/end offsets |
| LINE-004 | Refresh preview button | TextButton.icon | calls `refreshCameraSnapshot` (`lib/app_state/camera_sync.dart`) over LAN using this camera's saved connection, persists the real fetched snapshot via `HomesController.updateCamera`, and refreshes this screen's own preview immediately (reads a live `_camera` lookup each build, not the static `widget.camera` snapshot); shows a snackbar if the camera has no saved connection yet or the fetch fails |
| LINE-005 | Line crossing detection toggle | SwitchListTile | defaults off |
| LINE-006 | Sensitivity slider | Slider | 0–100, default 50; disabled when LINE-005 is off |
| LINE-007 | Direction dropdown | DropdownButtonFormField | options: Both directions (default), A → B only, B → A only; disabled when LINE-005 is off |
| LINE-008 | Reset line position button | OutlinedButton.icon | resets the line to its default position (centered horizontally, 20%–80% width) |
| LINE-009 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| LINE-010 | Discard button (in LINE-009) | TextButton | discards the change and leaves |
| LINE-011 | Save button (in LINE-009) | FilledButton | saves via `_save()` before leaving |

Only one line can be drawn (no add/delete list, unlike Intrusion Detection's multi-zone support) — dragging a handle repositions that endpoint directly.

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
