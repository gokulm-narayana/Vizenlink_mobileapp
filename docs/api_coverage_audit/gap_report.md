# UI ↔ Client/API Wiring Gap Report

Cross-references every screen in `lib/screens/**/*.dart` against real client/API code — `packages/camera_api` (LAN/ONVIF/NuraEye/WAN clients), `packages/auth_api` (AWS Cognito), and anything else documented in `docs/client_code/*.md` — to find UI that *looks* finished but is still running on hardcoded/mock/placeholder data. Complements `scenario-gap-audit` (spec vs. built UI). Read-only analysis; no screens or client code were modified while producing this report.

## Summary

Full fresh re-run — every screen re-read against current source, not diffed against the prior (now very stale) report. A large amount of real WAN wiring landed since the last audit: LAN-then-WAN fallback across Night Mode, Video Mode, Video Encoder, Privacy Mode, On-Screen Display, Imaging, and Camera Live's quick-toggle shortcuts; real LAN+WAN live streaming, two-way Talk, snapshot/recording; a new WAN preview-snapshot key-management feature; real camera WiFi signal strength + measured stream bitrate.

- **Screens checked:** 34
- **Elements checked:** ~450 (interactive elements + notable data-bearing rows/badges)
- ✅ **Wired** (real `camera_api`/`auth_api` call, real documented client code, or legitimate local-only-by-design plumbing): ~290
- ⚠️ **Client code exists, not wired:** ~45
- ❌ **No client code available / static-navigation-only:** ~115

**What changed since the last audit** (that report predates all of this):
1. **Live streaming is now real, both transports.** `camera_live_screen.dart`'s Live tab (video surface, snapshot, recording, two-way Talk) runs on real LAN WebRTC (`WebRtcUriClient`/`RTCPeerConnection`) with automatic WAN fallback (`AwsWanLiveViewClient`/`KvsPlaybackClient`, full transport-selection + health-monitoring + producer-restart recovery). This was the single largest ❌ in the prior report ("entire video surface... none of these WAN/LAN clients are imported or called") — now closed. The Playback tab remains entirely mock (unchanged, no recordings-history client exists anywhere in `camera_api`).
2. **WAN fallback landed across 6 settings screens + Camera Live's shortcuts**, closing what was the prior report's single largest Quick Win: Night Mode, Video Mode, Video Encoder, Privacy Mode, On-Screen Display, **Imaging** (closed this session — Mirror/Flip, Brightness/Contrast/Saturation/Sharpness, WDR, White Balance/Exposure all now retry over `WanImageQualityClient`/`WanImagingClient`/`WanMirrorFlipClient` on LAN failure), and Camera Live's LIVE-041/042 Privacy/Video-Mode quick-toggle tiles. Audio already had it before.
3. **A new WAN preview-snapshot feature** (`lib/app_state/preview_key_store.dart` — RSA keypair generation/storage/registration) backs a transient (never-persisted) WAN fallback on "Refresh preview" for Night Mode, Video Mode, Privacy Mode, On-Screen Display, and Imaging.
4. **Real signal strength + bitrate.** Camera Live's LIVE-030 (signal bars) now polls real `NetworkInfoClient.getWifiSignalStrength()`; the Bitrate badge (LIVE-029, previously a hardcoded `2048.0` stub) now shows a real measured `RTCPeerConnection.getStats()` reading with a real configured-bitrate fallback (`Camera.bitrateKbps`, itself real from Video Encoder settings).
5. **Manual exposure time/gain sliders** (IMG-018/019) added to Imaging — previously no UI existed for `ImagingSettings.exposureTime`/`exposureGain` at all.
6. Dashboard online/offline detection (`pingCameraReachability`, LAN + WAN via `WanDeviceIdentityClient`) now runs every 15s — not itself a screen element, but backs the offline badges' accuracy across the app.

**Unchanged from before** (re-verified this pass, not just carried forward): Playback tab (mock), AI Mode (canned stub replies), Alerts/Events backends (100% hardcoded seed data, zero `camera_api`/`alerts_api` imports), Motion/Person/Vehicle detection (no client exists at all), Recording mode/schedule (no client exists), Storage enable/retention/format (`RestStorageClient` documented but still unwired), Danger Zone soft/hard reset (simulated only), Camera Info password change (no credential-change client), account-management screens beyond core sign-in (Google sign-in, phone auth, email/phone change, 2FA, active sessions, member/invite management — all still fully fake stubs), `docs/client_code/` still only has `auth_api.md` and `camera_api.md` (no `alerts_api.md` — everything in `packages/alerts_api` remains technically "no known client code" per this skill's own definition even though the package exists).

**One doc-vs-code drift found:** `docs/client_code/camera_api.md`'s own "Integration status" note says the scan setup form's "Connect" step "still simulates success rather than verifying credentials" — this is stale. Current `scanned_devices_screen.dart` does real `OnvifDeviceClient` credential verification and surfaces real ONVIF failures.

---

## Quick Wins — client code exists, just needs wiring

Sorted smallest-gap-first.

| Screen (file) | Client code covering it | What's missing | Est. effort |
|---|---|---|---|
| `intrusion_detection_screen.dart` | `MaskClient`/`WanMaskClient` (same rectangle-zone client `privacy_mode_screen.dart` already uses) | Enable toggle, sensitivity, zone add/delete/clear/draw, Save all still route through local state + `simulateCameraSave()` — the exact same client is already wired one screen over (Privacy Mode) | M |
| `line_crossing_screen.dart` | `rest_deterrence_alarms_client`/`rest_alerts_client` (per camera_api.md's own screen mapping) | Enable toggle, sensitivity, direction, line position, Save — all local-only | M |
| `storage_screen.dart` | `RestStorageClient` (`lan/nuraeye/rest_storage_client.dart`, generated + documented, camera_api.md explicitly flags this screen as needing it) | Enable-SD toggle, retention-days, Format SD Card, and the capacity/used/free/health labels all read/write local `Camera` fields only; deletion-history rows are hardcoded literal strings | M |
| `alerts_screen.dart`/`alert_detail_screen.dart` | `rest_alerts_client`/`rest_deterrence_alarms_client` (alert-*rule* config only) | `AlertsController` is 100% hardcoded seed data — no client anywhere fetches an alert-event history/feed at all (that part is genuinely ❌, not just unwired); the rule-configuration half is ⚠️ | L |
| `danger_zone_screen.dart` | `OnvifDeviceClient` (has `reboot`/`factoryReset`; `WanDeviceIdentityClient` mirrors both over WAN) | Soft Reset / Hard Reset both call `simulateCameraSave()` only — the actual reboot/factory-reset client methods already exist and are used elsewhere (Camera Info doesn't currently call them either, but they're real and documented) | S |
| `camera_settings_screen.dart` | `CapabilitiesClient`/`Media2CapabilitiesClient` (per camera_api.md, meant to gate which sub-screen tiles show/hide per camera hardware) | Only `camera.isOnline` gates tile visibility today — no per-capability show/hide anywhere in the 12 camera-settings screens | M |
| `camera_info_screen.dart` | — (field exists on `Camera` model, just never populated) | `networkSpeedKbps` (CAMINFO-030) is displayed but `syncCameraFromDevice` never actually sets it from `NetworkInfoInfo` | S |

---

## Blocked — no client code available yet

Grouped by feature area.

**AI-style detection analytics** — `motion_detection_screen.dart`, `person_detection_screen.dart`, `vehicle_detection_screen.dart`: enable/sensitivity/confidence/zones have no matching client anywhere in `camera_api` (confirmed against `API_REFERENCE.md`/`SETTINGS_API_GUIDE.md` again this pass). Only "Refresh preview" is real (`SnapshotClient`/WAN preview fallback where wired).

**Recording mode/schedule** — `recording_screen.dart`: no recording-mode or schedule client exists at all; footage-estimate label reads local `Camera` fields only, not a live capacity read.

**Playback / recordings history** — `camera_live_screen.dart`'s entire Playback tab (timeline, day picker, prev/next event, clip handles, Snapshot/Download — the latter two are literal `onPressed: () {}` no-ops) and the Alerts/Events feed data itself: no recordings-history or events-feed client exists anywhere in `camera_api`. `_mockRecordedRanges`/`_mockDayEvents()` are explicit mock markers.

**Alerts/Events backend** — `AlertsController`/`EventsController` (`lib/app_state/`) remain 100% hardcoded seed data, zero `camera_api` imports, not even a fake-async delay. `packages/alerts_api` exists as raw shared code but still has no `docs/client_code/alerts_api.md` — undocumented, so nothing in it counts as "known" client code yet per this skill's own definition.

**AI Mode** — `ai_mode_screen.dart`: object-detection gesture, "Ask" (canned reply after a 900ms delay), and voice input are all explicit stubs (own doc comment: "no real AI backend... asking always returns a canned stub reply"). Retake (real frame capture) and navigation entry are real.

**Camera credential change** — `camera_info_screen.dart`'s "Modify Password" dialog: no ONVIF/NuraEye credential-change client exists in `camera_api` at all; explicitly documented as fake in the screen's own comment.

**Account/member management (everything except core sign-in and change-password)** — `login_screen.dart`/`signup_screen.dart`'s "Continue with Google" (explicit `google_sign_in` stub) and phone-auth tab; `account_settings_screen.dart`'s email/phone change and 2FA enrollment (fully fake — any syntactically-valid 6-digit code is accepted, no server verification call at all); `active_sessions_screen.dart` (hardcoded session list, no listing/revocation API); `create_user_screen.dart`/`invite_user_screen.dart`/`users_invites_screen.dart` (no member-creation/invite-sending/member-management API — results only feed each other's local mock lists); `notification_preferences_screen.dart` (entire screen local widget state, no notification backend); `account_screen.dart`'s Subscription/Plan and About tiles, `help_support_screen.dart`'s Contact Support/Report a Bug/User Guide (all `_showComingSoon` stubs); `camera_access_screen.dart`/per-member camera-access checklists (real `HomesController` data, but no sharing/permissions backend to persist the result to). `change_password_screen.dart` is the one genuinely-wired exception in this whole area (`AuthController.instance.changePassword`).

**Spotlight** — `camera_live_screen.dart`'s LIVE-018 tile: purely local `setState` toggle, no spotlight/floodlight client documented anywhere.

---

## Full detail by screen group

One row per design ID (or per element where a screen has no stable ID for it yet — pure-nav tiles and app-bar chrome mostly).

### `camera_live_screen.dart` + `live_view_controller.dart`

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| LIVE-003 | Video surface | ✅ | `LiveViewController` — `WebRtcUriClient` (LAN) + `AwsWanLiveViewClient`/`KvsPlaybackClient` (WAN) | Full transport selection, ICE handling, auto-retry, WAN health monitoring, RouteAware pause when covered by a pushed route |
| LIVE-004 | Live/Needs-Attention/Offline badge | ✅ | `Camera.liveStatus` (derived from real `isOnline`) | |
| LIVE-007/008 | Mute / Fullscreen corner buttons | ✅ | `LiveViewController.setAudioEnabled` | Local playback controls over the real track |
| LIVE-009 | Snapshot | ✅ | `LiveViewController.captureSnapshot()` | Native `MediaStreamTrack.captureFrame()`; falls back to `RenderRepaintBoundary` only with no live connection |
| LIVE-010 | Record | ✅ | `LiveViewController.startRecording`/`stopRecording` | Native `MediaRecorder`; falls back to trimming the dummy asset when there's no live connection |
| LIVE-011 | Talk | ✅ | `LiveViewController.startTalk`/`endTalk` | WebRTC renegotiation over the existing connection, per `TWO_WAY_TALK_GUIDE.md`; LAN only, no WAN talk exists (documented limitation) |
| LIVE-018 | Spotlight | ❌ | — | Local `setState` toggle only, no spotlight/floodlight client exists anywhere |
| LIVE-029 | Bitrate badge | ✅ | Real `RTCPeerConnection.getStats()` + `Camera.bitrateKbps` fallback | Fixed this session — was a hardcoded `2048.0` stub |
| LIVE-030 | Signal strength badge | ✅ | `NetworkInfoClient.getWifiSignalStrength()`, polled 20s | Fixed this session — was always static 0 |
| LIVE-037 | Audio-recording indicator | ✅ | `Camera.audioRecordingEnabled` (real, from Audio settings) | |
| LIVE-038 | Connection-type indicator | ✅ | `connectivity_plus` + `LiveViewController.measuredBitrateKbps` | Real measured throughput appended when available (LAN only) |
| LIVE-039/040 | Cellular-data confirm dialog / reminder | ✅ (local, by design) | `connectivity_plus` | Phone-network signal, not a camera API concern |
| LIVE-041 | Privacy shortcut tile | ✅ | `PrivacyModeClient` + `WanPrivacyModeClient` fallback | |
| LIVE-042 | Video Mode shortcut tile | ✅ | `OnvifImagingClient` + `WanImagingClient` fallback | |
| LIVE-043 | AI Mode entry tile | ✅ (nav) | Real frame capture via `LiveViewController.captureSnapshot` | See `ai_mode_screen.dart` below for what happens once inside |
| LIVE-005 | Live/Playback tab switcher | ✅ (local) | — | Tab state only |
| LIVE-012 | Playback timeline | ❌ | — | `_mockRecordedRanges` — explicit mock marker, no recordings backend exists |
| LIVE-019 | Playback day picker | ❌ | — | Same mock data source |
| LIVE-013/020 | Playback prev/next event | ❌ | — | `_mockDayEvents()` |
| LIVE-023/024 | Playback clip trim handles | ❌ | — | Operate on the same mock ranges |
| LIVE-015 | Playback Snapshot | ❌ | — | Literal `onPressed: () {}` no-op |
| LIVE-016 | Playback Download clip | ❌ | — | Literal `onPressed: () {}` no-op |

### `ai_mode_screen.dart`

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| AIMODE-004/018 | Circle-to-select gesture / "Detecting object…" | ❌ | — | Local geometry only, no object-detection client exists anywhere |
| AIMODE-006 | Retake | ✅ | `LiveViewController.captureSnapshot` (threaded via `captureFrame`) | |
| AIMODE-009 | Send / ask | ❌ | — | 900ms `Future.delayed` then a hardcoded canned reply string |
| AIMODE-016 | Mic / voice input | ❌ | — | 2s `Timer` → "Voice input isn't available yet" snackbar |
| AIMODE-019/020 | Image crop math | ✅ (local, by design) | — | Real pixel math, no client needed |

### Dashboard, Scan, Shell, Homes

| Screen / element | Status | Client code | Notes |
|---|---|---|---|
| `dashboard_screen.dart` thumbnail auto-refresh | ✅ | `refreshCameraSnapshot` → `SnapshotClient` | 5-min timer |
| `dashboard_screen.dart` online/offline polling | ✅ | `pingCameraReachability` → `WebRtcUriClient.checkReachable` + `WanDeviceIdentityClient` fallback | 15s timer |
| DASH-019 Add camera | ✅ (nav) | Real scan flow | |
| Manage Homes / tile actions | ✅ (local, by design) | `HomesController` | |
| SCAN-006 Rescan | ✅ | `WsDiscoveryClient.scanForCameras` | |
| SCAN-004 Found-camera list | ✅ | `WsDiscoveryClient` + `NuraeyeClient.areYouNuraeyeDevice` + `OnvifDeviceClient` probing | |
| SCAN-010 Setup-form Connect | ✅ | `OnvifDeviceClient.getDeviceInformation`/`getSerialNumber`/`getNetworkInterfaceInfo`/`getDeviceIdentity` | Real credential verification — `camera_api.md`'s "still simulates success" note is stale |
| Post-add enrichment | ✅ | `syncCameraFromDevice` (`OnvifDeviceClient`, `CapabilitiesClient`, `SnapshotClient`) | |
| `main_shell.dart` bottom nav + unread badge | ✅ (local, by design) | `AlertsController` (local controller) | |
| `manage_homes_screen.dart` add/rename/delete | ✅ (local, by design) | `HomesController` | No backend expected |

### Auth (`login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart`, `confirm_signup_screen.dart`, `splash_screen.dart`)

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| LOGIN-006 | Log in | ✅ | `AuthController.instance.signIn` | |
| LOGIN-011/FORGOT-003/008 | Forgot password flow | ✅ | `AuthController.forgotPassword`/`confirmForgotPassword` | |
| LOGIN-008/SIGNUP-010 | "Continue with Google" | ❌ | — | Explicit stub — `// Stubbed: no google_sign_in package wired up yet.` |
| LOGIN-004/SIGNUP-005 | Phone tab | ❌ | — | "Phone sign-in/up is not available yet — use email." |
| SIGNUP-008 | Sign up | ✅ | `AuthController.instance.signUp` | |
| CONFIRM-005 | Confirm code | ✅ | `AuthController.confirmSignUp` then `signIn` | |
| CONFIRM-006 | Resend code | ✅ | `AuthController.resendConfirmationCode` | |
| SPLASH | Routing decision | ✅ | `AuthController.status`/`restore()` | |

### Alerts (`alerts_screen.dart`, `alert_detail_screen.dart`)

| Element | Status | Client code | Notes |
|---|---|---|---|
| Alert list / camera+type filters | ❌ | No client fetches an alert-event feed anywhere in `camera_api` | `AlertsController` is 100% hardcoded seed data (`_seedAlerts()`), not even a fake-async delay |
| Snooze-camera toggle | ⚠️ | `RestAlertsClient`/`RestDeterrenceAlarmsClient` (rule-config only, documented, unused) | |
| Mark read/unread | ❌ | — | Local list mutation only |
| Delete/restore alert | ❌ | — | Local list mutation only |
| Alert detail video playback | ❌ | — | Bundled dummy asset, not a real clip |
| Download/share | ✅ (local, by design) | `gal`/`share_plus` | Device I/O, not a camera_api concern |

### Events (`events_screen.dart`, `event_detail_screen.dart`, `events_summary_screen.dart`)

| Element | Status | Client code | Notes |
|---|---|---|---|
| Event list / camera+type+day filters | ❌ | — | `EventsController` 100% hardcoded seed data (`_seedEvents()`), no events-history client exists anywhere |
| Recording-coverage timeline band | ❌ | — | Explicit mock marker: `_mockRecordedRanges` |
| Event detail video playback | ❌ | — | Same bundled dummy asset pattern as alerts |
| Delete event | ❌ | — | Local list mutation only |
| `events_summary_screen.dart` | ✅ (local, by design) | — | Pure presentational aggregation over whatever list it's given |

### `audio_screen.dart`

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| AUD-012 | Record Audio toggle | ✅ | `AudioVolumeClient` + `WanAudioVolumeClient` fallback | |
| AUD-006 | Speaker volume | ✅ | `SpeakerVolumeClient` + `WanSpeakerVolumeClient` fallback | |
| AUD-007 | Microphone gain | ✅ | `AudioVolumeClient` + `WanAudioVolumeClient` fallback | |
| AUD-008 | Test Sound | ✅ | `AudioVolumeClient.playTestSound` + `WanAudioVolumeClient` fallback | |
| — | Hardware gate (mic/speaker visibility) | ✅ | `AudioCapabilityClient.getAudioCapability` | LAN-only, no WAN capability query exists (documented) |

### `imaging_screen.dart` — closed this session

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| IMG-004 | Mirror/Flip | ✅ | `MirrorFlipClient` + `WanMirrorFlipClient` fallback | WAN fallback added this session |
| IMG-005–008 | Brightness/Contrast/Saturation/Sharpness | ✅ | `OnvifImagingClient` + `WanImageQualityClient` fallback | WAN fallback added this session |
| IMG-009/010 | White balance / Exposure mode | ✅ | `OnvifImagingClient` + `WanImageQualityClient` fallback | |
| IMG-011 | Reset to Default | ✅ | `NuraeyeClient.call('GetImageDefaults')` + `WanImageQualityClient.getImageDefaults` fallback | |
| IMG-012/013 | WDR toggle/level | ✅ | `OnvifImagingClient` + `WanImagingClient.setWdr` fallback | |
| IMG-014 | Refresh preview | ✅ | `refreshCameraSnapshot` + `fetchWanPreviewSnapshot` transient WAN fallback | Added this session |
| IMG-018/019 | Exposure time / gain sliders | ✅ | `OnvifImagingClient` (`ImagingSettings.exposureTime`/`exposureGain`) | **New this session** — only shown in Manual mode; LAN-only, no WAN client documents these two fields specifically |

### `night_mode_screen.dart`, `video_mode_screen.dart`, `video_encoder_screen.dart`, `on_screen_display_screen.dart`, `privacy_mode_screen.dart`

| Screen | Status | Client code | Notes |
|---|---|---|---|
| NIGHT-006 mode tiles | ✅ | `NightVisionClient` + `WanNightVisionClient` fallback | |
| NIGHT-007 Refresh preview | ✅ | `refreshCameraSnapshot` + WAN transient fallback | |
| VIDMODE-004 Day/Auto/Night tiles | ✅ | `OnvifImagingClient` + `WanImagingClient.setDayNightMode` fallback | |
| VIDMODE-007 Refresh preview | ✅ | `refreshCameraSnapshot` + WAN transient fallback | |
| ENC-003/007–013 resolution/encoder/profile/rate/GOV/quality/bitrate | ✅ | `OnvifVideoEncoderClient` + `WanVideoEncoderClient` fallback | |
| ENC-014 Reset to Default | ✅ (local, by design) | — | No camera-reported defaults endpoint exists for encoder settings |
| OSD-006/016/017/012/013 Time slot | ✅ | `OsdClient` + `WanOsdClient` fallback | |
| OSD-007/008/014/015 Custom text slot | ✅ | `OsdClient` + `WanOsdClient` fallback | |
| OSD-018 Refresh preview | ✅ | `refreshCameraSnapshot` + WAN transient fallback | |
| PRIV-002 Off/Full/Zone mode | ✅ | `PrivacyModeClient` + `WanPrivacyModeClient` fallback | |
| PRIV-005–009/014 zone add/draw/delete/clear | ✅ | `MaskClient` + `WanMaskClient` fallback (per-op diff) | |
| PRIV-005(button) Refresh preview | ✅ | `refreshCameraSnapshot` + WAN transient fallback | |

### `video_display_screen.dart`, `tags_screen.dart`

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| VIDDISP-* | Menu tiles | ✅ (nav) | — | Pure navigation |
| TAG-004/006 | Bitrate toggle/position | ❌ (by design) | — | App-composited overlay badge, no client-code concept exists on the camera side |
| TAG-005 | Live tag toggle | ❌ (by design) | — | Same reasoning |
| TAG-007/008 | Signal strength toggle/position | ❌ (by design) | — | Same reasoning |
| TAG-012 | Refresh preview | ✅ | `refreshCameraSnapshot` | LAN-only — this screen doesn't have the WAN transient fallback the 5 screens above do |

### `detections_screen.dart`, `intrusion_detection_screen.dart`, `line_crossing_screen.dart`, `motion_detection_screen.dart`, `person_detection_screen.dart`, `vehicle_detection_screen.dart`

| Screen | Status | Client code | Notes |
|---|---|---|---|
| DETECT-* menu tiles | ✅ (nav) | — | Pure menu |
| INTRUDE-005/006 enable/sensitivity | ⚠️ | `MaskClient`/`WanMaskClient` (documented, unused here) | |
| INTRUDE-007/009/010/014 zone add/delete/clear/draw | ⚠️ | Same | Same client Privacy Mode already uses |
| INTRUDE-002 Save | ⚠️ | — | `simulateCameraSave()` |
| INTRUDE-004 Refresh preview | ✅ | `refreshCameraSnapshot` | |
| LINE-005/006/007 enable/sensitivity/direction | ⚠️ | `rest_deterrence_alarms_client` (documented, unused) | |
| LINE-008 line position/reset | ⚠️ | Same | |
| LINE-004 Refresh preview | ✅ | `refreshCameraSnapshot` | |
| MOTION-003/004 enable/sensitivity | ❌ | — | No client exists at all |
| MOTION-007 Refresh preview | ✅ | `refreshCameraSnapshot` | |
| PERSON-003/004 enable/confidence | ❌ | — | No client exists |
| PERSON-008/009/011/012 zone add/finish/delete/clear | ❌ | — | No client exists |
| PERSON-007 Refresh preview | ✅ | `refreshCameraSnapshot` | |
| Vehicle detection enable/confidence | ❌ | — | No client exists |
| Vehicle detection Refresh preview | ✅ | `refreshCameraSnapshot` | |

### `recording_screen.dart`, `storage_screen.dart`

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| REC-003 | Mode radio group | ❌ | — | No recording-mode client documented anywhere |
| REC-005–008 | Schedule window add/edit/delete | ❌ | — | Same |
| REC-004 | Footage estimate label | ❌ | — | Reads local `Camera` fields only, not a live capacity read |
| REC-002 | Save | ❌ | — | `simulateCameraSave()` |
| REC-010 | "Set up detection" | ✅ (nav) | — | |
| STOR-003 | Enable SD Storage | ⚠️ | `RestStorageClient` (documented, unused) | camera_api.md explicitly flags this screen as needing it |
| STOR-009 | Retention-days | ⚠️ | Same | |
| STOR-004–007 | Capacity/used/free/health labels | ⚠️ | Same | Local `Camera` fields only, not a live read |
| STOR-011 | Format SD Card | ⚠️ | Same | `simulateCameraSave()` then locally zeroes usage |
| STOR-014 | Deletion-history rows | ❌ | — | Hardcoded literal strings, no backing call at all |

### `wifi_config_screen.dart`, `camera_info_screen.dart`, `camera_settings_screen.dart`, `danger_zone_screen.dart`

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| WIFI-010/011 | Current network display | ✅ | `OnvifDeviceClient.getNetworkInterfaceInfo` + `NetworkInfoClient.getWifiSsid`/`getWifiSignalStrength` | |
| WIFI-007–009 | New SSID/password/Connect | ✅ | `NetworkInfoClient.setupWifi` | Falls back to `simulateCameraSave` only with no saved connection (documented/intentional) |
| WIFI-012/013/015 | Nearby-network scan | ✅ (local, by design) | Phone's own `wifi_scan` radio | `NetworkInfoClient` has no scan capability — correctly out of `camera_api`'s scope |
| CAMINFO-003 | Name field + Save | ✅ | `OnvifDeviceClient.setDeviceName` | |
| CAMINFO-032 | "Sync from camera" | ✅ | `syncCameraFromDevice` | |
| CAMINFO-006 | Timezone dropdown | ✅ | `NetworkInfoClient.getSupportedTimezones` + `OnvifDeviceClient.setTimeZone` | |
| CAMINFO-011/033/013/014/012 | Manufacturer/model/serial/hardware/firmware | ✅ | Populated via `syncCameraFromDevice` | |
| CAMINFO-008/009/028 | WiFi network/signal/MAC/IP | ✅ | Populated via `syncCameraFromDevice` | |
| CAMINFO-030 | Network speed | ⚠️ | — | Field displayed but `syncCameraFromDevice` never actually sets it (Quick Win) |
| CAMINFO-015 | "Modify Password" | ❌ | — | No credential-change client exists anywhere in `camera_api`; explicitly documented as fake |
| CAMINFO-004/005 | Home/Room dropdowns | ✅ (local, by design) | `HomesController` | App-side organization, not a camera setting |
| CAMSET-003–009 | Settings menu tiles | ✅ (nav) | — | Only `camera.isOnline` gates today |
| — | Per-capability show/hide gating | ⚠️ | `CapabilitiesClient`/`Media2CapabilitiesClient` (documented, unused for this purpose) | Quick Win |
| DANGER-004 | Soft Reset | ⚠️ | `OnvifDeviceClient.reboot` (+ `WanDeviceIdentityClient` mirror), documented, unused | Simulated only |
| DANGER-005 | Hard Reset | ⚠️ | `OnvifDeviceClient.factoryReset` (+ WAN mirror), documented, unused | Simulated only |
| DANGER-006 | Delete Camera | ✅ (local, by design) | `HomesController.deleteCamera` | Correctly local — no camera round trip needed |

### Account & Member Management

| Design ID | Element | Status | Client code | Notes |
|---|---|---|---|---|
| ACCT-013 | Log out | ✅ | `AuthController.instance.signOut()` | |
| ACCT-007 | Edit avatar | ⚠️ | `ProfileController.updateAvatarImage` (local) | No upload/persist call |
| ACCT-011 | About/app version | ❌ | — | Hardcoded `_mockAppVersion = 'v1.0.0'` |
| ACCT-014 | Subscription/Plan | ❌ | — | `_showComingSoon` stub |
| ACSET-002/009 | Display name + Save | ⚠️ | `ProfileController.updateDisplayName` (local) | |
| ACSET-003/010/011 | Email change | ❌ | — | No email-change client; OTP dialog accepts any 6-digit code, no verify call |
| ACSET-004/010/011 | Phone change | ❌ | — | Same fake OTP flow |
| ACSET-005 | Change password nav | ✅ (nav) | `ChangePasswordScreen` (genuinely wired, see below) | |
| ACSET-006/019–023 | Two-factor authentication | ❌ | — | QR/secret hardcoded literal; confirmation is the same fake any-6-digit-code dialog |
| ACSET-007 | Active sessions nav | ✅ (nav) | `ActiveSessionsScreen` (itself unwired, see below) | |
| ACSET-008 | Delete account | ❌ | — | `_showComingSoon` stub |
| SESS-002 | Session list | ❌ | — | Hardcoded `_sessions` literal, no session-listing API exists |
| SESS-008/009 | Per-session / sign-out-all | ❌ | — | Local list mutation only |
| CAMACC-002–006 | All-cameras switch, checklist, Save | ⚠️ | `HomesController` (local) | Real home/camera data, no permissions backend to persist to |
| CRUSR-002–005 | Name/Email/Password/Confirm | ❌ | — | No admin user-creation API |
| CRUSR-006/007 | Role/expiry | ⚠️ | — | Local state only |
| CRUSR-011–015 | Camera access checklist | ⚠️ | `HomesController` (local) | |
| CRUSR-009 | Create button | ❌ | — | Result only feeds `UsersInvitesScreen`'s local mock list |
| INVUSR-002 | Contact field | ❌ | — | No invite-send API |
| INVUSR-003/004 | Role/expiry | ⚠️ | — | Local state only |
| INVUSR-008–012 | Camera access checklist | ⚠️ | `HomesController` (local) | |
| INVUSR-006 | Send invite | ❌ | — | No invite-sending client anywhere |
| NOTIF-002–012 | All toggles + quiet-hours pickers | ❌ | — | Entire screen local widget state, no notification backend at all |
| HELP-002/003 | FAQ search/list | ✅ (local, by design) | — | Legitimately local content filtering |
| HELP-004/005/006 | Contact Support/Report Bug/User Guide | ❌ | — | `_showComingSoon` stubs |
| HELP-007 | App version footer | ❌ | — | Hardcoded literal |
| USRINV-003/004/005 | Member list/role change/remove | ❌ | — | Hardcoded seed list, local mutation only |
| USRINV-023 | Per-member camera access | ⚠️ | `HomesController` (local) | |
| USRINV-007/008 | Pending invite / cancel | ❌ | — | Hardcoded seed list, local mutation only |
| CHPW-002–004 | Password fields | ✅ | — | Local validation feeding a real call |
| CHPW-006 | Update button | ✅ | `AuthController.instance.changePassword` | Real `CognitoAuthException` handling with friendly-message mapping |
