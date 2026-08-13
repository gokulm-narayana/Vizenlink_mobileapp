# UI ↔ client/API coverage gap report

Scope: every screen in `lib/screens/**/*.dart` (44 files), cross-referenced against `docs/client_code/camera_api.md` (the sole client-code doc, mapping `packages/camera_api` classes to screens) and `packages/camera_api/API_REFERENCE.md`/`SETTINGS_API_GUIDE.md` it points to.

Method: for each screen, read the Dart source and classified each interactive element/data source as calling a documented client method (✅), covered by a documented-but-unwired client class per `camera_api.md`'s screen-mapping table (⚠️), or backed by nothing documented at all — hardcoded literals, `_seed*()`/`_mock*` constants, `Future.delayed` fakes, or local `ValueNotifier` state only (❌).

## Summary

- **44 screens** checked; 5 are pure navigation/menu shells with no data elements (`camera_settings_screen.dart`, `detections_screen.dart`, `video_display_screen.dart`, `shell/main_shell.dart`, `splash/splash_screen.dart`) and are excluded from the counts below.
- **39 scored screens**: **9 ✅ Wired**, **4 ⚠️ Client code exists, not wired**, **26 ❌ No client code available**.

## Quick Wins

Screens where client code already exists in `docs/client_code/camera_api.md` but isn't (fully) called yet — closest to done first.

| Screen | Client code covering it | What's missing | Est. effort |
|---|---|---|---|
| `lib/screens/camera_settings/wifi_config_screen.dart` | `docs/client_code/camera_api.md` (`NetworkInfoClient`) | No `package:camera_api` import at all; Save still routes through `simulateCameraSave()` instead of calling `NetworkInfoClient.setupWifi`/`getWifiSsid`/`getWifiSignalStrength` | S |
| `lib/screens/camera_settings/storage_screen.dart` | `docs/client_code/camera_api.md` (`RestStorageClient`) | No `package:camera_api` import; `enabled`/`cardPresent`/`capacityBytes`/`freeBytes` fields and Save both need to call `RestStorageClient.getLocalStorage`/`setLocalStorage` instead of `simulateCameraSave()` | S |
| `lib/screens/alerts/alerts_screen.dart` + `lib/screens/alerts/alert_detail_screen.dart` | `docs/client_code/camera_api.md` (`rest_alerts_client`, `rest_deterrence_alarms_client`) | `AlertsController` seeds the list from `_seedAlerts()` (with `picsum.photos` thumbnails) instead of `RestAlertsClient`; detail screen plays the shared dummy video instead of a real clip/snapshot fetch | M |
| `lib/screens/camera_live/camera_live_screen.dart` | `docs/client_code/camera_api.md` (`SnapshotClient`/`WanPreviewSnapshotClient`, `WebRtcUriClient`/`CloudStreamingClient`, `WanLiveViewClient`/`KvsPlaybackClient`) | No `package:camera_api` import anywhere in the file; live tab, snapshot capture, and the playback/recording timeline (`_mockDayEvents`, `_mockRecordedRanges`) all run on the bundled `assets/videos/camera_dummy.mp4` instead of the four mapped-but-unintegrated client classes | L |

All four are `/integrate-client-code` jobs, not blocked on the senior engineer — the classes they need already exist and are documented.

## Blocked (needs new client code)

Nothing in `docs/client_code/camera_api.md` (or `packages/camera_api` generally, which is camera-only) covers these areas. Each needs a new client file from the senior engineer before `integrate-client-code` can act.

- **AI-detection / recording camera-settings** — `lib/screens/camera_settings/motion_detection_screen.dart`, `intrusion_detection_screen.dart`, `line_crossing_screen.dart`, `person_detection_screen.dart`, `vehicle_detection_screen.dart`, `recording_screen.dart`, `danger_zone_screen.dart`, `tags_screen.dart`: no client code for AI-detection config, deterrence rules, recording schedules, or camera tags/danger-zone actions — all Save actions call the local `simulateCameraSave()` stub.
- **Events** — `lib/screens/events/events_screen.dart`, `event_detail_screen.dart`, `events_summary_screen.dart`: no client code maps recorded-event listing, summary stats, or clip playback; `EventsController._seedEvents()` and a dummy video asset stand in.
- **Dashboard** — `lib/screens/dashboard/dashboard_screen.dart`: composes `HomesController`/`AlertsController`/`EventsController`, all of which are themselves locally seeded; no direct API call and nothing to wire until those controllers have real data sources.
- **Account/auth** — `lib/screens/account/account_screen.dart` (`_mockAppVersion`), `account_settings_screen.dart`, `active_sessions_screen.dart` (explicitly commented "static mock data"), `camera_access_screen.dart`, `create_user_screen.dart`, `help_support_screen.dart`, `invite_user_screen.dart`, `notification_preferences_screen.dart`, `users_invites_screen.dart` (explicitly commented "static mock data"): no user/session/auth/notification-preferences client exists — `camera_api` is camera-only.
- **Homes** — `lib/screens/homes/manage_homes_screen.dart`: add/rename/delete home/room all mutate local `HomesController` state (backed by `shared_preferences`) only; no server-side homes/rooms API documented.
- **Auth entry** — `lib/screens/login/login_screen.dart`, `lib/screens/signup/signup_screen.dart`: `_submit()` does `await Future.delayed(400ms)` then navigates; no auth client documented anywhere in `docs/client_code/`.

## Full Detail

| Screen (file) | Element/action | Status | Client code covering it | Notes |
|---|---|---|---|---|
| `lib/screens/scan/scanned_devices_screen.dart` | LAN device scan/list | ✅ | `docs/client_code/camera_api.md` (`WsDiscoveryClient`) | Real WS-Discovery scan replaces the old fake stub list |
| `lib/screens/scan/scanning_popup.dart` | Scanning progress popup | ✅ | `docs/client_code/camera_api.md` (`WsDiscoveryClient`, via `scanned_devices_screen`) | Reflects the same real scan, no direct client import needed |
| `lib/screens/camera_settings/camera_info_screen.dart` | "Sync from camera" (name/timezone/identity fields) | ✅ | `docs/client_code/camera_api.md` (`OnvifDeviceClient`, `CapabilitiesClient`) | Populates manufacturer/model/firmware/serial/MAC/IP; `WanDeviceIdentityClient` (WAN counterpart) still not wired — flagged as follow-up in the client-code doc itself |
| `lib/screens/camera_settings/night_mode_screen.dart` | Night-vision mode controls | ✅ | `docs/client_code/camera_api.md` (`NightVisionClient`) | LAN `packages/camera_api` client imported and used |
| `lib/screens/camera_settings/video_mode_screen.dart` | Orientation/mirror-flip controls | ✅ | `docs/client_code/camera_api.md` (`MirrorFlipClient`) | LAN client imported and used |
| `lib/screens/camera_settings/imaging_screen.dart` | Day/night, WDR, brightness/contrast, etc. | ✅ | `docs/client_code/camera_api.md` (`OnvifImagingClient`) | LAN client imported and used |
| `lib/screens/camera_settings/video_encoder_screen.dart` | Encoder/bitrate/resolution controls | ✅ | `docs/client_code/camera_api.md` (`OnvifVideoEncoderClient`) | LAN client imported and used |
| `lib/screens/camera_settings/privacy_mode_screen.dart` | Privacy mask regions | ✅ | `docs/client_code/camera_api.md` (`MaskClient`, `PrivacyModeClient`) | LAN clients imported and used |
| `lib/screens/camera_settings/on_screen_display_screen.dart` | OSD overlay text/position | ✅ | `docs/client_code/camera_api.md` (`OsdClient`) | LAN client imported and used |
| `lib/screens/camera_settings/audio_screen.dart` | Speaker/mic volume controls | ✅ | `docs/client_code/camera_api.md` (`AudioCapabilityClient`, `SpeakerVolumeClient`/`AudioVolumeClient`) | LAN clients imported and used |
| `lib/screens/camera_settings/wifi_config_screen.dart` | Network name / Wi-Fi Save | ⚠️ | `docs/client_code/camera_api.md` (`NetworkInfoClient`) | Save calls `simulateCameraSave()` instead of the real client; no `camera_api` import present |
| `lib/screens/camera_settings/storage_screen.dart` | SD card status + storage toggle Save | ⚠️ | `docs/client_code/camera_api.md` (`RestStorageClient`) | Save calls `simulateCameraSave()`; no `camera_api` import present |
| `lib/screens/camera_live/camera_live_screen.dart` | Live view stream | ⚠️ | `docs/client_code/camera_api.md` (`WebRtcUriClient`/`CloudStreamingClient`, `WanLiveViewClient`) | Plays bundled `assets/videos/camera_dummy.mp4`; no `camera_api` import |
| `lib/screens/camera_live/camera_live_screen.dart` | Snapshot capture | ⚠️ | `docs/client_code/camera_api.md` (`SnapshotClient`/`WanPreviewSnapshotClient`) | Trims a copy of the dummy asset instead of calling a real snapshot endpoint |
| `lib/screens/camera_live/camera_live_screen.dart` | Playback / recording timeline | ⚠️ | `docs/client_code/camera_api.md` (`KvsPlaybackClient`) | `_mockDayEvents()`/`_mockRecordedRanges` are hardcoded, share the dummy video |
| `lib/screens/alerts/alerts_screen.dart` | Alert list | ⚠️ | `docs/client_code/camera_api.md` (`rest_alerts_client`) | `AlertsController._seedAlerts()` hardcodes entries, `picsum.photos` thumbnails |
| `lib/screens/alerts/alert_detail_screen.dart` | Alert detail / clip playback | ⚠️ | `docs/client_code/camera_api.md` (`rest_alerts_client`, `rest_deterrence_alarms_client`) | Plays the shared dummy video asset, no real clip fetch |
| `lib/screens/camera_settings/motion_detection_screen.dart` | Sensitivity/zone/Save controls | ❌ | — | Save calls `simulateCameraSave()`; no client covers AI-detection config |
| `lib/screens/camera_settings/intrusion_detection_screen.dart` | Zone drawing + Save | ❌ | — | Same gap as motion detection |
| `lib/screens/camera_settings/line_crossing_screen.dart` | Line rule + Save | ❌ | — | Same gap as motion detection |
| `lib/screens/camera_settings/person_detection_screen.dart` | Sensitivity/Save | ❌ | — | Same gap as motion detection |
| `lib/screens/camera_settings/vehicle_detection_screen.dart` | Sensitivity/Save | ❌ | — | Same gap as motion detection |
| `lib/screens/camera_settings/recording_screen.dart` | Recording schedule + Save | ❌ | — | No recording-schedule client documented |
| `lib/screens/camera_settings/danger_zone_screen.dart` | Reboot/reset/delete actions | ❌ | — | Both actions call `simulateCameraSave()`; no device-lifecycle client documented |
| `lib/screens/camera_settings/tags_screen.dart` | Camera tags + Save | ❌ | — | Save calls `simulateCameraSave()`; no tags client documented |
| `lib/screens/dashboard/dashboard_screen.dart` | Home/camera grid, alert/event summaries | ❌ | — | Composes `HomesController`/`AlertsController`/`EventsController`, all locally seeded; no direct API call |
| `lib/screens/events/events_screen.dart` | Recorded-event list | ❌ | — | `EventsController._seedEvents()`; `_mockRecordedRanges` timeline |
| `lib/screens/events/event_detail_screen.dart` | Event clip playback | ❌ | — | Plays the shared dummy video asset |
| `lib/screens/events/events_summary_screen.dart` | Event summary stats | ❌ | — | Derived from locally seeded `EventsController` data only |
| `lib/screens/homes/manage_homes_screen.dart` | Add/rename/delete home/room | ❌ | — | Mutates local `HomesController` (`shared_preferences`-backed) state only |
| `lib/screens/login/login_screen.dart` | Login submit | ❌ | — | `_submit()` awaits `Future.delayed(400ms)` then navigates; no auth client documented |
| `lib/screens/login/login_screen.dart` | "Continue with Google" | ❌ | — | Same stub pattern as `_submit()` |
| `lib/screens/signup/signup_screen.dart` | Signup submit | ❌ | — | Same `Future.delayed(400ms)` stub as login |
| `lib/screens/signup/signup_screen.dart` | "Continue with Google" | ❌ | — | Same stub pattern |
| `lib/screens/account/account_screen.dart` | Profile / app version display | ❌ | — | `_mockAppVersion` and local `ProfileController` state only |
| `lib/screens/account/account_settings_screen.dart` | Account settings form | ❌ | — | No account-settings client documented |
| `lib/screens/account/active_sessions_screen.dart` | Session list / revoke | ❌ | — | Explicitly commented "static mock data" in source; `WanDeviceIdentityClient` mapped only loosely ("Authentication card") and not actually a sessions API |
| `lib/screens/account/camera_access_screen.dart` | Per-user camera access toggles | ❌ | — | No access-control client documented |
| `lib/screens/account/create_user_screen.dart` | Create user form | ❌ | — | No user-management client documented |
| `lib/screens/account/help_support_screen.dart` | Help/support content | ❌ | — | Static content, none expected to be dynamic |
| `lib/screens/account/invite_user_screen.dart` | Invite user form | ❌ | — | No invite client documented |
| `lib/screens/account/notification_preferences_screen.dart` | Notification toggles | ❌ | — | No notification-preferences client documented |
| `lib/screens/account/users_invites_screen.dart` | Users/invites list | ❌ | — | Explicitly commented "static mock data" in source |

**Excluded (nav-only, no data elements):** `lib/screens/camera_settings/camera_settings_screen.dart`, `lib/screens/camera_settings/detections_screen.dart`, `lib/screens/camera_settings/video_display_screen.dart`, `lib/screens/shell/main_shell.dart`, `lib/screens/splash/splash_screen.dart`.
