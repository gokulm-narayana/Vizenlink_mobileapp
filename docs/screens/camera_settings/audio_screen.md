# AudioScreen

- **Dart file:** `lib/screens/camera_settings/audio_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/audio`
- **Purpose:** Reached from the "Audio" row on [camera_settings_screen.md](camera_settings_screen.md) (a top-level camera setting, not nested under Video & Display). Lets the user toggle whether recordings include an audio track, adjust the camera's speaker volume and microphone gain, and play a test sound through the camera's speaker. State is staged locally and only applied when Save is tapped — no CCTV protocol/backend is wired up yet (see CLAUDE.md), so Save does not persist beyond the screen's local state, and Test Sound only simulates playback (button shows a brief loading state plus a snackbar).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| AUD-001 | Screen title (AppBar) | Text | "Audio" |
| AUD-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure. Note: Test Sound (AUD-008) has its own separate loading state and is unaffected by this overlay. |
| AUD-012 | "Record Audio" toggle | SwitchListTile (in GlassCard, above AUD-006) | independent of AUD-006/007 (speaker volume/mic gain affect two-way talk + warning playback, not what gets recorded); controls `Camera.audioRecordingEnabled`. When on, shows a persistent mic-icon indicator in live view — see [camera_live_screen.md](../camera_live/camera_live_screen.md)'s LIVE-037 |
| AUD-006 | Speaker volume slider | Slider | 0–100, default 50 |
| AUD-007 | Microphone gain slider | Slider | 0–100, default 50 |
| AUD-008 | Test Sound button | OutlinedButton.icon (play icon) | plays a simulated test sound on the camera's speaker; shows a spinner in place of the play icon for ~2s and a "Playing test sound on camera speaker…" snackbar; disabled while playing |
| AUD-009 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| AUD-010 | Discard button (in AUD-009) | TextButton | discards the change and leaves |
| AUD-011 | Save button (in AUD-009) | FilledButton | saves via `_save()` before leaving |

AUD-003 (previously microphone toggle), AUD-004 (previously microphone volume slider), and AUD-005 (previously two-way audio toggle) are retired — replaced by AUD-006/007/008 above.

On successful save, values are now persisted through `HomesController.updateCamera` (not just cosmetically shown as saved) — reopening this screen reflects whatever was last saved, and once a real CCTV stream is wired up (see CLAUDE.md), it can read these `Camera` fields directly with no further plumbing needed.
