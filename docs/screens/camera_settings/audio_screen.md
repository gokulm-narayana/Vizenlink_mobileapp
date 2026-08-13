# AudioScreen

- **Dart file:** `lib/screens/camera_settings/audio_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/audio`
- **Purpose:** Reached from the "Audio" row on [camera_settings_screen.md](camera_settings_screen.md) (a top-level camera setting, not nested under Video & Display). Lets the user toggle whether recordings include an audio track, adjust the camera's speaker volume and microphone gain, and play a test sound through the camera's speaker. State is staged locally and only applied when Save is tapped. Backed by real `camera_api` (`AudioCapabilityClient`/`AudioVolumeClient`/`SpeakerVolumeClient`, LAN only — no WAN fallback wired up yet, same gap as every other settings screen so far) when the camera has a saved connection, loaded on screen open; falls back to local-only `HomesController` state (`simulateCameraSave`) for a camera with no saved connection. Speaker volume (AUD-006) and Test Sound (AUD-008) are hidden when the camera reports no speaker hardware; "Record Audio" (AUD-012) and Microphone gain (AUD-007) are hidden when it reports no microphone hardware — gated on `AudioCapabilityClient.getAudioCapability()`, per `.claude/rules/mobile-app-screen-conventions.md` item 5. Test Sound plays a real test tone via `AudioVolumeClient.playTestSound()` when a connection exists.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| AUD-001 | Screen title (AppBar) | Text | "Audio" |
| AUD-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while pushing changes via `AudioVolumeClient.setMicGain`/`setAudioRecordingEnabled` and `SpeakerVolumeClient.setSpeakerVolume` (each gated on the matching `AudioCapability` flag) when the camera has a saved connection, or `simulateCameraSave` (~800ms, always succeeds) otherwise, then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure. Note: Test Sound (AUD-008) has its own separate loading state and is unaffected by this overlay. |
| AUD-012 | "Record Audio" toggle | SwitchListTile (in GlassCard, above AUD-006) | independent of AUD-006/007 (speaker volume/mic gain affect two-way talk + warning playback, not what gets recorded); controls `Camera.audioRecordingEnabled`, backed by `AudioVolumeClient.isAudioRecordingEnabled`/`setAudioRecordingEnabled` (LAN-only, no WAN mirror). Hidden when `AudioCapability.hasMicrophone` is `false`. When on, shows a persistent mic-icon indicator in live view — see [camera_live_screen.md](../camera_live/camera_live_screen.md)'s LIVE-037 |
| AUD-006 | Speaker volume slider | Slider | 0–100, default 50; backed by `SpeakerVolumeClient.getSpeakerVolume`/`setSpeakerVolume`. Hidden when `AudioCapability.hasSpeaker` is `false` |
| AUD-007 | Microphone gain slider | Slider | 0–100, default 50; backed by `AudioVolumeClient.getMicGain`/`setMicGain`. Hidden when `AudioCapability.hasMicrophone` is `false` |
| AUD-008 | Test Sound button | OutlinedButton.icon (play icon) | plays a test sound on the camera's speaker via `AudioVolumeClient.playTestSound()` when a connection exists (falls back to a 2s simulated delay otherwise); shows a spinner in place of the play icon while playing and a "Playing test sound on camera speaker…" snackbar; disabled while playing. Hidden when `AudioCapability.hasSpeaker` is `false` |
| AUD-009 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| AUD-010 | Discard button (in AUD-009) | TextButton | discards the change and leaves |
| AUD-011 | Save button (in AUD-009) | FilledButton | saves via `_save()` before leaving |

AUD-003 (previously microphone toggle), AUD-004 (previously microphone volume slider), and AUD-005 (previously two-way audio toggle) are retired — replaced by AUD-006/007/008 above.

On successful save, values are persisted both to the camera (when a connection exists) and through `HomesController.updateCamera` — reopening this screen reflects whatever was last saved. `AudioCapability` (hardware presence) is refreshed each time the screen is opened, not cached across screens.
