# camera_api (`client_code_inbox/camera_api/`)

Pure-Dart, `package:flutter`-free camera network layer (LAN ONVIF + proprietary NuraEye REST, and WAN AWS IoT/KVS). Every network call returns `Future<CameraResult<T>>` (`CameraSuccess` / `CameraFailure` / `CameraTimeout` — never throws).

**Full method-level reference:** see the package's own [`API_REFERENCE.md`](../../client_code_inbox/camera_api/API_REFERENCE.md) — every class, method signature, and the `CameraResult` pattern is documented there in detail. This doc's job is different: it maps each client class to the mobilecctvapp screen(s) it belongs to, so integration knows where each piece goes.

**Location:** relocated from `client_code_inbox/camera_api/` to `packages/camera_api/` (a permanent local path dependency, added to `pubspec.yaml`) — `client_code_inbox/` is staging-only per this project's convention, so the whole package moved out as one unit rather than per-file, since it doesn't decompose into a single copyable file.

**Integration status:**
- Core (`CameraConnection`, `CameraResult`) + `WsDiscoveryClient` wired into `scanned_devices_screen`/`scanning_popup` (real LAN discovery, replacing the old fake stub list). The setup form now also captures and persists `host`/`username`/`password` onto the `Camera` model (see `Camera.connection`), though the "Connect" step itself still simulates success rather than verifying credentials against the camera.
- `OnvifDeviceClient` (`getDeviceInformation`, `getNetworkInterfaceInfo`) + `CapabilitiesClient` wired into `camera_info_screen`'s new "Sync from camera" button (CAMINFO-032) — LAN only. Populates `Camera.manufacturer/model/firmwareVersion/serialNumber/hardwareId/macAddress/ipAddress/wanLiveViewCapable`, and mirrors the serial number into `Camera.thingName` (per `OnvifDeviceClient.getSerialNumber`'s doc: same string, needed for WAN). `WanDeviceIdentityClient` (the WAN counterpart) is not wired up yet — flagged as follow-up.
- `NetworkInfoClient` (`getWifiSsid`, `getWifiSignalStrength`, `setupWifi`) + `OnvifDeviceClient.getNetworkInterfaceInfo` (for the wired/wireless check) wired into `wifi_config_screen` — LAN only, no WAN counterpart exists for this client. Replaced the screen's earlier fake nearby-network-scan UI entirely, since the client has no scan capability — see [wifi_config_screen.md](../screens/camera_settings/wifi_config_screen.md) for the shape that replaced it. `getSupportedTimezones` was already wired into `camera_info_screen`'s timezone picker separately.

The screen mapping below predates most of the integration work above and elsewhere in the app (night mode, imaging, video mode, video encoder, privacy mode, on-screen display, and audio screens are also wired up by now) — treat it as "which screen a class belongs to," not "still unintegrated." `NetworkInfoClient` is marked integrated (✅) as of the bullet above; the rest haven't been re-audited against current code.

## Core (used by everything)

| Class | File | Used for |
|---|---|---|
| `CameraConnection` | `camera_connection.dart` | Identify/authenticate a single camera — the object every other client method takes |
| `CameraResult`/`CameraSuccess`/`CameraFailure`/`CameraTimeout` | `camera_result.dart` | Return type of every network call — screens branch UI state on this |
| `WsDiscoveryClient` | `lan/discovery/ws_discovery_client.dart` | Find cameras on the LAN — `scanned_devices_screen` / `scanning_popup` |

## Screen mapping

| Client class(es) | LAN / WAN pair | Likely screen |
|---|---|---|
| `OnvifDeviceClient` | LAN only | `camera_info_screen` (device identity/info) |
| `WanDeviceIdentityClient` | WAN | `camera_info_screen` / `account/active_sessions_screen` ("Authentication" card per its doc comment) |
| `OnvifImagingClient`, `WanImagingClient`, `WanImageQualityClient` | LAN + WAN | `imaging_screen` (day/night, WDR, brightness/contrast/etc.) |
| `NightVisionClient` (nuraeye), `WanNightVisionClient` | LAN + WAN | `night_mode_screen` |
| `OnvifVideoEncoderClient`, `WanVideoEncoderClient` | LAN + WAN | `video_encoder_screen` |
| `OsdClient`, `WanOsdClient` | LAN + WAN | `on_screen_display_screen` |
| `MaskClient` (onvif), `WanMaskClient` | LAN + WAN | `privacy_mode_screen` (privacy mask regions) — cross-check against `drawable_zone.dart` widget, may also apply to intrusion/line-crossing zone drawing |
| `PrivacyModeClient` (nuraeye), `WanPrivacyModeClient` | LAN + WAN | `privacy_mode_screen` |
| `MirrorFlipClient` (nuraeye), `WanMirrorFlipClient` | LAN + WAN | `video_mode_screen` or `video_display_screen` (orientation) — confirm which with user |
| `AudioCapabilityClient`, `SpeakerVolumeClient` (onvif), `AudioVolumeClient` (nuraeye), `WanAudioVolumeClient`, `WanSpeakerVolumeClient` | LAN + WAN | `audio_screen` |
| `NetworkInfoClient` ✅, `rest_network_connectivity_client` | LAN | `wifi_config_screen` |
| `SnapshotClient`, `WanPreviewSnapshotClient` | LAN + WAN | `camera_live_screen`, `camera_preview_thumbnail.dart` widget |
| `WebRtcUriClient`, `CloudStreamingClient` (nuraeye) | LAN | `camera_live_screen` (live stream URI) |
| `WanLiveViewClient` / `AwsWanLiveViewClient`, `KvsPlaybackClient` | WAN | `camera_live_screen` (WAN playback path) |
| `IotCommandClient`, `WanAuth` | WAN | Core plumbing — command relay + app-supplied auth config, not screen-specific |
| `rest_alerts_client`, `rest_deterrence_alarms_client` | LAN | `alerts_screen`, `intrusion_detection_screen` / `line_crossing_screen` (deterrence) |
| `CapabilitiesClient` (nuraeye), `rest_capabilities_client`, `Media2CapabilitiesClient` (onvif) | LAN | Hardware-gating input for `camera_settings_screen` and its sub-screens (which controls to show/hide) |
| `rest_storage_client` | LAN | No matching screen yet — flag as a gap (see `ui-api-gap-audit` / `scenario-gap-audit`) |

## Notes

- WAN classes consistently mirror a LAN counterpart one-for-one (per their own doc comments) — when integrating a setting, check both clients for that feature and confirm with the user which transport a given screen should call (or both, with fallback).
- `rest_*.dart` files under `lan/nuraeye/` are machine-generated (marked `DO NOT HAND-EDIT` in `camera_api.dart`) — never touch those directly even under the "unavoidable change" exception; flag to the senior instead.
- Several doc comments reference `FR-NE-*`/`FR-MOB-*` IDs — these likely correspond to entries in this workspace's `features/` — worth cross-referencing during `scenario-gap-audit`.

## New in the 2026-09-07 client_code_inbox drop — documented only, not yet integrated

This package is shared with a sibling app (`nuraeye-rt/mobile_app`, referenced elsewhere in this
repo e.g. the Force LAN/WAN test menu) — the drop's own `SETTINGS_API_GUIDE.md`/`API_REFERENCE.md`
describe screens that exist *there* (`EventSettingsScreen`, `recordings_screen.dart`) but not in
*this* app. The mapping below is this app's own candidate screens, not the sibling's. Full
method-level detail for all of these already lives in the package's own updated
`API_REFERENCE.md`/`SETTINGS_API_GUIDE.md` (`packages/camera_api/` once synced from the inbox) —
not duplicated here, same reasoning as this doc's header note about the package "not decomposing
into a single copyable file."

| Client class(es) | LAN / WAN pair | What it does | Candidate screen in *this* app |
|---|---|---|---|
| `RecordingsClient` (`lib/src/lan/nuraeye/recordings_client.dart`) | LAN only, no WAN counterpart yet | `GetRecordings` + a `Range`-capable clip playback/download URI, plain REST (`FR-NE-117`/`FR-NE-118`) — a real recordings list, replacing job-polling ONVIF Search after the sibling app found that a poor fit for a phone client | `camera_live_screen.dart`'s Playback tab — currently plays a single bundled ~1-minute dummy clip on a mocked day-timeline (`_mockRecordedRanges`); this is the real data source that timeline is standing in for |
| `HealthClient` / `WanHealthClient` | LAN + WAN, same `HealthStatus` wire vocabulary | Read-only camera health/vitals (`FR-HLT-009`) — no matching Set | `camera_info_screen.dart`'s Health section (CAMINFO-031) — currently reads `Camera.healthConditionMessages`, mock data with no real API call behind it yet (per [camera_info_screen.md](../screens/camera_settings/camera_info_screen.md)) |
| `LoiteringDurationClient` / `WanLoiteringDurationClient` | LAN + WAN | Dwell-time threshold (seconds) before a `Loitering` event fires, independent of `PersonDetected`'s own enable toggle (`FR-CF-150`/`FR-NE-121`); bounds come from `CapabilitiesClient` (`loiteringDurationMinSeconds`/`MaxSeconds`), not a separate Options command | No matching UI in this app yet — `person_detection_screen.dart` is the natural home (mirrors the sibling's `EventSettingsScreen` "Loitering" card), but that screen doesn't currently expose a duration control; flag as a gap for `scenario-gap-audit`/`ui-api-gap-audit` |
| `BboxOverlayClient` / `WanBboxOverlayClient` | LAN + WAN | Whether the camera burns the AI detection bounding box into the video OSD (`FR-CF-151`/`FR-NE-123`) — purely a display toggle, independent of whether detection/alerts still fire (`bbox` keeps arriving in event payloads regardless); gated on `CameraCapabilities.bboxOverlayCapable` | Same gap as above — `person_detection_screen.dart`, no existing switch for this |
| `onvif_recording_client.dart`, `onvif_replaycontrol_client.dart`, `onvif_search_client.dart` | LAN, ONVIF Recording/ReplayControl/Search services | **Superseded, not for integration** — the drop's own `recordings_client.dart` doc comment says the team moved *away* from this ONVIF Recording/Search-based design to the plain-REST `RecordingsClient` above, after finding ONVIF Search's async job-polling browse model a poor fit for a phone client. Kept here for reference/completeness of the drop, not because they're the intended integration path |

**Other files in this drop with in-place edits** (not new classes — same class, updated
behavior): `capabilities_client.dart`, `network_info_client.dart`, `nuraeye_client.dart`,
`nuraeye_rest_client.dart`, `rest_capabilities_client.dart`, `rest_storage_client.dart`,
`audio_capability_client.dart`, `mask_client.dart`, `onvif_imaging_client.dart`,
`onvif_video_encoder_client.dart`, `osd_client.dart`, `speaker_volume_client.dart`,
`iot_command_client.dart`, `camera_connection.dart`, `camera_api.dart` (exports). Not
individually diffed/documented here — re-check each against its currently-integrated behavior
before/while integrating, since some carry real behavior changes (e.g. `SETTINGS_API_GUIDE.md`'s
diff shows `getImagingOptions()`/`getMaskOptions()` moving from client-internal caching to
required app-layer caching — see `.claude/rules/mobile-app-screen-conventions.md`'s caching
convention, which this app's `MaskClient` usage already follows per that file's own doc, so this
may just be the drop catching up to a convention this app already implemented independently).
