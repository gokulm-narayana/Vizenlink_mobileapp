# DetectionsScreen

- **Dart file:** `lib/screens/camera_settings/detections_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/detections`
- **Purpose:** Landing menu for the "Detections" row on [camera_settings_screen.md](../camera_settings_screen.md). Lists five detection types, each pushing its own sub-screen: [motion_detection_screen.md](motion_detection_screen.md), [intrusion_detection_screen.md](intrusion_detection_screen.md), [line_crossing_screen.md](line_crossing_screen.md), [person_detection_screen.md](person_detection_screen.md), [vehicle_detection_screen.md](vehicle_detection_screen.md). Sub-screens persist their fields through `HomesController.updateCamera` (reopening reflects what was last saved), though none have a visible effect yet since no CCTV protocol/backend is wired up (see CLAUDE.md).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| DETECT-001 | Screen title (AppBar) | Text | "Detections" |
| DETECT-003 | Motion Detection row | ListTile (in GlassCard) | navigates to [motion_detection_screen.md](motion_detection_screen.md); subtitle "Trigger on any movement in view" |
| DETECT-004 | Intrusion Detection row | ListTile (in GlassCard) | navigates to [intrusion_detection_screen.md](intrusion_detection_screen.md); subtitle "Trigger zones for restricted areas" |
| DETECT-005 | Line Crossing row | ListTile (in GlassCard) | navigates to [line_crossing_screen.md](line_crossing_screen.md); subtitle "Trigger when a line is crossed" |
| DETECT-006 | Person Detection row | ListTile (in GlassCard) | navigates to [person_detection_screen.md](person_detection_screen.md); subtitle "AI-based human detection" |
| DETECT-007 | Vehicle Detection row | ListTile (in GlassCard) | navigates to [vehicle_detection_screen.md](vehicle_detection_screen.md); subtitle "AI-based vehicle detection" |

DETECT-002 (previously the "Detection settings are coming soon." placeholder message) is retired.
