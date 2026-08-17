# UI ↔ API Coverage Gap Report

Audits every screen in `lib/screens/` against real client code — `packages/camera_api`
(`API_REFERENCE.md`/`SETTINGS_API_GUIDE.md`, the sole camera network layer) and `docs/client_code/`
(`auth_api`). The reverse of `scenario-gap-audit`: this checks whether *already-built* UI is
actually wired to a real backend call, or still running on mock/local-only data.

**Generated:** 2026-08-17. Supersedes the 2026-08-14 version — a large batch of camera-settings
screens (Imaging, Night Mode, OSD, Privacy Mode, Video Encoder, Video Mode, Audio) and the live-view
/ two-way-talk flow were wired to real `camera_api` clients since then.

## Summary

| | Count |
|---|---|
| Screens checked | 43 |
| Elements/actions checked | ~230 |
| ✅ Wired to real client code | ~150 |
| ⚠️ Client code exists, not wired | ~24 |
| ❌ No client code available | ~56 |

---

## Quick Wins — client code already exists, just needs wiring

Sorted smallest-remaining-gap first (screens closest to fully done).

| Screen (file) | Client code covering it | What's missing | Est. effort |
|---|---|---|---|
| `lib/screens/camera_settings/camera_info_screen.dart` (CAMINFO-008/009 Wi-Fi network/signal) | `NetworkInfoClient.getWifiSsid`/`.getWifiSignalStrength` | Same client is already imported and used one screen over (`wifi_config_screen.dart`) — `camera_info_screen.dart`'s sync (CAMINFO-032) just never calls it, leaving these two rows permanently stub. | S |
| `lib/screens/camera_settings/danger_zone_screen.dart` (Soft Reset, Hard Reset) | `OnvifDeviceClient.reboot()`, `.factoryReset(FactoryResetMode.soft/.hard)`, `WanDeviceIdentityClient` mirrors, `device_reset_types.dart` | File has no `import 'package:camera_api/camera_api.dart'` at all — both actions call `simulateCameraSave()` (fake 800ms delay, always succeeds). The UI already has separate Soft/Hard tiles, mapping 1:1 onto `FactoryResetMode.soft`/`.hard`. | S |
| `lib/screens/camera_settings/detections/person_detection_screen.dart` (PERSON-003 toggle) | `EventPreferencesClient`/`WanEventPreferencesClient` — `"PersonDetected"` confirmed in today's `supportedEventTypes` | Toggle only flips local `_enabled`; never calls `getEventPreferences`/`setEventPreferences`. This is the one detection toggle with a **confirmed** (not speculative) event-type match. | S |
| `lib/screens/camera_settings/detections/motion_detection_screen.dart` (MOTION-003 toggle) | `EventPreferencesClient`/`WanEventPreferencesClient` (plausible match — exact `"MotionDetected"` key not confirmed in the doc's example list, which is dynamic) | Same pattern as Person Detection — local toggle only, never calls the client. | S |
| `lib/screens/camera_settings/recording_and_storage/storage_screen.dart` (STOR-003/004/005/006/007/011) | `RestStorageClient` (`API_REFERENCE.md`, "Local storage (SD card) status/enable") | No `camera_api` import anywhere in the file. Enable toggle, capacity/health/failure rows, and Format action are all stub-seeded `Camera` model fields + `simulateCameraSave()`. | M |
| `lib/screens/camera_settings/detections/intrusion_detection_screen.dart` (zone CRUD: add/draw/select/delete/clear) | `MaskClient`/`WanMaskClient` (**speculative** — that client is scoped to Privacy Mode's fixed 4-point rectangle mask, not free-form intrusion-exclusion polygons; shape/semantics don't cleanly match) | All zone state is local `List<DrawableZone>`; only ever reaches the camera through the fake `simulateCameraSave()` on Save. Flagged lower confidence than the others — may turn out to need new client code once actually attempted, not a clean swap. | L |

For any of these, `/integrate-client-code` can close the gap now — the client methods already exist and are documented.

---

## Blocked — no client code available yet

Grouped by area; nothing in `docs/client_code/` or `packages/camera_api` covers these at all, so they need a new file/API from the senior engineer before there's anything to wire.

**Detection settings (no client anywhere for these concepts):**
- Sensitivity/confidence sliders on Motion, Person, Vehicle, Intrusion, and Line Crossing detection screens — no `camera_api` client exposes a numeric sensitivity/confidence parameter for any detection type.
- `vehicle_detection_screen.dart`'s enable toggle — unlike Person Detection, `"VehicleDetected"` isn't in today's documented event-type list at all.
- `line_crossing_screen.dart` — direction dropdown, line-position drag/reset, and (unlike Intrusion's zones) no client anywhere models line-segment/direction geometry, not even a speculative fit.

**Recording & storage:**
- `recording_screen.dart` — recording mode and schedule-window controls have no documented client/API at all (distinct from `storage_screen.dart`'s gap above, which at least has `RestStorageClient` to reach for).
- `storage_screen.dart`'s retention-duration control and deletion-history log — no retention-policy or audit-log client exists.

**Camera info:**
- `camera_info_screen.dart` — "Network speed" row and the Modify Password dialog (CAMINFO-015–021): no client class covers either concept (no `setPassword`/`changePassword`-style method on `OnvifDeviceClient`).

**Tags / OSD overlays:**
- `tags_screen.dart` — Bitrate/Live/Signal-Strength tag toggles are app-side compositing over the live preview, not a camera setting; genuinely nothing to wire to, by design.

**Recordings, alerts, and events (no backend exists for any of it):**
- `alerts_screen.dart`, `alert_detail_screen.dart` — all 23 seed alerts, thumbnails, and video clips are local mock data (`AlertsController`, `picsum.photos` URLs, bundled dummy video asset); no push/alerts backend exists.
- `events_screen.dart`, `event_detail_screen.dart`, `events_summary_screen.dart` — same pattern via `EventsController`'s hardcoded seed list; no recordings/events API exists in `camera_api` at all.
- `camera_live_screen.dart`'s Playback tab (LIVE-019 timeline/day picker) — draws from the same mock `EventsController` data.

**Homes & accounts (outside `camera_api`'s and `auth_api`'s scope):**
- `manage_homes_screen.dart` — add/rename/delete home/room is `HomesController` CRUD persisted only to `SharedPreferences`; no home/room management endpoint exists in either audited source.
- `dashboard_screen.dart` — home switcher, favorite/pin/delete/reorder camera actions — same `HomesController`-only persistence.
- Almost all of `account_settings_screen.dart`, `active_sessions_screen.dart`, `users_invites_screen.dart`, `create_user_screen.dart`, `invite_user_screen.dart`, `notification_preferences_screen.dart`, `help_support_screen.dart` — `auth_api` covers only sign-up/sign-in/session/password/sign-out; it has no concept of profile fields (name/phone/avatar), MFA, multi-device session listing, member/role management, invites, or notification preferences. The only real calls in this whole area are `change_password_screen.dart` (`AuthController.changePassword`) and `account_screen.dart`'s log-out button (`AuthController.signOut`); camera-access checklists (`CameraAccessScreen` and its two callers) genuinely enumerate real cameras via `HomesController` but never persist the resulting scope anywhere.

**AI features:**
- Dashboard's "Ask AI" FAB and Live view's "AI Mode" tile run a real on-device model (`AiModelManager`/`llamadart`) — not a stub, but outside `auth_api`/`camera_api`'s scope, so nothing to audit against; their result cards pull from the mock `EventsController`/`HomesController` data noted above.

---

## Full detail table

### Auth & onboarding — fully wired

| Screen | Element/action | Status | Client code | Notes |
|---|---|---|---|---|
| `splash_screen.dart` | Session restore/route | ✅ | `AuthController.restore` | — |
| `login_screen.dart` | Email/password log in (LOGIN-006) | ✅ | `AuthController.signIn` | — |
| `login_screen.dart` | Phone tab | ❌ | — | No phone sign-in in `auth_api`; explicit "not available yet" stub. |
| `login_screen.dart` | Google sign-in (LOGIN-008) | ❌ | — | Explicit stub, no package wired. |
| `login_screen.dart` | Forgot password link | ✅ | nav only | — |
| `forgot_password_screen.dart` | Send code / confirm (FORGOT-003/008) | ✅ | `AuthController.forgotPassword`/`.confirmForgotPassword` | — |
| `signup_screen.dart` | Name field | ❌ | — | `auth_api.signUp` takes only email/password; name never sent anywhere. |
| `signup_screen.dart` | Email sign-up (SIGNUP-008) | ✅ | `AuthController.signUp` | — |
| `signup_screen.dart` | Phone tab / Google | ❌ | — | Same stubs as Login. |
| `confirm_signup_screen.dart` | Confirm code, resend (CONFIRM-005/006) | ✅ | `AuthController.confirmSignUp`/`.resendConfirmationCode` | — |

### Scan & onboarding — mostly wired

| Screen | Element/action | Status | Client code | Notes |
|---|---|---|---|---|
| `scanned_devices_screen.dart` | Scan/Rescan (SCAN-006) | ✅ | `WsDiscoveryClient` | Real WS-Discovery multicast + unicast fallback. |
| `scanned_devices_screen.dart` | Device probing, status | ✅ | `NuraeyeClient.areYouNuraeyeDevice`, `OnvifDeviceClient` | — |
| `scanned_devices_screen.dart` | Connect form (SCAN-010) | ✅ | `OnvifDeviceClient` (multiple methods) | Real credential verification before add. |
| `scanned_devices_screen.dart` | Add camera → `HomesController.addCamera` | ❌ | — | Local persistence only — by design, no camera/home backend exists (matches `manage_homes_screen.dart`). |
| `scanned_devices_screen.dart` | Auto-sync after add | ✅ | `syncCameraFromDevice` (`OnvifDeviceClient`, `CapabilitiesClient`, `SnapshotClient`) | — |
| `scanning_popup.dart` | Dashboard-entry scan | ✅ | `WsDiscoveryClient` | — |
| `scanning_popup.dart` | Rescan-only popup timing | ⚠️ | `WsDiscoveryClient` (real, running) | Popup's own 2s delay is cosmetic, not tied to real scan completion. |

### Dashboard, homes, shell — mixed

| Screen | Element/action | Status | Client code | Notes |
|---|---|---|---|---|
| `dashboard_screen.dart` | Silent thumbnail refresh (5 min) | ✅ | `SnapshotClient` via `refreshCameraSnapshot` | — |
| `dashboard_screen.dart` | Reachability check (15s) | ✅ | `WebRtcUriClient.checkReachable`, `WanDeviceIdentityClient` | LAN-then-WAN, matches convention. |
| `dashboard_screen.dart` | Home switcher, favorite/pin/delete/reorder | ❌ | — | `HomesController` local-only; see Blocked section. |
| `dashboard_screen.dart` | Unread alert badge | ⚠️ | — | Reads mock `AlertsController` data. |
| `dashboard_screen.dart` | Ask AI FAB | ❌* | — | Real on-device model, outside audited scope; result cards use mock data. |
| `manage_homes_screen.dart` | All home/room CRUD | ❌ | — | See Blocked section. |
| `main_shell.dart` | Tab navigation | ✅ | n/a | — |
| `main_shell.dart` | Unread badge dot | ⚠️ | — | Mock `AlertsController` data. |

### Alerts & Events — no backend exists

| Screen | Status | Notes |
|---|---|---|
| `alerts_screen.dart` | ⚠️ | All filtering/mark-read/delete/snooze over `AlertsController`'s 23 hardcoded seed alerts. |
| `alert_detail_screen.dart` | ⚠️ | Playback/download/share operate on a bundled dummy video asset + picsum thumbnails. |
| `events_screen.dart` | ⚠️ | `EventsController` hardcoded seed events + mock recording-coverage ranges. |
| `event_detail_screen.dart` | ⚠️ | Same dummy-asset pattern as alert detail. |
| `events_summary_screen.dart` | ❌ | Pure client-side aggregation over the same mock event data — no analytics API exists at all. |

### Camera Live — mostly wired

| Screen | Element/action | Status | Client code | Notes |
|---|---|---|---|---|
| `camera_live_screen.dart` | Live video (LAN/WAN) | ✅ | `LiveViewController` → `WebRtcUriClient`, WebRTC signaling | Reworked this session — full-negotiation-per-toggle fix. |
| `camera_live_screen.dart` | Two-way talk (LIVE-011, TALK bar) | ✅ | Same `LiveViewController`, `POST /webrtc {talk:true}` | Fixed this session (see live_view_controller.dart history). |
| `camera_live_screen.dart` | Mute (LIVE-007) | ✅ | `LiveViewController` track control | Real local track mute on the live WebRTC stream. |
| `camera_live_screen.dart` | Snapshot (LIVE-009) | ✅ | `LiveViewController.captureSnapshot` | Real frame capture from the live track, falls back to boundary screenshot only off the Live tab. |
| `camera_live_screen.dart` | Record (LIVE-010) | ✅ | `flutter_webrtc` recorder against the real live track | Not a `camera_api` client, but genuinely real media, not mock. |
| `camera_live_screen.dart` | Spotlight (LIVE-018) | ✅ | `DeterrenceClient`/`WanDeterrenceClient` | Wired 2026-08-17 — real activate/deactivate with LAN→WAN retry, matching the Privacy/Video Mode shortcut pattern. |
| `camera_live_screen.dart` | Privacy shortcut (LIVE-041) | ✅ | `PrivacyModeClient`/`WanPrivacyModeClient` | — |
| `camera_live_screen.dart` | Video mode shortcut (LIVE-042) | ✅ | `OnvifImagingClient`/`WanImagingClient` | — |
| `camera_live_screen.dart` | AI Mode (LIVE-043) | ❌* | — | Real on-device model, outside audited scope. |
| `camera_live_screen.dart` | Playback tab (LIVE-019 timeline) | ❌ | — | Mock `EventsController` data. |

### Camera Settings — top-level & danger zone

| Screen | Status | Notes |
|---|---|---|
| `camera_settings_screen.dart` | ✅ | Pure navigation menu, no direct calls of its own. |
| `camera_info_screen.dart` | ✅ (mostly) | Name/timezone/sync fully wired to `OnvifDeviceClient`/`CapabilitiesClient`; Wi-Fi rows ⚠️, network speed + password change ❌ (see Quick Wins/Blocked). |
| `danger_zone_screen.dart` | ⚠️/⚠️/✅ | Soft/Hard Reset ⚠️ (Quick Win); Delete Camera ✅ (correctly local-only). |
| `wifi_config_screen.dart` | ✅ | Fully wired — `OnvifDeviceClient`, `NetworkInfoClient`, phone-side `wifi_scan` plugin. |

### Camera Settings — Video & Display group (fully wired)

`imaging_screen.dart`, `night_mode_screen.dart`, `on_screen_display_screen.dart`, `privacy_mode_screen.dart`,
`video_encoder_screen.dart`, `video_mode_screen.dart`, `audio_screen.dart` — ✅ across the board: every
field's load/save/Options/reload path calls the correct real `camera_api` LAN client with WAN fallback,
per `SETTINGS_API_GUIDE.md`'s LAN/WAN convention. `video_display_screen.dart` is a pure navigation menu.
`tags_screen.dart` is the one exception (❌, by design — see Blocked section).

### Camera Settings — Detections group

| Screen | Status | Notes |
|---|---|---|
| `detections_screen.dart` | ✅ | Pure navigation menu. |
| `motion_detection_screen.dart` | ⚠️ toggle / ❌ sensitivity | See Quick Wins / Blocked. |
| `person_detection_screen.dart` | ⚠️ toggle / ❌ confidence / ⚠️ zones (speculative) | Toggle has confirmed client match — top Quick Win. |
| `vehicle_detection_screen.dart` | ❌ toggle / ❌ confidence | No matching event type documented at all. |
| `intrusion_detection_screen.dart` | ⚠️ toggle (speculative) / ❌ sensitivity / ⚠️ zones (speculative, weak fit) | See Quick Wins. |
| `line_crossing_screen.dart` | ⚠️ toggle (speculative) / ❌ everything else | Weakest fit of the detection screens — no client models line/direction geometry at all. |

### Camera Settings — Recording & Storage

| Screen | Status | Notes |
|---|---|---|
| `recording_screen.dart` | ❌ | No client/API for recording mode or schedule windows at all. |
| `storage_screen.dart` | ⚠️ | `RestStorageClient` exists and covers most of this screen but is never imported. See Quick Wins. |

### Account

| Screen | Status | Notes |
|---|---|---|
| `account_screen.dart` | ✅ log out / ❌ else | Log out is real (`AuthController.signOut`); profile fields are hardcoded seed data. |
| `account_settings_screen.dart` | ✅ change-password nav / ❌ else | Display name/email/phone edits, 2FA, delete account all local/fake — no matching `auth_api` methods exist. |
| `active_sessions_screen.dart` | ❌ | Fully hardcoded device list; no multi-session API exists. |
| `camera_access_screen.dart` | ✅ enumeration / ❌ persistence | Real camera list via `HomesController`; selection never saved anywhere. |
| `change_password_screen.dart` | ✅ | Fully wired — `AuthController.changePassword`. |
| `create_user_screen.dart` | ✅ camera checklist / ❌ else | No admin-create-user, role, or expiry API exists. |
| `help_support_screen.dart` | ✅ FAQ search (local data, expected) / ❌ else | No support/ticketing API exists. |
| `invite_user_screen.dart` | ✅ camera checklist / ❌ else | No invite-send API exists. |
| `notification_preferences_screen.dart` | ❌ | No notification-preferences API exists (distinct from camera-side `EventPreferencesClient`). |
| `users_invites_screen.dart` | ✅ nav / ❌ else | Members/roles/invites all hardcoded local state. |

---

## Notes on confidence

Items marked "speculative" in the Quick Wins/Blocked sections (Intrusion zones, Motion/Line-Crossing
toggles) reflect real shape/semantic mismatches spotted during this audit, not just "not yet tried" —
worth a design discussion before assuming `/integrate-client-code` can close them cleanly.
