# IntrusionDetectionScreen

- **Dart file:** `lib/screens/camera_settings/intrusion_detection_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/detections/intrusion-detection`
- **Purpose:** Reached from the "Intrusion Detection" row on [detections_screen.md](detections_screen.md). Lets the user enable intrusion detection, set its sensitivity, and draw up to 8 trigger zones on the preview — detection only fires within these zones. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| INTRUDE-001 | Screen title (AppBar) | Text | "Intrusion Detection" |
| INTRUDE-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| INTRUDE-003 | Camera preview with zone overlay | Custom widget (`_IntrusionPreview`), 16:9, fixed at the top via `FixedPreviewLayout` | renders every zone via the shared `ZoneOverlay` widget (`lib/widgets/drawable_zone.dart`); tapping a zone selects it (highlighted border); dragging the zone body moves it, dragging any of its four corner handles resizes it (each corner drags freely while the opposite corner stays anchored) — both clamped so the zone never leaves the preview bounds or shrinks below a minimum size (8% of preview width/height) |
| INTRUDE-004 | Refresh preview button | TextButton.icon | calls `refreshCameraSnapshot` (`lib/app_state/camera_sync.dart`) over LAN using this camera's saved connection, persists the real fetched snapshot via `HomesController.updateCamera`, and refreshes this screen's own preview immediately (reads a live `_camera` lookup each build, not the static `widget.camera` snapshot); shows a snackbar if the camera has no saved connection yet or the fetch fails |
| INTRUDE-005 | Intrusion detection toggle | SwitchListTile | defaults off |
| INTRUDE-006 | Sensitivity slider | Slider | 0–100, default 50; disabled when INTRUDE-005 is off |
| INTRUDE-007 | Add zone button | TextButton.icon | adds a new zone at a cascading default position/size; disabled once 8 zones exist; newly added zone becomes selected |
| INTRUDE-014 | Draw-new-zone surface | `ZoneDrawSurface` (shared widget, `lib/widgets/drawable_zone.dart`), overlaid on INTRUDE-003 underneath the existing `ZoneOverlay`s | alternative to INTRUDE-007: drag a rough rectangle directly on the preview (thin white line while dragging), or tap once for a default-size zone centered on the tap — either way it becomes a real zone (same `_addZoneAt` path INTRUDE-007 uses) the instant the gesture ends, immediately selected and draggable/resizable like any other zone. Sits *below* the `ZoneOverlay`s in the `Stack` so dragging an existing zone still moves/resizes it rather than starting a new draw. Disabled once 8 zones exist, same as INTRUDE-007 |
| INTRUDE-008 | Zone list | Column of rows ("Zone N" + delete icon), only shown when zones exist | tapping a row selects that zone (highlights it on the preview and in the list); each row's trailing delete icon removes just that zone |
| INTRUDE-009 | Delete selected zone button | OutlinedButton.icon | disabled unless a zone is selected; removes the selected zone |
| INTRUDE-010 | Clear all zones button | OutlinedButton.icon | disabled when there are no zones; removes every zone at once |
| INTRUDE-011 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| INTRUDE-012 | Discard button (in INTRUDE-011) | TextButton | discards the change and leaves |
| INTRUDE-013 | Save button (in INTRUDE-011) | FilledButton | saves via `_save()` before leaving |

Zones use the shared `DrawableZone` model and `ZoneOverlay`/`ZoneListTile`/`ZoneDrawSurface` widgets (`lib/widgets/drawable_zone.dart`), the same mechanics as [privacy_mode_screen.md](../video_display/privacy_mode_screen.md)'s privacy zones — stored as fractional `Rect` bounds (0–1) of the preview area, capped at 8 (`maxDrawableZones`).

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
