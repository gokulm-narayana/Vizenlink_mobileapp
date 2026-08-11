# CameraInfoScreen

- **Dart file:** `lib/screens/camera_settings/camera_info_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/info`
- **Purpose:** Reached from the "Camera Info" row on [camera_settings_screen.md](camera_settings_screen.md). Lets the user rename the camera, move it to a different home/room, and change its timezone — all staged as local draft state and only written through `HomesController` (same shared state the Dashboard reads) after confirming in the CAMINFO-022 "Save changes?" dialog. Also shows read-only device-info fields sourced from the `Camera` model, and offers a password-change dialog. The Device Identity (manufacturer/model, serial number, hardware ID, firmware version) and Network & Connectivity (Wi-Fi network, signal strength, MAC address, IP address) fields display whatever is currently cached on the `Camera` model — real values once CAMINFO-032 "Sync from camera" has run at least once for this camera, otherwise the original stub/placeholder seed values. Network speed and recording status remain pure stub data (no real client wired up yet). Leaving the screen (back gesture or bottom-nav tap, via the shared `LeaveGuard` widget, `lib/widgets/navigation_leave_guard.dart`) with unsaved edits triggers the CAMINFO-025 "Unsaved changes" prompt instead of silently discarding them.

Fields are grouped under section headers (`_SectionHeader`, purely a visual/layout grouping — no new design IDs), each with its own `GlassCard`(s): **Health** (open health conditions, shown only when there are any — see below), **Device Identity** (name, manufacturer/model, serial number, hardware ID, firmware version), **Network & Connectivity** (Wi-Fi network, signal strength, MAC address), **Location** (home, room, timezone), **Recording** (recording status), **Security** (Modify Password).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CAMINFO-031 | Health condition row | Read-only info row, one per open condition | Health section — the whole section is omitted entirely when `camera.healthConditionMessages` is empty (a healthy camera shows no Health section at all). Each row shows one plain-language message from `Camera.healthConditionMessages` (currently: a storage-failure condition and/or "SD card wearing out", see [storage_screen.md](recording_and_storage/storage_screen.md)); this is also what drives the Dashboard's DASH-021 icon and the amber "Needs Attention" state on `Camera.liveStatus` |
| CAMINFO-001 | Screen title (AppBar) | Text | "Camera Info" |
| CAMINFO-002 | Save button (AppBar action) | TextButton | disabled until a field changes; opens the CAMINFO-022 "Save changes?" confirmation dialog before committing |
| CAMINFO-003 | Camera name field | TextField (editable) | Device Identity section; staged locally; marks the screen dirty (enables CAMINFO-002) on any keystroke |
| CAMINFO-032 | Sync from camera button | OutlinedButton.icon | Below the name field, above the Device Identity card; calls `camera_api`'s `OnvifDeviceClient.getDeviceInformation()`/`getNetworkInterfaceInfo()` and `CapabilitiesClient.getCapabilities()` over LAN using `Camera.connection` (built from host/username/password captured at scan setup); shows a spinner + "Syncing…" while in flight. Persists whatever succeeds (manufacturer, model, firmware version, serial number, hardware ID, MAC address, IP address, WAN live-view capability, and `thingName` mirrored from the serial number — see `OnvifDeviceClient.getSerialNumber`'s doc) via `HomesController.updateCamera`, then shows a snackbar summarizing success or which fields failed. If the camera has no saved connection yet (added before credential capture was wired up), shows a snackbar saying so instead of attempting a call. LAN only — WAN fallback (`WanDeviceIdentityClient`) isn't wired up yet. |
| CAMINFO-011 | Manufacturer & model row | Read-only info row | Device Identity section; from `camera.manufacturer` + `camera.model` |
| CAMINFO-013 | Serial number row | Read-only info row | Device Identity section; from `camera.serialNumber` |
| CAMINFO-014 | Hardware ID row | Read-only info row | Device Identity section; from `camera.hardwareId` |
| CAMINFO-012 | Firmware version row | Read-only info row | Device Identity section; from `camera.firmwareVersion` |
| CAMINFO-008 | Wi-Fi network row | Read-only info row | Network & Connectivity section; from `camera.wifiNetwork` — not synced by CAMINFO-032, still stub |
| CAMINFO-009 | Signal strength row | Read-only info row | Network & Connectivity section; from `camera.signalStrength` (0–4 bars) — not synced by CAMINFO-032, still stub |
| CAMINFO-030 | Network speed row | Read-only info row | Network & Connectivity section; from `camera.networkSpeedKbps`, auto-scaled to KB/s or MB/s via `formatBitrate` (`lib/widgets/live_status_badges.dart`) — not synced by CAMINFO-032, still stub |
| CAMINFO-010 | MAC address row | Read-only info row | Network & Connectivity section; from `camera.macAddress` |
| CAMINFO-028 | IP address row | Read-only info row | Network & Connectivity section; from `camera.ipAddress` |
| CAMINFO-029 | Configure Wi-Fi button | OutlinedButton.icon | Network & Connectivity section; navigates to [wifi_config_screen.md](wifi_config_screen.md) |
| CAMINFO-004 | Home dropdown | DropdownButtonFormField | Location section; lists all homes; staged locally (resets room to Unassigned), committed to `HomesController.moveCameraToHome` on Save |
| CAMINFO-005 | Room dropdown | DropdownButtonFormField | Location section; rooms of the currently selected home, plus "Unassigned"; staged locally, committed on Save |
| CAMINFO-006 | Timezone dropdown | DropdownButtonFormField | Location section; dummy timezone list (`_dummyTimezones` — UTC and 9 common IANA zones) until a real camera can report its own; staged locally, committed via `HomesController.updateCameraTimezone` on Save |
| CAMINFO-007 | Recording status row | Read-only info row | Recording section; from `camera.recordingStatus` (Continuous / Scheduled / Event-triggered / Off) — editable from [recording_screen.md](recording_and_storage/recording_screen.md), reached via the "Recording" row on [camera_settings_screen.md](camera_settings_screen.md), not from this row |
| CAMINFO-015 | Modify Password button | OutlinedButton | Security section; opens the CAMINFO-016 dialog |
| CAMINFO-016 | Modify Password dialog | Dialog (glass-styled, matches the app's Login/Signup dialogs) | contains CAMINFO-017–021 |
| CAMINFO-017 | Current password field | TextField (obscured) | required |
| CAMINFO-018 | New password field | TextField (obscured) | required, minimum 8 characters |
| CAMINFO-019 | Confirm password field | TextField (obscured) | must match CAMINFO-018 |
| CAMINFO-020 | Cancel button | TextButton | closes the dialog, discards changes |
| CAMINFO-021 | Save button | GradientButton | validates fields, closes the dialog, and shows a "Password updated" snackbar — no real camera credential backend yet |
| CAMINFO-022 | Save-changes confirmation dialog | AlertDialog | opened by CAMINFO-002; confirming commits the staged edits via `HomesController.renameCamera` / `moveCameraToHome` / `updateCameraTimezone` and shows a "Changes saved" snackbar |
| CAMINFO-023 | Cancel button (in CAMINFO-022) | TextButton | closes the dialog without saving |
| CAMINFO-024 | Save button (in CAMINFO-022) | FilledButton | commits the staged edits |
| CAMINFO-025 | Unsaved-changes dialog | AlertDialog | shown when leaving the screen (back gesture or bottom-nav tap) while `_isDirty`; offers Discard or Save |
| CAMINFO-026 | Discard button (in CAMINFO-025) | TextButton | leaves the screen without saving, edits are lost |
| CAMINFO-027 | Save button (in CAMINFO-025) | FilledButton | commits the staged edits, then leaves the screen |
