# camera_api — Live View Streaming Guide (WebRTC/RTSP LAN + KVS WAN)

This file explains how to implement live-view playback end-to-end, on both transports. It exists
because `API_REFERENCE.md` documents `camera_api`'s clients one class at a time (what each
method does), and `SETTINGS_API_GUIDE.md`'s "Cloud Streaming" entry is a one-paragraph pointer —
neither walks through the actual multi-step sequence, the wire formats a from-scratch
implementation needs, or the failure modes a robust client has to anticipate. This guide does
that, for a team implementing its own live-view session/reconnect logic on top of the existing
`camera_api` clients — the same way this app's own `LiveViewController`/`LiveViewScreen`
(`mobile_app/lib/features/live_view/`) do, rather than a working implementation handed to you.
Those two files are non-`flutter_webrtc`-package code specifically because `camera_api` is
pure-Dart with no `package:flutter` import — session-level WebRTC/video-player orchestration is
intentionally left as app-level business logic, not something this package provides.

## 1. Two transports, one decision rule (LAN itself has two sub-transports)

| | LAN — WebRTC | LAN — RTSP fallback | WAN (KVS) |
|---|---|---|---|
| When | Phone and camera on the same network, camera build has `WEBRTC_STREAMING` | Same network, but `WEBRTC_STREAMING` disabled camera-side (current default) | Phone away from home, or LAN unreachable |
| Latency | Sub-second (real-time peer connection) | Low (local remux, no cloud round trip) but not peer-to-peer real-time | Several seconds (HLS segment buffering) |
| Mechanism | Direct signaling to the camera, then a peer-to-peer media stream | Real RTSP session, remuxed to fMP4 over a local HTTP loopback for `video_player` (§2.5) | Camera pushes to AWS Kinesis Video Streams; phone pulls an HLS URL from AWS |
| Audio | Playback only (downlink) | Playback only (downlink) | Playback only (downlink) |

Two-way talk is **not** part of any of these transports — it is a separate, dedicated audio-only
RTSPS connection on its own port, described in [TWO_WAY_TALK_GUIDE.md](TWO_WAY_TALK_GUIDE.md). It
works on LAN only (`FR-NE-081` WAN relay is `Planned`).

Which of the two LAN sub-transports you get is **decided by the camera, not the app** —
`GetLiveStreamUri`'s `output.transport` field says which one (§2.1). The app never chooses.

**Which to use is decided by real connectivity, never by comparing IP addresses or guessing from
network type.** Try LAN first; only fall back to WAN after a genuine LAN reachability failure
(§2's discovery call actually failing, confirmed by an independent reachability probe, not just a
slow response). Comparing the phone's current IP against a saved camera IP is fragile — VPNs,
mobile hotspots, guest WiFi VLANs, or a camera whose LAN IP simply changed since onboarding all
give a wrong answer.

**Capability-gate WAN before attempting it at all.** The camera reports `wanLiveViewCapable` via
`GetCapabilities` at onboarding time (`FR-NE-092`) — cache it, and skip the entire WAN sequence
(no Lambda/KVS calls at all) for a camera known not to support it, going straight to an explicit
"this camera doesn't support remote viewing" state instead of a wasted round trip ending in a raw
error. Treat an unknown/uncached value as capable (fail open) rather than blocking WAN for an
already-onboarded camera.

## 2. LAN path — WebRTC signaling, or RTSP fallback

**2026-09-07: the camera itself now picks the LAN transport** — WebRTC when its firmware build
has `WEBRTC_STREAMING` compiled in, RTSP(S) otherwise (the current default: `WEBRTC_STREAMING`
was disabled camera-side, module kept intact, not removed). This supersedes this guide's earlier
"RTSP is reserved for VMS/NVR, WebRTC is the LAN mobile path" framing (root `CLAUDE.md`'s Stream
consumer mapping) — that conclusion no longer holds, since a build with `WEBRTC_STREAMING` off
has no other LAN transport, and this app now actually plays that RTSP stream too (§2.3).

### 2.1 Discovery

There is no discovery mechanism built into the signaling socket (or the RTSP listener) itself —
resolve the live-view target first via the NuraEye REST endpoint `POST /nuraeye/live-stream-uri`
(`camera_api`'s `LiveStreamUriClient.getLiveStreamUri`, `FR-NE-127` — **replaces this guide's
former separate `GetWebRtcUri`, `FR-NE-090`**, merged into this one endpoint the same day):

```
Request:  POST /nuraeye/live-stream-uri  {"profile_token": "Profile_3"}
Response (WebRTC): {"error_code": 0, "error_msg": "Success",
           "output": {"transport": "webrtc", "port": <n>, "path": "/webrtc",
                      "url": "http://<camera-ip>:<port>/webrtc"}}
Response (RTSP):    {"error_code": 0, "error_msg": "Success",
           "output": {"transport": "rtsp", "port": <n>, "path": "/high"|"/medium"|"/low",
                      "url": "rtsps://<camera-ip>:<port><path>"}}
```

`profile_token` is `Profile_1`/`Profile_2`/`Profile_3` (Stream 0/1/2, high/medium/low — all three
are ordinary ONVIF profiles, reachable via `GetStreamUri` too, `FR-CF-010`). This call, and both
transports it can resolve, are **LAN-only by design** — there is no WAN counterpart and there
never will be one for either.

**This app's own live view defaults to `Profile_3` and only auto-adjusts within one session
manually** — background: a real bug (2026-09-08) once shipped a bare `'Profile_1'` string literal
as the default, so live view requested the NVR/VMS-facing main stream instead of the stream built
for this app. Fixed by introducing named constants (`kMobileOnlyStreamProfileToken` etc.,
`live_stream_uri_client.dart`) so the choice is self-documenting at every call site, and by
disabling `LiveViewController`'s FR-MOB-037 LAN-trouble-detection profile ladder (§10.8) for the
Live tab's default session — that automatic ladder must never silently step a session from
`Profile_3` to `Profile_1`/`Profile_2` (or back) on its own, since a background quality change the
user didn't ask for is confusing regardless of direction.

**Superseded 2026-09-11**: this does *not* mean live view is permanently pinned to `Profile_3` —
`OnvifVideoEncoderClient.getProfiles()` (Media2 `GetProfiles`) now lets a caller discover every
profile the camera actually has configured (token/name/resolution), and the Stream Quality picker
(camera_live_screen.dart's LIVE-058/059) calls `LiveViewController.setPreferredProfile(token)` to
request a *user-chosen* profile directly — a deliberate, explicit switch, not the old automatic
ladder. `Profile_1`/`Profile_2` are legitimate choices for a user who explicitly picks "High"/etc.;
what's still forbidden is the *automatic*, un-requested ladder ever moving the Live tab's default
session off whatever profile the user (or the initial default) selected.

Branch on `output.transport`, not on any assumption about which one you'll get:
- `"webrtc"`: `url` is **plain `http://`, not `https://`** — the signaling socket is
  unauthenticated and unencrypted by firmware design. This is acceptable because it never leaves
  the LAN. Continue with §2.2 below.
- `"rtsp"`: `url` is an RTSPS stream URL (RTSP-level Digest auth applies, same credentials as
  `/nuraeye`/`/onvif`). See §2.5.

### 2.2 Offer/answer

`POST` to the resolved URL (i.e. `POST /webrtc` on the camera) with:

```json
{"type": "offer", "sdp": "<your SDP offer>"}
```

- On success: `HTTP 200`, `Content-Type: application/json`, body `{"type": "answer", "sdp":
  "<answer SDP>"}` — negotiate this as your `RTCPeerConnection`'s remote description exactly as
  you would any other WebRTC answer.
- **No STUN/TURN — host candidates only.** This is a same-LAN connection; don't configure ICE
  servers expecting them to be used.

To end a session explicitly, `POST /webrtc/stop` (no body) — `HTTP 200` on success, tears down
the peer connection immediately camera-side.

### 2.3 The one-peer-connection-per-signaling-port constraint — read this before building anything else

**The camera supports exactly one `RTCPeerConnection` per signaling port.** Every accepted
`POST /webrtc` offer tears down whatever connection currently exists on that port first, no
exceptions — "Check if a connection was already established; if so, tear it down and rebuild a
new one" is literally what the firmware does on every offer (this is deliberate, to support rapid
start/stop/start reconnect attempts from a client).

**Practical consequence: never open a second, independent connection to the same signaling port
for a second purpose while a live-view connection is already open.** Doing so silently kills the
first connection the moment the second offer is accepted — this app's original two-way-talk
feature hit exactly this bug (talk opened a second connection, the two evicted each other in a
loop). Any future multi-purpose WebRTC feature must **renegotiate the existing connection** (fresh
offer, changed transceiver, same signaling exchange), never open a second one. (Two-way talk no
longer uses WebRTC at all — it has its own dedicated RTSPS connection, see
[TWO_WAY_TALK_GUIDE.md](TWO_WAY_TALK_GUIDE.md).)

### 2.4 Reconnect and health

- No push signal exists for "the camera closed the connection" beyond your own peer connection's
  `connectionState`/ICE state changes — watch those directly.
- With no STUN/TURN, a momentary ICE `disconnected` state is normal and routinely self-recovers
  within a few seconds (WebRTC's own periodic consent-freshness check causes this on an otherwise
  healthy LAN connection). **Don't tear down and reconnect on the first `disconnected` blip** —
  give it a grace window (a few seconds) to recover to `connected`/`completed` before treating it
  as a real drop. Ending the session on the first blip is a real bug this app hit and fixed.
- A genuinely dropped/failed connection should trigger a fresh `POST /webrtc` offer — this both
  re-establishes the connection and (per §2.3) cleanly replaces whatever stale connection state
  might be left camera-side, so a plain retry is the correct recovery, not something requiring
  special-casing.

### 2.5 RTSP fallback (`transport: "rtsp"`)

New 2026-09-07, added when the camera itself has no other LAN transport
(`WEBRTC_STREAMING` disabled camera-side). The RTSP(S) listener speaks a real RTSP/1.0 protocol
(`OPTIONS`/`DESCRIBE`/`SETUP`/`PLAY`/`TEARDOWN`, TCP-interleaved RTP, RFC 2617 Digest auth) — not
directly consumable by `video_player`/ExoPlayer/AVPlayer, so this app doesn't speak RTSP straight
to the player. Instead:

1. `RtspLiveViewSession` (`mobile_app/lib/features/live_view/rtsp/rtsp_live_view_session.dart`)
   is a real RTSP client — `DESCRIBE`+`SETUP`+`PLAY` against the resolved `url`, then depacketizes
   H.264 (RFC 6184 single-NAL/FU-A) and, if present, AAC (RFC 3640 AAC-hbr) off the interleaved
   RTP stream. **Adapted from** the pre-existing recorded-clip playback client
   (`../recordings/rtsp/rtsp_replay_client.dart`'s `RtspReplaySession`, itself the reason this
   app doesn't use `media_kit`/libmpv at all — see that file's own doc for the ten-iteration
   real-hardware history) — same protocol engine, with clip-specific concepts (seek, a bound
   clip's start/end epoch) dropped, since live view has neither.
2. `RtspLiveViewProxy` (`rtsp_live_view_proxy.dart`, adapted from `rtsp_remux_proxy.dart`) remuxes
   what that session reads into fragmented MP4 (`fmp4_muxer.dart`, reused unchanged — its
   `totalDurationSeconds: null` is exactly the "unbounded live content" signal ExoPlayer needs)
   and serves it over a local HTTP loopback server (`http://127.0.0.1:<port>/live.mp4`).
3. `LiveViewScreen` points `VideoPlayerController.networkUrl()` at that loopback URL — from there
   it's rendered, muted, and snapshotted through the exact same code path the WAN (KVS HLS)
   transport already uses (both are just "a `video_player` session fed by a local/remote URI").

No seek, no pause/resume at the RTSP level (the camera's live-view RTSPS listener has no `PAUSE`
method — same limitation `../recordings/rtsp/rtsp_remux_proxy.dart`'s own doc describes for clip
playback). A dropped connection surfaces as the proxy's `isSessionEnded` going true (or a
`video_player` `hasError`) — reconnect by constructing a fresh `RtspLiveViewProxy` against a
freshly-resolved `getLiveStreamUri()` target, mirroring §2.4's WebRTC reconnect posture (a plain
retry, no special-casing).

## 3. WAN path — the four-step sequence

There is no single "connect" call — WAN live view is a sequence of independent steps, each with
its own failure modes. All four go through AWS IoT Core (MQTT command relay) and, for playback
resolution, a Lambda proxy — never a direct-from-app AWS SDK call (see §4 for why).

**`FR-CF-154` (2026-09-14): quality-selective, reference-counted, per-viewer leases.** Every KVS
stream (`high`/`medium`/`low`, one per `StreamQuality` value, named `<thing_name>-high`/
`-medium`/`-low` — the app must let the user pick which tier to watch, mirroring the LAN
RTSPS `/high`/`/medium`/`/low` picker) is a real, independently-billed AWS resource. The camera
never starts more than the requested tier, reference-counts concurrent viewers of the same tier
so they share one AWS session, and issues each `StartCloudStreaming` caller its own lease
**token** — `camera_api`'s `WanLiveViewClient` interface reflects this shape directly (see below);
there is no fire-and-forget "just start it" call anymore.

### Step 1 — `StartCloudStreaming(quality)`

Request/response MQTT command (`WanLiveViewClient.startCloudStreaming(StreamQuality quality)`,
`params.quality` = `"high"`/`"medium"`/`"low"`). Tells the camera to begin pushing that one
quality tier to its configured KVS channel (or, if another viewer already has it running, just
increments the camera-side reference count — no new AWS session). Returns the viewer's lease
**token** (an `int`) on success — keep it, every later call for this session needs it. This call
succeeding only means the command was delivered — it does not mean video is flowing yet (see §4
on why `stream_status: active` isn't sufficient evidence either).

### Step 2 — `GetCloudStreamingStatus(token)`, with retry — also the heartbeat

Request/response MQTT command (`getCloudStreamingStatus(token)`) returning one of:

| Value | Meaning |
|---|---|
| `active` | Camera believes it is currently pushing frames for this viewer's tier. **Does not guarantee AWS is accepting them** — see §4. |
| `idle` | Not streaming, no known failure — the normal resting state before any client requests it. Also a **normal transient state immediately after `StartCloudStreaming`** while the substream spins up — retry a couple of times before treating this as a real problem. |
| `degraded` | Not streaming, and the last 3+ consecutive connection attempts failed. |
| `notCompiled` | This firmware build doesn't have KVS support compiled in at all — don't retry, there's nothing to wait for. |

**This call is also the lease heartbeat.** Passing `token` refreshes the camera-side lease for
that viewer; a token not refreshed within **30 seconds** is dropped automatically
(`bsp_camera_pollKvsViewerLeases()`, firmware-side), and once the last viewer's reference drops,
the camera tears the AWS session down to stop paying for it. Call this **at least every 30s**
for the lifetime of the session, not just once at connect time — this app's own periodic WAN
health poll (`LiveViewController._checkWanHealth`, default every 10s) does this for free, since
its existing health check already calls `getCloudStreamingStatus` on that cadence.

### Step 3 — `resolvePlaybackUri(quality)` (via the Lambda relay)

Once `active`, resolve a playable URL (`resolvePlaybackUri(quality)`, backed by
`KvsPlaybackClient` → the deployed `cloud_backend/kvs_playback_lambda` Function URL, which calls
AWS KVS's `GetDataEndpoint`/`GetHLSStreamingSessionURL` under its own execution role for the
`<thing_name>-<quality>` stream name — see §4). The returned HLS session URL is long-lived (12h,
`Expires=43200` server-side) — you do not need to re-resolve it for every reconnect within that
window, only when it's actually expired or invalid (see §5's caveat on when this assumption
breaks).

The substream can legitimately still be spinning up for a few seconds after `StartCloudStreaming`
reports `active` — retry `resolvePlaybackUri` a few times (e.g. 3 attempts, ~2s apart) before
treating a failure here as terminal, mirroring step 2's own retry posture.

### Step 4 — HLS playback

Play the resolved URL with any standard HLS-capable player (this app uses `video_player`, backed
by ExoPlayer/AVFoundation natively — no KVS SDK needed in the app at all, since the Lambda already
resolves everything down to a plain HLS URL).

### Ending the session

`stopCloudStreaming(token)` (fire-and-forget, same shape as the pre-`FR-CF-154` Stop) — available
on **both** transports: the WAN/MQTT command, and (added for exactly this reason) a LAN
`/nuraeye` action of the same name (`CloudStreamingLanClient.stopCloudStreaming()` — no token,
LAN's own action is the older blunt "stop every quality" behavior, unaffected by this rework). If
you've just confirmed the camera is reachable on LAN (e.g. switching back from WAN because the
phone came back onto the home network), prefer the LAN stop call — it avoids an unnecessary
AWS/Lambda round trip for a camera you can already reach directly. Fall back to the WAN stop only
if the LAN attempt itself fails.

**Send `stopCloudStreaming(token)` even if your session never fully reached "playing."** A real
bug found in this app: if `startCloudStreaming()` succeeds but the session is torn down before
playback resolution completes (steps 2-3 still in flight), the camera has *already* incremented
its reference count for this viewer. Skipping the stop call in that window leaves the lease to
expire on its own via the 30s heartbeat timeout rather than releasing it immediately — track "did
I get a token back from Start" as a fact independent of whatever UI/connection state your app
happens to be in, and always pair it with a Stop using that same token.

### Switching quality tier mid-session

There is no "change quality" command — switching tiers means stopping the current lease
(`stopCloudStreaming(oldToken)`) and starting a fresh one on the new quality
(`startCloudStreaming(newQuality)` → new token), same as a reconnect. See
`LiveViewController.setWanQuality` for the reference implementation (tears down the old lease,
re-runs the connect sequence above on the new tier).

## 4. What `stream_status` does and doesn't tell you

`GetCloudStreamingStatus`/`stream_status` is derived entirely from the camera's own view of its
publish loop — it does not observe AWS's fragment-acknowledgement responses at all. A real
incident (`BUG-023`, firmware-side) found `stream_status: active` reported continuously for over
30 seconds while **every single fragment was being silently rejected by AWS** — the firmware log
and the status query were both blind to it; the only way to get ground truth was checking AWS
directly:

```bash
ENDPOINT=$(aws kinesisvideo get-data-endpoint --stream-name <name> \
  --api-name LIST_FRAGMENTS --region <region> --query DataEndpoint --output text)
aws kinesis-video-archived-media list-fragments --stream-name <name> \
  --endpoint-url "$ENDPOINT" --region <region> \
  --fragment-selector '{"FragmentSelectorType":"PRODUCER_TIMESTAMP",
    "TimestampRange":{"StartTimestamp":"<start>","EndTimestamp":"<end>"}}' \
  --query 'length(Fragments)'
```

That specific defect is fixed camera-side now (see §6), but the underlying fact remains: **`active`
means "the producer believes it's pushing," not "video is actually landing."** If you're building
diagnostics or a "why isn't this working" support path, don't stop at `stream_status` — a stalled
player with `stream_status: active` and no picture is a real, distinct failure mode from a
`degraded` status, and needs different handling (the stream itself needs investigating, not just
"retry the connection").

## 5. Reconnect and failure semantics — read this before writing your recovery logic

Camera-visible trouble and phone-visible trouble are two different signals and need two different
watchers — there is no single live push signal for WAN the way LAN's ICE connection state is one:

1. **Camera-visible**: poll `GetCloudStreamingStatus` periodically while playing (this app uses a
   10s interval). A cheap LAN-reachability probe first, each tick, is worth doing before spending
   the paid AWS/Lambda call — if the phone has come back onto the camera's LAN, switch to the LAN
   path entirely rather than continuing to poll WAN. On `degraded`/`idle`/a failed status call,
   re-resolve playback (§3 step 3) before falling back to a full restart from step 1.
2. **Phone-visible**: watch your player's own error/stall signals (e.g. `hasError`, or a
   position-progress poll to catch "playing but frozen," which `hasError` alone won't catch).

**The open question your recovery logic needs to answer, that this app's own implementation does
not yet answer correctly: is a player-visible error/stall recoverable by reconnecting to the
*same* already-resolved HLS URL, or does it require re-resolving a fresh one (§3 step 3 again)?**

The "same URL is fine" assumption holds for a transient phone-side network/decoder hiccup — the
underlying KVS session hasn't changed, so reconnecting to the identical long-lived URL (§3 step 3)
recovers cleanly. It does **not** hold for a different, real scenario: **the camera can
legitimately stop the KVS stream outright mid-session** — this happens, among other triggers,
whenever a client toggles the camera's mic on/off while WAN streaming is active (see §6). This is
expected, correct camera-side behavior, not corruption — but from the app's perspective it looks
identical to a stall (playback freezes, or an HLS player may throw a hard platform-level
exception), and (since `FR-CF-154`, 2026-09-14) the camera does **not** bring the stream back on
its own — a fresh §3 sequence from Step 1 is required, not a same-URL reconnect. This app's
current recovery path (`live_view_screen.dart`'s `_recoverWanPlayback`) does not yet distinguish
a transient phone-side hiccup from a real camera-initiated stop — real-device testing (pre-dating
`FR-CF-154`, back when the camera still self-reconnected) found this required the user to
manually retry a few times before playback resumed. **This remains a known, unresolved gap** —
not a solved pattern to copy as-is. Recommend building in an explicit fallback: if a same-URL
reconnect fails its own retry budget, fall through to a fresh §3 sequence (re-check status,
re-`startCloudStreaming`, re-resolve a new URL) rather than giving up or looping the same stale
URL indefinitely — and prefer reacting to `CloudStreamStopped` (§6) over waiting to notice via a
failed reconnect at all.

## 6. The audio-track/mic-toggle interaction, and camera-initiated stops in general

`SetAudioRecording`/`GetAudioRecording` (`FR-NE-078`, `AudioVolumeClient`/`WanAudioVolumeClient`
in `camera_api`) toggles whether the camera is capturing microphone audio at all — the same
underlying camera state on both LAN and WAN transports ("one state, two transports"). **If cloud
streaming is currently active, toggling this forces the camera to immediately stop the affected
KVS stream(s)** so the stream's track composition (whether an audio track is declared at all)
never drifts out of sync with what's actually being fed to it (the failure this guards against,
found and fixed in `BUG-023`, was a stream stuck declaring an audio track nobody was feeding,
which AWS rejects outright). A stream resolution change (video re-init) stops any of that specific
tier's active stream the same way.

**`FR-CF-154` (2026-09-14): the camera no longer self-reconnects after either trigger** — it was
a self-managed `STOP`+`RECONNECT` before, adding complexity the camera doesn't need to carry;
now it's a plain stop, matching how a LAN RTSP client is simply disconnected and left to redial
itself. A WAN viewer whose stream was stopped this way must reconnect from Step 1
(`startCloudStreaming`) — same as any other WAN session start — not assume the camera will bring
it back. To reconnect promptly rather than waiting for the next `GetCloudStreamingStatus` poll to
notice, subscribe to the `CloudStreamStopped` alert-topic event (fired once per stop, cause-
agnostic — covers both the audio toggle and a resolution change) and treat it as a trigger to
restart the connect sequence immediately.

## 7. Client reference

Everything above is implemented by these existing `camera_api` classes — see `API_REFERENCE.md`
for exact method signatures:

| Purpose | Class |
|---|---|
| LAN live-view discovery (`GetLiveStreamUri` — resolves WebRTC or RTSP) | `LiveStreamUriClient` |
| LAN reachability probe | `LiveStreamUriClient.checkReachable` |
| LAN cloud-streaming status/stop | `CloudStreamingLanClient` |
| WAN command relay (low-level) | `IotCommandClient` |
| WAN KVS playback URL resolution | `KvsPlaybackClient` |
| WAN live-view session (quality-selective Start/Stop/Status/resolve, lease token, one interface) | `WanLiveViewClient` / `AwsWanLiveViewClient` |
| WAN audio-recording toggle | `WanAudioVolumeClient` |

None of these implement the offer/answer negotiation, the reconnect state machine, or the
transport-selection logic described above — that's the layer you build on top, same as this app's
own `LiveViewController`/`LiveViewScreen` do (not shipped as reusable `camera_api` code — see the
note at the top of this file for why).

## 8. Known limitations (as of 2026-09-14)

- **§5's reconnect gap** — same-URL-reconnect-only recovery doesn't distinguish a transient
  phone-side hiccup from a real camera-initiated stop, which (since `FR-CF-154`) needs a fresh
  Start, not a same-URL retry. Unresolved.
- `FR-CF-154`'s server-side pieces (quality-selective start/stop, reference counting, 30s lease
  timeout, `CloudStreamStopped` event) are build-verified firmware-side only — **not yet
  hardware-verified** as of this writing.
- No WAN talk (two-way audio) — see `TWO_WAY_TALK_GUIDE.md`.
- `stream_status: active` is not sufficient evidence of a healthy stream (§4) — no fix planned,
  this is inherent to what the status derivation observes; build your own diagnostics around it
  rather than expecting a firmware change.
- No resolution/bitrate telemetry exists for the WAN path (HLS gives no equivalent of WebRTC's
  `inbound-rtp` stats report) — if you need live quality metrics on WAN, you'll need to derive
  them from player-level buffering/stall signals rather than a byte-count-based bitrate the way
  LAN can.
