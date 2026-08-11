# WifiConfigScreen

- **Dart file:** `lib/screens/camera_settings/wifi_config_screen.dart`
- **Route:** `/dashboard/live/:cameraId/settings/info/wifi-config`
- **Purpose:** Reached from the "Configure Wi-Fi" button (CAMINFO-029) on [camera_info_screen.md](camera_info_screen.md). Scans for nearby networks (simulated — no real Wi-Fi scan API is wired up, see CLAUDE.md), lets the user tap one and enter its password, or enter a network manually. On Connect, simulates a round-trip (`simulateCameraSave`, shared with the rest of the app's Save flows), writes the new network name through `HomesController.updateCameraWifi`, shows a "Connected to `<ssid>`" snackbar, and pops back to Camera Info. Scan results are a fixed stub list, not a real scan.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| WIFI-001 | Screen title (AppBar) | Text | "Configure Wi-Fi" |
| WIFI-002 | Scanning indicator | CircularProgressIndicator + "Scanning for networks…" | shown for ~1s on screen load, then replaced by WIFI-003 |
| WIFI-003 | Network list | Column of tappable rows (signal-bars icon, SSID, lock icon if secured) | stub list of 4 networks (`_scannedNetworks`), varying signal strength and secured/open; tapping a row selects it and reveals WIFI-004/005 |
| WIFI-004 | Password field | TextField (obscured) | shown once a network is selected; required only if the selected network is secured |
| WIFI-005 | Connect button | FilledButton | shown alongside WIFI-004; disabled until a password is entered for secured networks (open networks can connect immediately); triggers the `SavingOverlay` "Connecting…" state |
| WIFI-006 | Edit manually button | OutlinedButton.icon | toggles to manual-entry mode (WIFI-007–009), replacing the selected-network panel |
| WIFI-007 | Network name field | TextField | manual-entry mode |
| WIFI-008 | Password field (manual) | TextField (obscured) | manual-entry mode; optional (manual entry doesn't require a password, since the network's security type isn't known) |
| WIFI-009 | Connect button (manual) | FilledButton | manual-entry mode; disabled until a network name is entered |
