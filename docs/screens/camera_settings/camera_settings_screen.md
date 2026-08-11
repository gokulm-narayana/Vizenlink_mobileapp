# CameraSettingsScreen

- **Dart file:** `lib/screens/camera_settings/camera_settings_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings`
- **Purpose:** Landing menu for a camera's settings, reached from the gear icon on [camera_live_screen.md](../camera_live/camera_live_screen.md). Lists seven sections, each pushing its own sub-screen: [camera_info_screen.md](camera_info_screen.md), [video_display_screen.md](video_display/video_display_screen.md), [detections_screen.md](detections/detections_screen.md), [audio_screen.md](audio_screen.md), [recording_screen.md](recording_and_storage/recording_screen.md), [storage_screen.md](recording_and_storage/storage_screen.md), [danger_zone_screen.md](danger_zone_screen.md). Camera Info, Video & Display, Detections, Audio, Recording, and Storage are disabled while `camera.isOnline` is false, since none of them can reach an offline device; Danger Zone stays reachable (it gates Soft/Hard Reset individually and always allows Delete Camera — see [danger_zone_screen.md](danger_zone_screen.md)).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CAMSET-001 | Screen title (AppBar) | Text | "<camera name> Settings" |
| CAMSET-003 | Camera Info row | ListTile (in GlassCard) | navigates to [camera_info_screen.md](camera_info_screen.md); disabled (dimmed, "Camera is offline — reconnect to access" subtitle) when the camera is offline |
| CAMSET-004 | Video & Display row | ListTile (in GlassCard) | navigates to [video_display_screen.md](video_display/video_display_screen.md); disabled the same way when offline |
| CAMSET-005 | Detections row | ListTile (in GlassCard) | navigates to [detections_screen.md](detections/detections_screen.md); disabled the same way when offline |
| CAMSET-007 | Audio row | ListTile (in GlassCard) | navigates to [audio_screen.md](audio_screen.md); disabled the same way when offline |
| CAMSET-008 | Recording row | ListTile (in GlassCard) | navigates to [recording_screen.md](recording_and_storage/recording_screen.md); disabled the same way when offline |
| CAMSET-009 | Storage row | ListTile (in GlassCard) | navigates to [storage_screen.md](recording_and_storage/storage_screen.md); disabled the same way when offline |
| CAMSET-006 | Danger Zone row | ListTile (in GlassCard) | navigates to [danger_zone_screen.md](danger_zone_screen.md); icon/label tinted with the app's offline/danger color to signal destructive content; always enabled, even when the camera is offline |
