# VideoEncoderScreen

- **Dart file:** `lib/screens/camera_settings/video_encoder_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/video-encoder`
- **Purpose:** Reached from the "Video Encoder" row on [video_display_screen.md](video_display_screen.md). Lets the user configure the camera's stream encoding: resolution, video encoder (codec), encoder profile, frame rate, GOV (I-frame interval), quality, bitrate mode, and bitrate. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so field types/ranges are fixed rather than sourced from a real camera's reported capabilities, and Save does not persist beyond the screen's local state.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| ENC-001 | Screen title (AppBar) | Text | "Video Encoder" |
| ENC-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| ENC-014 | Reset to Default button | OutlinedButton | top of the scrollable list, right-aligned; resets all fields on this screen (ENC-003, ENC-007–013) to their defaults; marks the screen dirty |
| ENC-003 | Resolution selector | DropdownButtonFormField | options: 1080p (default), 720p, 480p |
| ENC-007 | Video encoder selector | DropdownButtonFormField | options: H.264 (default), H.265 |
| ENC-008 | Encoder profile selector | DropdownButtonFormField | options: Baseline, Main (default), High |
| ENC-009 | Frame rate slider | Slider | 1–25 fps, default 15 |
| ENC-010 | GOV slider | Slider | 10–50, default 30 |
| ENC-011 | Quality slider | Slider (5 discrete steps) | 1–5, default 3 |
| ENC-012 | Bitrate mode dropdown | DropdownButtonFormField | CBR (default) / VBR |
| ENC-013 | Bitrate slider | Slider | 32–8192 kbps, default 2048 |
| ENC-015 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| ENC-016 | Discard button (in ENC-015) | TextButton | discards the change and leaves |
| ENC-017 | Save button (in ENC-015) | FilledButton | saves via `_save()` before leaving |

ENC-004 (previously Frame Rate radio 15/24/30 fps), ENC-005 (previously Bitrate radio Low/Medium/High), and ENC-006 (previously Codec radio) are retired — ENC-006 is replaced by ENC-007 above.

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
