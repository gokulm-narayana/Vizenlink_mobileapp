# PrivacyModeScreen

- **Dart file:** `lib/screens/camera_settings/privacy_mode_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/privacy-mode`
- **Purpose:** Reached from the "Privacy Mode" row on [video_display_screen.md](video_display_screen.md). Offers an Off / Full / Zone mode selector (PRIV-002): Off streams normally, Full blocks the entire feed, Zone masks only the drawn privacy zones — up to 8 draggable/resizable mask rectangles on the preview. Zones can be added/edited/removed regardless of the current mode, but the zones section (PRIV-006–009) is only shown while Zone is selected, since zones have no effect in Off or Full. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| PRIV-001 | Screen title (AppBar) | Text | "Privacy Mode" |
| PRIV-010 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| PRIV-004 | Camera preview with zone overlay | Custom widget (`_PrivacyPreview`), 16:9, fixed at the top of the screen via `FixedPreviewLayout` | when PRIV-002 is Full, shows a full opaque `_FullBlackoutOverlay` (icon + "Privacy Mode: Full") covering the whole preview instead of the camera image; otherwise renders every zone in `_zones` as the shared `ZoneOverlay` widget (`lib/widgets/drawable_zone.dart`, same one used by [intrusion_detection_screen.md](../detections/intrusion_detection_screen.md)) — regardless of Off/Zone mode, so zones stay editable even when not in effect. Tapping a zone selects it (highlighted border), dragging the zone body moves it, dragging any of its four corner handles resizes it (each corner drags freely while the opposite corner stays anchored), both clamped so the zone never leaves the preview bounds or shrinks below a minimum size (8% of preview width/height) |
| PRIV-005 | Refresh preview button | TextButton.icon | re-renders the preview (simulated ~600ms delay with a spinner in place of the icon); no real camera snapshot fetch exists yet |
| PRIV-002 | Mode selector | Row of 3 `ModeTile` (shared widget, `lib/widgets/mode_tile.dart`) | options: Off (default, eye icon), Full (eye-off icon), Zone (square icon); selecting a mode marks the screen dirty |
| PRIV-003 | Explanatory text | Text | text changes per selected mode (Off/Full/Zone), describing what that mode does |
| PRIV-006 | Add zone button | TextButton.icon | only shown when PRIV-002 is Zone; adds a new zone at a cascading default position/size; disabled once 8 zones exist; newly added zone becomes selected |
| PRIV-007 | Zone list | Column of `ZoneListTile` rows (shared widget, `lib/widgets/drawable_zone.dart`; "Zone N" + delete icon), only shown when Zone mode is selected and zones exist | tapping a row selects that zone (highlights it on the preview and in the list); each row's trailing delete icon removes just that zone |
| PRIV-008 | Delete selected zone button | OutlinedButton.icon | only shown when PRIV-002 is Zone; disabled unless a zone is selected; removes the selected zone |
| PRIV-009 | Clear all zones button | OutlinedButton.icon | only shown when PRIV-002 is Zone; disabled when there are no zones; removes every zone at once |
| PRIV-011 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| PRIV-012 | Discard button (in PRIV-011) | TextButton | discards the change and leaves |
| PRIV-013 | Save button (in PRIV-011) | FilledButton | saves via `_save()` before leaving |

Zones use the shared `DrawableZone` model (`lib/widgets/drawable_zone.dart`) — fractional `Rect` bounds (0–1) of the preview area, same pattern as the OSD/Tags screens' positioning, so they scale correctly with preview size — capped at 8 (`maxDrawableZones`, shared with Intrusion Detection). Zone count is shown next to the "Add zone" button as "Privacy zones (N/8)".

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
