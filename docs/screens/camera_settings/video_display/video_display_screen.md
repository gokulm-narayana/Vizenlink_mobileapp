# VideoDisplayScreen

- **Dart file:** `lib/screens/camera_settings/video_display_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/video-display`
- **Purpose:** Landing menu for the "Video & Display" section of camera settings, reached from [camera_settings_screen.md](../camera_settings_screen.md). Lists seven sections, each pushing its own sub-screen: [video_mode_screen.md](video_mode_screen.md), [night_mode_screen.md](night_mode_screen.md), [privacy_mode_screen.md](privacy_mode_screen.md), [on_screen_display_screen.md](on_screen_display_screen.md), [imaging_screen.md](imaging_screen.md), [video_encoder_screen.md](video_encoder_screen.md), [tags_screen.md](tags_screen.md). All sub-screens now persist their fields through `HomesController.updateCamera`, so reopening any of them reflects what was last saved; only Tags' Bitrate/Live Tag toggles currently have a visible effect elsewhere (on [camera_live_screen.md](../../camera_live/camera_live_screen.md)) — the rest have no visible effect yet since no CCTV protocol/backend is wired up (see CLAUDE.md), but are ready for one to read directly. This screen takes `homesController` purely to thread it down to each sub-screen.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| VIDDISP-001 | Screen title (AppBar) | Text | "Video & Display" |
| VIDDISP-002 | Video Mode row | ListTile (in GlassCard) | navigates to [video_mode_screen.md](video_mode_screen.md); subtitle "Day, Auto, or Night switching" |
| VIDDISP-003 | Night Mode row | ListTile (in GlassCard) | navigates to [night_mode_screen.md](night_mode_screen.md); subtitle "Infrared, Smart, or Full Color" |
| VIDDISP-005 | Privacy Mode row | ListTile (in GlassCard) | navigates to [privacy_mode_screen.md](privacy_mode_screen.md); subtitle "Block the feed fully or mask zones" |
| VIDDISP-006 | On-Screen Display row | ListTile (in GlassCard) | navigates to [on_screen_display_screen.md](on_screen_display_screen.md); subtitle "Time and custom text overlays" |
| VIDDISP-007 | Imaging row | ListTile (in GlassCard) | navigates to [imaging_screen.md](imaging_screen.md); subtitle "Brightness, contrast, WDR, exposure" |
| VIDDISP-008 | Video Encoder row | ListTile (in GlassCard) | navigates to [video_encoder_screen.md](video_encoder_screen.md); subtitle "Resolution, frame rate, bitrate, codec" |
| VIDDISP-011 | Tags row | ListTile (in GlassCard) | navigates to [tags_screen.md](tags_screen.md); subtitle "Live, bitrate, and signal strength badges" |

Each row's `ListTile.subtitle` is a short static description of what that sub-screen configures — pure copy, not tied to a design ID of its own.

VIDDISP-004 (previously "Video Quality") is retired — its resolution/frame rate fields moved into [video_encoder_screen.md](video_encoder_screen.md). VIDDISP-009 (previously "Audio") is retired — Audio moved to [camera_settings_screen.md](../camera_settings_screen.md) as CAMSET-007, since it's a camera-level setting rather than a video/display one.
