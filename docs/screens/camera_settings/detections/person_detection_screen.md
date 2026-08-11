# PersonDetectionScreen

- **Dart file:** `lib/screens/camera_settings/person_detection_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/detections/person-detection`
- **Purpose:** Reached from the "Person Detection" row on [detections_screen.md](detections_screen.md). Lets the user enable AI-based person detection, set its confidence threshold, and draw up to 8 free-form polygon exclusion zones on the preview — person detection ignores movement inside these zones (e.g. a street or a neighbor's yard visible in frame) and still detects normally everywhere else. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| PERSON-001 | Screen title (AppBar) | Text | "Person Detection" |
| PERSON-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| PERSON-006 | Camera preview with exclusion-zone overlay | Custom widget (`_PersonPreview`), 16:9, fixed at the top via `FixedPreviewLayout` | renders every completed zone (and the in-progress draft zone, if any) via the shared `PolygonOverlay` widget (`lib/widgets/drawable_zone.dart`) — an outline (filled once 3+ points close it) with a draggable circular handle per vertex; each handle drags independently, clamped to stay within the preview bounds |
| PERSON-007 | Refresh preview button | TextButton.icon | re-renders the preview (simulated ~600ms delay with a spinner in place of the icon); no real camera snapshot fetch exists yet |
| PERSON-003 | Person detection toggle | SwitchListTile | defaults off |
| PERSON-004 | Confidence threshold slider | Slider | 0–100, default 50; disabled when PERSON-003 is off |
| PERSON-008 | Add point button | TextButton.icon | adds a vertex to the in-progress draft zone (starting a new one if none is in progress) at a staggered default position, then draggable into place; disabled once 8 zones (completed + draft) exist |
| PERSON-009 | Finish zone button | FilledButton.icon, only shown while a draft zone exists | disabled until the draft has 3+ points (label shows how many more are needed); tapping closes the draft into a saved zone. A "Cancel" TextButton next to it discards the in-progress draft |
| PERSON-010 | Zone list | Column of `PolygonZoneListTile` rows (shared widget, `lib/widgets/drawable_zone.dart`; "Zone N" + delete icon), only shown when completed zones exist | tapping a row selects that zone (highlights it on the preview and in the list); each row's trailing delete icon removes just that zone |
| PERSON-011 | Delete selected zone button | OutlinedButton.icon | disabled unless a completed zone is selected (and no draft is in progress); removes the selected zone |
| PERSON-012 | Clear all zones button | OutlinedButton.icon | disabled when there are no zones (completed or draft); removes every zone at once |
| PERSON-013 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| PERSON-014 | Discard button (in PERSON-013) | TextButton | discards the change and leaves |
| PERSON-015 | Save button (in PERSON-013) | FilledButton | saves via `_save()` before leaving |

Zones use the shared `PolygonZone` model (`lib/widgets/drawable_zone.dart`) — an ordered list of fractional `Offset` vertices (0–1) of the preview area — capped at 8 total (`maxDrawableZones`, shared with Intrusion Detection/Privacy Mode's rectangle zones). Unlike those two screens' `DrawableZone` rectangles, polygon zones are free-form shapes built one point at a time via the Add point / Finish zone workflow rather than dragged out from a default size.

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
