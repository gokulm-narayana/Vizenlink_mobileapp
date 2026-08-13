# VideoEncoderScreen

- **Dart file:** `lib/screens/camera_settings/video_encoder_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display/video-encoder`
- **Purpose:** Reached from the "Video Encoder" row on [video_display_screen.md](video_display_screen.md). Lets the user configure the camera's stream encoding: resolution, video encoder (codec), encoder profile, frame rate, GOV (I-frame interval), quality, bitrate mode, and bitrate. State is staged locally and only applied when Save is tapped. Backed by real `camera_api` when the camera has a saved connection: `OnvifVideoEncoderClient.getVideoEncoderSettings`/`getVideoEncoderSettingsOptions` (the high-res `VideoEncoderCfg_1` profile, via ONVIF Media2) load every field plus its real bounds/choice list — which differ per codec (H264 vs H265) on this firmware — on screen open, and `setVideoEncoderSettings` (which always sends the full config; there's no partial-update mode over SOAP) pushes them on Save. Falls back to local-only `HomesController` state (`simulateCameraSave`) for a camera with no saved connection yet. WAN fallback (`WanVideoEncoderClient`) isn't wired up yet.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| ENC-001 | Screen title (AppBar) | Text | "Video Encoder" |
| ENC-002 | Save button (AppBar action) | `SettingsSaveButton` (shared widget, `lib/widgets/settings_save_button.dart`) | disabled until a field changes or while saving; tapping triggers the full-screen `SavingOverlay` (dimmed backdrop + centered "Saving…" card) while calling `OnvifVideoEncoderClient.setVideoEncoderSettings` (real, when connected) or `simulateCameraSave` (local-only fallback), then shows a "Changes saved" snackbar, or an error snackbar with the button re-enabled on failure |
| ENC-014 | Reset to Default button | OutlinedButton | top of the scrollable list, right-aligned; resets all fields on this screen (ENC-003, ENC-007–013) to their hardcoded defaults (not the camera's own values); marks the screen dirty |
| ENC-003 | Resolution selector | DropdownButtonFormField, or a read-only Text label | becomes a plain label instead of a dropdown when the camera's `getVideoEncoderSettingsOptions()` reports only one valid resolution for the current codec — the common case on this firmware today, per that response's own doc ("`ONVIF_MAX_VENC_OPTIONS_RESOLUTION_COUNT == 1`"); shows the fixed 1080p/720p/480p dropdown when unverified or genuinely multi-valued |
| ENC-007 | Video encoder selector | DropdownButtonFormField | options: H.264, H.265 — filtered to `getVideoEncoderSettingsOptions().availableEncodings` when connected (both shown when unverified) |
| ENC-008 | Encoder profile selector | DropdownButtonFormField | options: Baseline, Main, High — filtered to the current codec's own `encoderProfiles` list (bounds differ per codec on this firmware) |
| ENC-009 | Frame rate slider | Slider | real min/max from the current codec's `frameRateRange`, else 1–25 fps fallback |
| ENC-010 | GOV slider | Slider | real min/max from `govLengthRange`, else 10–50 fallback |
| ENC-011 | Quality slider | Slider | real min/max from `qualityRange` (ONVIF quality is typically 1–10, not this screen's old fixed 1–5), else 1–5 fallback |
| ENC-012 | Bitrate mode dropdown | DropdownButtonFormField | VBR always shown; CBR hidden outright (not just disabled) when the current codec's `supportsCbr` is `false` |
| ENC-013 | Bitrate slider | Slider | real min/max from `bitrateRange`, else 32–8192 kbps fallback |
| ENC-015 | Unsaved-changes dialog | AlertDialog (shared, `confirmDiscardOnLeave` in `lib/widgets/navigation_leave_guard.dart`) | shown when leaving (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget) while dirty |
| ENC-016 | Discard button (in ENC-015) | TextButton | discards the change and leaves |
| ENC-017 | Save button (in ENC-015) | FilledButton | saves via `_save()` before leaving |

ENC-004 (previously Frame Rate radio 15/24/30 fps), ENC-005 (previously Bitrate radio Low/Medium/High), and ENC-006 (previously Codec radio) are retired — ENC-006 is replaced by ENC-007 above.

On successful save, values are persisted through `HomesController.updateCamera` — reopening this screen reflects whatever was last saved. For a camera with a saved connection, that save is now a real `SetVideoEncoderConfiguration` call, and the local copy only updates once the camera confirms it.
