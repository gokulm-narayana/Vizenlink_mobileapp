# DangerZoneScreen

- **Dart file:** `lib/screens/camera_settings/danger_zone_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/danger-zone`
- **Purpose:** Reached from the "Danger Zone" row on [camera_settings_screen.md](camera_settings_screen.md). Offers Soft Reset and Hard Reset (grouped together — both require the camera to be online, since they round-trip to the device) and Delete Camera (its own group, allowed even while offline — it only removes the camera from local app state, no device round-trip needed). No CCTV protocol/backend is wired up yet (see CLAUDE.md), so the resets only simulate a round-trip via `simulateCameraSave`.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| DANGER-001 | Screen title (AppBar) | Text | "Danger Zone" |
| DANGER-003 | Warning intro text | Text | "These actions are destructive and, in most cases, cannot be undone. Proceed with care." |
| DANGER-004 | Soft Reset tile | `_DangerTile` (local widget) inside a `GlassCard`, grouped with DANGER-005 | disabled (dimmed, "Camera is offline — reconnect it to reboot." subtitle) when `!camera.isOnline`; otherwise shows "Reboots the camera. Settings and recordings are kept." Tapping opens a confirm dialog ("Soft reset camera?" / Cancel / Reboot); on confirm shows the full-screen `SavingOverlay` (label "Rebooting…") while simulating a camera round-trip (`simulateCameraSave`, ~800ms, always succeeds for now), then a "Camera is rebooting" snackbar, or a failure snackbar |
| DANGER-005 | Hard Reset tile | `_DangerTile`, grouped with DANGER-004 | disabled the same way as DANGER-004 when offline; otherwise shows "Erases all settings and restores factory defaults. This cannot be undone." Confirm dialog ("Hard reset camera?" / Cancel / Erase & Reset); on confirm shows `SavingOverlay` (label "Resetting…") simulating a round-trip, then a "Camera has been reset to factory defaults" snackbar, or a failure snackbar |
| DANGER-006 | Delete Camera tile | `_DangerTile` inside its own `GlassCard`, visually separated from the reset group | always enabled, even when the camera is offline — deleting doesn't need to reach the device. Confirm dialog ("Delete camera?" / Cancel / Delete); on confirm calls `HomesController.deleteCamera` (removes the camera from its home's camera list) and navigates to [dashboard_screen.md](../dashboard/dashboard_screen.md) via `context.go`, since the camera the user was viewing no longer exists |

DANGER-002 (previously a "coming soon" placeholder message) is retired — replaced by real content above.
