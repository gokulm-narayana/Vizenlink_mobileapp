# Scan for cameras

Two-part flow: a centered scanning popup, then a dedicated results page.

## Scanning popup

- **Dart file:** `lib/screens/scan/scanning_popup.dart`
- **Presented via:** `showDialog` from the Dashboard's "Add Camera" FAB — a small centered dialog box (not full-width), dimmed background behind it.
- **Purpose:** Show simulated scan progress for ~2s before navigating to the results page.

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SCAN-001 | Scanning popup | AlertDialog (compact, centered) | spinner + "Scanning for cameras…" text; auto-dismisses and navigates to ScannedDevicesScreen when the simulated scan completes |

## ScannedDevicesScreen

- **Dart file:** `lib/screens/scan/scanned_devices_screen.dart`
- **Route:** `/dashboard/scan`
- **Purpose:** Run a real LAN discovery scan (`camera_api`'s `WsDiscoveryClient`) and let the user set up and add found cameras to the currently selected home. Discovery is real; per-camera identity/setup-state detection and the actual "Connect" call to the camera are not wired up yet (see Notes).

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SCAN-003 | App bar title ("Scanned devices") | AppBar | |
| SCAN-006 | Rescan button | IconButton (AppBar action) | re-shows the scanning popup (SCAN-001), then replaces the results list |
| SCAN-011 | Initial loading spinner | CircularProgressIndicator (centered) | shown only while the first scan (on screen entry) is in flight, before any results exist |
| SCAN-004 | Found camera list | ListView of glass-style rows | one row per discovered camera: name (`"Camera at <host>"`), LAN IP address (from WS-Discovery), and a status badge ("Configured" / "Unconfigured"); tapping a row starts that camera's setup flow |
| SCAN-005 | Empty state | Text | shown if a completed scan finds zero cameras |
| SCAN-007 | Unconfigured camera choice dialog | Glass-styled dialog | shown when an "Unconfigured" (factory-reset) camera is tapped; two actions: "Connect with default credentials" and "Change credentials" |
| SCAN-010 | Setup form | Glass-styled dialog (GlassCard, rounded fields, gradient "Connect" button) | Unified form for all three entry paths: **Configured** camera → username/password start empty (user must know the camera's existing credentials); **default credentials** path → username/password pre-filled `admin`/`password`; **change credentials** path → username pre-filled `admin`, "New password" + "Confirm password" fields, validated to match. Room dropdown only lists rooms on the currently selected home. "Connect" simulates success, adds the camera to the home, and returns to the Dashboard. |

## Notes

- Reached only from the Dashboard's "Add camera" AppBar button (`DASH-019`): tap → SCAN-001 popup → (on completion) push to `/dashboard/scan`.
- Discovery: `WsDiscoveryClient.scanMulticast()` runs first; if it finds nothing, `scanUnicast()` (subnet sweep) runs as a fallback — matching the client's own documented tiering. Runs once on screen entry (behind SCAN-011) and again on every SCAN-006 rescan (behind the SCAN-001 popup).
- **Every discovered camera currently shows as "Unconfigured"** — WS-Discovery only yields a device's network address (host/port), not its identity or whether it's already set up. Real detection needs `OnvifDeviceClient`/`CapabilitiesClient`, wired in a follow-up integration pass.
- The setup form's "Connect" (SCAN-010) still simulates success client-side — it doesn't verify the entered credentials against the camera. It does now persist the entered host/username/password onto the new `Camera` (see `Camera.connection`), which is what [camera_info_screen.md](../camera_settings/camera_info_screen.md)'s "Sync from camera" button uses to make its first real LAN calls.
- Default stub credentials: username `admin`, password `password`.
- Styling: SCAN-007 and SCAN-010 use the app's glass/gradient visual language (`GlassCard`, rounded input fields, gradient-filled primary button) rather than default `AlertDialog` styling, matching Login/Signup.
- Superseded the earlier modal-bottom-sheet version of this flow.
