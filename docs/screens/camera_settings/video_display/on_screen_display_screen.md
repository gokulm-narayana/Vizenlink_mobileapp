# OnScreenDisplayScreen

- **Dart file:** `lib/screens/camera_settings/on_screen_display_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/on-screen-display`
- **Purpose:** Reached from the "On-Screen Display" row on [video_display_screen.md](video_display_screen.md). Shows a live preview of the camera feed with Time and Custom Text overlays, each independently positioned (one of 4 fixed corners, or Custom — freely draggable) and colored. All state here is local-only draft state — it only affects this screen's own preview and is not persisted or shown elsewhere (no CCTV protocol/backend is wired up yet, see CLAUDE.md). Bitrate and Signal Strength (app-side, non-draggable status badges that actually apply to the Camera Live page) live on the separate [tags_screen.md](tags_screen.md), not here.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| OSD-001 | Screen title (AppBar) | Text | "On-Screen Display" |
| OSD-004 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| OSD-005 | Live preview | Custom widget (`_OsdPreview`), 16:9 over `CameraPreviewThumbnail` | renders the Time and Custom Text overlays (when enabled) via `_OverlayChip`, at their fixed-corner or custom-dragged position |
| OSD-018 | Refresh preview button | `RefreshPreviewButton` (shared widget, `lib/widgets/refresh_preview_button.dart`) | re-renders the whole OSD-005 preview stack, i.e. the underlying `CameraPreviewThumbnail` plus overlay chips (simulated ~600ms delay with a spinner in place of the icon); no real camera snapshot fetch exists yet; same widget used by [privacy_mode_screen.md](privacy_mode_screen.md) (PRIV-005) and every other preview screen |
| OSD-006 | Time toggle | SwitchListTile | defaults on |
| OSD-016 | Date format dropdown | DropdownButtonFormField | options: `YYYY-MM-DD` (default), `DD-MM-YYYY`, `MM-DD-YYYY`; disabled when OSD-006 is off |
| OSD-017 | Time format dropdown | DropdownButtonFormField | options: 24-hour (default), 12-hour; disabled when OSD-006 is off |
| OSD-012 | Time position dropdown | DropdownButtonFormField | options: Top left, Top right, Bottom left, Bottom right, Custom (default) — picking a fixed corner snaps the overlay there and disables dragging; picking Custom re-enables free dragging on OSD-005 from wherever it last was; disabled when OSD-006 is off |
| OSD-013 | Time color picker | `ColorPickerField` (shared widget, `lib/widgets/color_picker_field.dart`) | swatch + hex value; tapping opens a dialog with an HSV saturation/value square and hue slider (plain-Flutter, no external package) to pick any color; sets the Time overlay's text color; disabled (dimmed) when OSD-006 is off |
| OSD-007 | Custom text toggle | SwitchListTile | defaults off |
| OSD-008 | Custom text input | TextField | enabled only when OSD-007 is on |
| OSD-014 | Custom text position dropdown | DropdownButtonFormField | same 5 options as OSD-012 (default: Custom); disabled when OSD-007 is off |
| OSD-015 | Custom text color picker | `ColorPickerField` | same as OSD-013; disabled (dimmed) when OSD-007 is off |
| OSD-019 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| OSD-020 | Discard button (in OSD-019) | TextButton | discards the change and leaves |
| OSD-021 | Save button (in OSD-019) | FilledButton | saves via `_save()` before leaving |

The Time overlay always shows date + time combined (e.g. "2026-08-05 14:05"), formatted per OSD-016/OSD-017 independently — there's no separate show/hide for date vs. time.

When a Time/Custom Text position dropdown is set to Custom, a "Drag on the preview to reposition" hint appears underneath it (persistent, not a one-time snackar) as long as Custom stays selected.

Both overlays use `_OverlayChip`: for fixed corners, positioned directly (no drag); for Custom, freeform drag via `GestureDetector.onPanUpdate`, position stored as a fractional offset (0–1) of the preview size. The chip measures its own rendered size after layout (via a `GlobalKey`/`RenderBox`, since text width varies with content) and clamps against that actual footprint rather than a guessed constant, including re-clamping when content changes size without a drag (e.g. picking a longer timestamp format while positioned near an edge).

OSD-002/OSD-003 (previously "Show timestamp"/"Show camera name") and OSD-009/OSD-010 (previously "Bitrate OSD"/"Live tag OSD", moved to [tags_screen.md](tags_screen.md) as TAG-004/TAG-005) are retired.

Body uses `FixedPreviewLayout` (shared widget, `lib/widgets/fixed_preview_layout.dart`): the preview stays pinned at the top of the screen while only the controls below it scroll — the same layout used by every camera-settings screen with a preview (Video Mode, Night Mode, Imaging, Tags).
