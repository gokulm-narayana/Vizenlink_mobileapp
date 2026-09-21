# UI ↔ API Coverage Gap Report

_Generated 2026-09-11, refreshed 2026-09-15 after `packages/camera_api` was entirely replaced
again from the `nuraeye-rt` reference app (new `TalkUriClient`, `rest_health_client.dart`/
`bbox_overlay_client.dart`/`loitering_duration_client.dart` and their WAN mirrors). This pass
re-verifies every Part B claim by reading actual current call sites in `lib/screens/**` and
`lib/app_state/**` rather than trusting the prior report, and found one significant miss in the
prior pass (`OnvifReplayControlClient` is now genuinely wired) plus two items that can now be
resolved definitively instead of flagged "unconfirmed." Part A / Quick Wins / Blocked are
unchanged from the 2026-09-11 pass — this refresh focused on Part B._

## Summary

**Part A — UI → API** (screens in `lib/screens/**/*.dart` cross-referenced against
`docs/client_code/*.md` + `docs/screens/**/*.md`):

| Status | Count (screens, element-groups) |
|---|---|
| ✅ Wired | 34 screens fully or near-fully wired |
| ⚠️ Client code exists, not wired | 6 screens / element-groups |
| ❌ No client code available | 8 screens / element-groups |

**Part B — API → UI** (capabilities from `docs/client_code/*.md` +
`packages/camera_api/API_REFERENCE.md` + `SETTINGS_API_GUIDE.md`, ~40 non-plumbing capabilities
checked):

| Status | Count |
|---|---|
| ✅ Has UI | 34 |
| 🆕 API available, no UI yet | 6 |

**Key correction vs. the previous report / stale doc notes:** `docs/client_code/camera_api.md`'s
"New in the 2026-09-07 drop" table claims `LoiteringDurationClient`/`BboxOverlayClient` and
`HealthClient`/`WanHealthClient` have "no matching UI yet." That is now false — both are wired
into `person_detection_screen.dart` and `camera_info_screen.dart`/`camera_sync.dart`
respectively (verified by reading the call sites, not just doc comments). `TalkUriClient` is
confirmed still unwired — but two-way talk itself **is** fully working in `camera_live_screen.dart`
via a different, older mechanism (WebRTC renegotiation on the live-view peer connection, see
`TWO_WAY_TALK_GUIDE.md`), so this is a duplicate/unadopted transport, not a missing feature.

**New corrections from this 2026-09-15 refresh:**
- **`OnvifReplayControlClient` was wrongly listed as unwired.** It is genuinely called —
  `_PlaybackTabState.initState()`/`_openClip` in `lib/screens/camera_live/camera_live_screen.dart`
  (search `_replayControl.getReplayUri(clip.id.toString())`, ~line 3357) resolves each clip's
  RTSPS playback URI and streams it live through `RtspRemuxProxy`, replacing
  `RecordingsClient.downloadClip()`-then-play-a-temp-file as the real playback path.
  `RecordingsClient` is still used here too, but now only for `getRecordings()` (clip listing) and
  `downloadClip()` (the one remaining real use: saving a clip to the gallery). Moved out of the
  🆕 table's "superseded, do not wire" bullet — `OnvifRecordingClient`/`OnvifSearchClient` are
  still correctly unwired and still correctly flagged "do not wire," this correction is
  `OnvifReplayControlClient` only.
- **`RestHealthClient` resolved, not just flagged uncertain.** Read `rest_health_client.dart`
  directly: it's a generated client hitting the identical `GET /nuraeye/health` endpoint
  `HealthClient` (hand-written) already covers, same data, different response type
  (`GetDeviceHealthResponse` vs. `HealthStatus`) — the exact "hand-written vs. generated REST
  client" duplicate-surface pattern `SETTINGS_API_GUIDE.md` already documents for
  `RestPrivacyClient`/`RestVideoImageClient`/etc. ("always use the hand-written client... the
  generated clients are current unused reserve API surface"). Not a capability gap — removed from
  the 🆕 table.
- **Device-identity Location/Password setters resolved, not just flagged uncertain.**
  `camera_info_screen.dart` confirmed calling `OnvifDeviceClient.setUserPassword`/
  `WanDeviceIdentityClient.setUserPassword` (with WAN fallback) — the password setter **is**
  wired. `setDeviceLocation` (LAN or WAN) is genuinely never called anywhere; the screen's own
  "Location" section (`CAMINFO-004` `Home` dropdown) is an unrelated local Home/Room-assignment
  feature backed by `HomesController`, not the camera's ONVIF location-scope field. Narrowed the
  🆕 entry to `setDeviceLocation` only.
- **Re-verified the "why this needs a fresh pass" items and confirmed the framing still holds:**
  `OnvifVideoEncoderClient.getProfiles()` is real in `live_view_controller.dart`'s
  `loadLanProfiles()` (feeds `camera_live_screen.dart`'s Stream Quality picker) and
  `video_stream_encoder_screen.dart` correctly targets `kMediumResVideoEncoderToken`/
  `kLowResVideoEncoderToken` on both LAN and WAN for the Medium/Low streams — not stale.
  `AudioCapabilityClient` now has two real call sites (`audio_screen.dart` and
  `camera_live_screen.dart`'s Talk button, gated on `_audioCapability?.hasSpeaker`, ~line 1029).
  `TalkUriClient`, `BboxOverlayClient`/`LoiteringDurationClient` (+ WAN mirrors), and
  `WanLocalStorageClient` all re-confirmed exactly as the prior report described (see 🆕 table).

---

## Quick Wins (⚠️ — client code exists, just needs wiring)

Sorted smallest-gap-first. All five detection-enable toggles follow the exact pattern already
proven working in `person_detection_screen.dart` — that screen calls
`EventPreferencesClient(nuraeye).setEventPreferences({...})` /
`WanEventPreferencesClient(thingName).setEventPreferences({...})` around its `_enabled` toggle;
the other four detection screens have an identical `_enabled` bool wired only to local
`Camera` model state, never sent to the camera.

| Screen (file) | Client code covering it | What's missing | Est. effort |
|---|---|---|---|
| `lib/screens/camera_settings/motion_detection_screen.dart` | `docs/client_code/camera_api.md` → `EventPreferencesClient`/`WanEventPreferencesClient` | `_save()` (line ~106) never calls `EventPreferencesClient`/`WanEventPreferencesClient.setEventPreferences({'motion': _enabled})`; only writes `Camera.motionDetectionEnabled` locally. No `getEventPreferences` call on load either. | S |
| `lib/screens/camera_settings/vehicle_detection_screen.dart` | same | Same gap as motion — `_save()` line ~106 doesn't call `setEventPreferences`. | S |
| `lib/screens/camera_settings/intrusion_detection_screen.dart` | same | No `_save`/API call found at all for the `_enabled` toggle — writes only to `Camera.intrusionDetectionEnabled`. Also has zone-drawing UI that may map to `MaskClient`/`WanMaskClient` (unconfirmed — cross-check zone semantics with the senior before wiring). | S/M |
| `lib/screens/camera_settings/line_crossing_screen.dart` | same | Same as intrusion — `_enabled` toggle not sent via `EventPreferencesClient`. | S/M |
| `lib/screens/camera_settings/parking_monitoring_screen.dart` | same, **if** `"parking"`/wrong-bay is a key `CapabilitiesClient.supportedEventTypes` actually reports | `_enabled` toggle (line ~60/287) not sent via `EventPreferencesClient`. Verify with the senior first whether parking monitoring is camera-side-gated at all, or purely an app-side zone feature — if the camera has no such event-type key this is actually ❌, not ⚠️. | S (pending verification) |
| `lib/screens/events/events_screen.dart` | `docs/client_code/camera_api.md` → `RecordingsClient` (already wired for real clip playback in `camera_live_screen.dart`'s Playback tab) | The day-timeline "recording coverage" band still uses `const _mockRecordedRanges` (line 15) instead of a real `RecordingsClient.getRecordings()`-derived coverage list. | M |

`/integrate-client-code` (or `/client-pipeline`) can close each of these — the client class is
already documented and already has a working call-site pattern elsewhere in the app to copy.

---

## Blocked (needs new client code from the senior)

No `docs/client_code/*.md` entry, and nothing in `packages/camera_api` covers these — a new file
from the senior engineer is needed before `/integrate-client-code` applies.

| Screen (file) | What's missing |
|---|---|
| `lib/screens/account/active_sessions_screen.dart` | Static mock session list (own doc comment admits it) — no session-listing API exists anywhere (`auth_api` has no such endpoint; `WanDeviceIdentityClient` was only ever a *candidate*, per `camera_api.md`, never confirmed as the right fit). |
| `lib/screens/account/users_invites_screen.dart` | Static mock users/invites list — no user-management/invite API; `HomesController` is local-only state (confirmed: no `http`/network client in `homes_controller.dart`). |
| `lib/screens/account/create_user_screen.dart` | Same — writes only to local `HomesController` state, no backend call. |
| `lib/screens/account/invite_user_screen.dart` | Same. |
| `lib/screens/account/camera_access_screen.dart` | Same — camera-access-scope editing is local-only. |
| `lib/screens/alerts/alert_detail_screen.dart` | No real alert-clip API — screen intentionally shows a snapshot-only placeholder (own doc comment, "removed the dummy video per direct user request"), correctly not faking data, but the underlying capability doesn't exist yet. |
| `lib/screens/events/event_detail_screen.dart` | Same — thumbnail-only, no real event-clip API. |
| `lib/screens/events/events_summary_screen.dart` | Own doc comment: "Mock/local data only — no backend/CCTV protocol" for the per-day activity chart. |

Note: `account_screen.dart`'s `_mockAppVersion` constant is not a real gap (app version isn't a
camera/backend concern) and is excluded from the count above.

---

## Available APIs With No UI Yet (🆕)

| Capability (class/method) | Documented in | Likely screen area | Notes |
|---|---|---|---|
| `TalkUriClient.getTalkUri()` (`lib/src/lan/nuraeye/talk_uri_client.dart`) | `API_REFERENCE.md` §"TalkUriClient" (not yet in `docs/client_code/`) | `camera_live_screen.dart` (two-way talk) | Not a functional gap — talk already works via `LiveViewController.startTalk`/`endTalk` (WebRTC renegotiation on the existing live-view connection). This is a newer, dedicated RTSPS-based module (port 560) that duplicates that path; adopting it would be a transport swap, not a new feature. Flag to the senior/user before treating as a priority. |
| `WanLocalStorageClient` (`lib/src/wan/wan_local_storage_client.dart`) — `getStatus()`/`setEnabled()` | `API_REFERENCE.md` §"WanLocalStorageClient" | `camera_settings/storage_screen.dart` | LAN counterpart `LocalStorageClient` **is** wired into `storage_screen.dart` (confirmed, ~line 141); grepped `storage_screen.dart` for any `Wan`/transport-fallback reference — none found. Storage settings currently have no WAN fallback path at all. |
| `CloudStreamingLanClient.getCloudStreamingStatus()` (`lib/src/lan/nuraeye/cloud_streaming_client.dart`) | `API_REFERENCE.md` §"CloudStreamingLanClient" | `camera_live_screen.dart` / `live_view_controller.dart` | Narrowed from the prior report's vague "unused surface" note: `CloudStreamingLanClient` is instantiated in exactly one place in `live_view_controller.dart` and only `.stopCloudStreaming()` is called there (opportunistic LAN-first stop). `.getCloudStreamingStatus()` — the LAN status check — is never called; all status polling goes through `AwsWanLiveViewClient.getCloudStreamingStatus()` (WAN) instead, even when LAN is reachable. |
| `OnvifRecordingClient` / `OnvifSearchClient` | `camera_api.md` — explicitly marked **superseded**, not for integration | n/a | Confirmed zero references anywhere in `lib/`. The team deliberately moved to `RecordingsClient` (plain REST) instead — do not wire these. (`OnvifReplayControlClient`, previously grouped with these two, is **not** in this bullet any more — see the correction note above, it is now genuinely wired into `camera_live_screen.dart`'s Playback tab.) |
| `OnvifDeviceClient.setDeviceLocation()` / `WanDeviceIdentityClient.setDeviceLocation()` (+ reading `DeviceIdentity.location`) | `API_REFERENCE.md` §"OnvifDeviceClient"/"WanDeviceIdentityClient", `SETTINGS_API_GUIDE.md` §"Device Identity" | `camera_info_screen.dart` | Narrowed from the prior report: `setDeviceName`/`setTimeZone`/`setUserPassword` are all confirmed wired (LAN with WAN fallback) in `camera_info_screen.dart`. Only the camera-side **location** scope field has no UI — the screen's existing "Location" section (`CAMINFO-004`, a Home dropdown) is an unrelated local Home/Room-assignment feature backed by `HomesController`, not this ONVIF field. Would need a new editable field — plan-before-code rule applies. |
| Recording-coverage read via `RecordingsClient.getRecordings()` for `events_screen.dart`'s day-timeline band | `camera_api.md` (already proven elsewhere — see correction note above) | `events/events_screen.dart` | `RecordingsClient` is now proven in two real call sites in `camera_live_screen.dart` (`getRecordings()` for clip listing, `downloadClip()` for gallery-save); `events_screen.dart`'s day-timeline still uses `const _mockRecordedRanges` (confirmed, line 16/247) instead of deriving coverage from a real call. Same item as the Quick Win above — listed here too since the client is already integrated elsewhere in the app. |

This work is new-screen/new-element territory in one case (adding a Location field would be a new
UI element) — per this repo's plan-before-code rule, any actual UI build here needs an element
inventory presented and confirmed first, it is not a same-day `/integrate-client-code` job like
the Quick Wins above.

---

## Full Detail Table (Part A)

Screens not listed individually below were checked and found ✅ fully wired to their documented
client code with no mock/TODO markers found (imports confirmed against `docs/client_code/*.md`
and grepped for real client-class usage): `login_screen`, `signup_screen`,
`confirm_signup_screen`, `forgot_password_screen`, `splash_screen`, `change_password_screen`,
`dashboard_screen`, `camera_live_screen` (live view, snapshot, playback, deterrence, talk, stream
quality — all real), `ai_mode_screen` (local zone-drawing tool, no backend needed by design),
`camera_info_screen` (device sync, health, name, timezone), `imaging_screen`, `night_mode_screen`,
`video_mode_screen`, `video_encoder_screen`, `video_stream_encoder_screen`, `on_screen_display_screen`,
`privacy_mode_screen`, `tags_screen`, `wifi_config_screen`, `danger_zone_screen` (reboot/factory
reset), `audio_screen`, `person_detection_screen`, `storage_screen`, `alerts_screen`,
`alert_settings_screen`, `multiview_screen`, `multiview_reorder_screen`, `scanned_devices_screen`,
`scanning_popup`, `add_camera_manually_dialog`, `manage_homes_screen`, `account_settings_screen`,
`notification_preferences_screen` and `help_support_screen` (static content screens, no API
needed by design), `camera_settings_screen`/`video_display_screen`/`detections_screen` (pure
navigation hubs, no elements of their own).

| Screen (file) | Element/action | Status | Client code covering it | Notes |
|---|---|---|---|---|
| `camera_settings/motion_detection_screen.dart` | Enable/disable toggle | ⚠️ | `camera_api.md` (`EventPreferencesClient`) | Saves only to local `Camera` model |
| `camera_settings/vehicle_detection_screen.dart` | Enable/disable toggle | ⚠️ | `camera_api.md` (`EventPreferencesClient`) | Same |
| `camera_settings/intrusion_detection_screen.dart` | Enable/disable toggle | ⚠️ | `camera_api.md` (`EventPreferencesClient`) | Same; zone UI may separately map to `MaskClient` |
| `camera_settings/line_crossing_screen.dart` | Enable/disable toggle | ⚠️ | `camera_api.md` (`EventPreferencesClient`) | Same |
| `camera_settings/parking_monitoring_screen.dart` | Enable/disable toggle | ⚠️ (pending verification) | `camera_api.md` (`EventPreferencesClient`) | Confirm "parking" is a real supported event-type key first |
| `events/events_screen.dart` | Day-timeline recording-coverage band | ⚠️ | `camera_api.md` (`RecordingsClient`, already proven in `camera_live_screen.dart`) | Uses `const _mockRecordedRanges` |
| `account/active_sessions_screen.dart` | Session list | ❌ | — | Static mock, own doc admits it |
| `account/users_invites_screen.dart` | Users/invites list | ❌ | — | Static mock, local `HomesController` only |
| `account/create_user_screen.dart` | Create-user form | ❌ | — | Local state only |
| `account/invite_user_screen.dart` | Invite form | ❌ | — | Local state only |
| `account/camera_access_screen.dart` | Access-scope editor | ❌ | — | Local state only |
| `alerts/alert_detail_screen.dart` | Clip/video playback | ❌ | — | Snapshot-only by design, no clip API |
| `events/event_detail_screen.dart` | Clip/video playback | ❌ | — | Thumbnail-only by design, no clip API |
| `events/events_summary_screen.dart` | Per-day activity chart | ❌ | — | Own doc: "Mock/local data only" |
| `camera_settings/video_stream_encoder_screen.dart` | Resolution tokens, encoder get/set | ✅ (re-verified) | `API_REFERENCE.md` (`OnvifVideoEncoderClient.getProfiles`, `kMediumResVideoEncoderToken`/`kLowResVideoEncoderToken`) | Confirmed real calls, not stale ⚠️ |
| `camera_settings/video_encoder_screen.dart` | Encoder settings | ✅ (re-verified) | same | Confirmed real calls |
| `camera_live/camera_live_screen.dart` | Stream Quality picker | ✅ (re-verified) | `LiveViewController.loadLanProfiles`/`setPreferredProfile` | Confirmed real calls, LIVE-059 |
| `camera_settings/person_detection_screen.dart` | Loitering duration, bbox overlay toggle | ✅ (re-verified, corrects stale doc) | `LoiteringDurationClient`/`WanLoiteringDurationClient`, `BboxOverlayClient`/`WanBboxOverlayClient` | `camera_api.md`'s "no matching UI yet" note is now outdated |
| `camera_settings/camera_info_screen.dart` | Health section | ✅ (re-verified, corrects stale doc) | `HealthClient`/`WanHealthClient` via `camera_sync.dart` | `camera_api.md`'s "mock data, no real API call" note is now outdated |

---

## Full Detail Table (Part B) — selected non-obvious entries

Most of the ~40 capabilities checked map 1:1 to the ✅ screens listed above (Day/Night Mode, WDR,
Image Quality/Defaults, Mirror/Flip, Anti-Flicker → `imaging_screen`; Privacy Mode/Masks →
`privacy_mode_screen`; OSD → `on_screen_display_screen`; Event Preferences/Response
Actions/Loitering/Bbox → `person_detection_screen`; Audio/Speaker Volume →`audio_screen`;
Snapshot/Preview, Cloud Streaming, WebRTC live-view URI, Deterrence manual trigger → wired inside
`camera_live_screen.dart`/`multiview_screen.dart` via `camera_sync.dart`/direct client calls;
WiFi → `wifi_config_screen`; Local Storage (LAN) → `storage_screen`; Recordings (LAN, clip listing
via `RecordingsClient.getRecordings()`/gallery-save via `.downloadClip()`, live playback via
`OnvifReplayControlClient.getReplayUri()` + `RtspRemuxProxy` — corrected 2026-09-15, see the
correction note above) → `camera_live_screen.dart`'s Playback tab; Device Identity/Info/Reboot/
Factory Reset → `camera_info_screen.dart`/`danger_zone_screen.dart`). The exceptions are listed in
the 🆕 table above.

---

## Method note on this run

This audit combined: (1) a full file listing of `docs/client_code/*.md`,
`packages/camera_api/API_REFERENCE.md`, and `SETTINGS_API_GUIDE.md` section headers to build the
capability inventory; (2) targeted `grep` of every client class name across `lib/screens/**` (and
`lib/app_state/**` where a screen delegates to a controller, e.g. `LiveViewController`,
`camera_sync.dart`, `HomesController`) to confirm real call sites vs. mentions in comments; (3) a
repo-wide marker scan (`TODO|FIXME|mock|dummy|placeholder|fake`) across `lib/screens/**` with each
hit manually read in context to filter out false positives (the great majority were
`.toDouble()`/`.toStringAsFixed()` matches on "double"). Two claims from the prior report/doc
comments were found stale and corrected here: `LoiteringDurationClient`/`BboxOverlayClient` and
`HealthClient`/`WanHealthClient` are now wired, not gaps.

**2026-09-15 refresh method note:** re-read `API_REFERENCE.md`/`SETTINGS_API_GUIDE.md` in full
against the current package (post-replacement from the `nuraeye-rt` reference app) to rebuild the
capability inventory, then re-ran the same class-name/method-name `grep` approach across
`lib/screens/**` and `lib/app_state/**` for every non-plumbing capability, reading each hit's
surrounding code (not just the grep line) to confirm a real call vs. a doc-comment mention —
this is what caught `OnvifReplayControlClient`'s real call site at
`camera_live_screen.dart:3357` (`_replayControl.getReplayUri(...)`), missed by the prior pass.
Also read `rest_health_client.dart` and `storage_screen.dart`/`camera_info_screen.dart` in full
to resolve the two previously-"unconfirmed" 🆕 entries definitively rather than re-flagging them.
Part A, Quick Wins, and Blocked were spot-checked but not re-audited line-by-line this pass — no
staleness found in the spot checks, so left as-is per the task scope.
