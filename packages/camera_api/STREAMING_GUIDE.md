# camera_api — Live View Streaming Guide (WebRTC LAN + KVS WAN)

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

## 1. Two transports, one decision rule

| | LAN (WebRTC) | WAN (KVS) |
|---|---|---|
| When | Phone and camera on the same network | Phone away from home, or LAN unreachable |
| Latency | Sub-second (real-time peer connection) | Several seconds (HLS segment buffering) |
| Mechanism | Direct signaling to the camera, then a peer-to-peer media stream | Camera pushes to AWS Kinesis Video Streams; phone pulls an HLS URL from AWS |
| Audio | Bidirectional-capable (two-way talk reuses this connection) | Playback only — no talk over WAN today (`FR-NE-081` is `Planned`) |

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

## 2. LAN path — WebRTC signaling

### 2.1 Discovery

There is no discovery mechanism built into the signaling socket itself — resolve it first via
the NuraEye JSON action `GetWebRtcUri` (`camera_api`'s `WebRtcUriClient.getWebRtcUri`,
`FR-NE-090`):

```
Request:  {"action": "GetWebRtcUri", "params": {"profile_token": "Profile_1"}}
Response: {"error_code": 0, "error_msg": "Success",
           "output": {"port": <n>, "url": "http://<camera-ip>:<port>/webrtc"}}
```

`profile_token` is `Profile_1`/`Profile_2`/`Profile_3` (Stream 0/1/2). This call, and the
signaling socket it resolves, are **LAN-only by design** — there is no WAN counterpart and there
never will be one, since the signaling socket has no WAN reachability regardless (see root
`CLAUDE.md`'s Stream consumer mapping: RTSP is reserved for VMS/NVR, WebRTC is the LAN mobile
path).

The resolved URL is **plain `http://`, not `https://`** — the signaling socket is unauthenticated
and unencrypted by firmware design. This is acceptable because it never leaves the LAN.

### 2.2 Offer/answer

`POST` to the resolved URL (i.e. `POST /webrtc` on the camera) with:

```json
{"type": "offer", "sdp": "<your SDP offer>", "talk": false}
```

- `talk` is optional; omit it or set `false` for live-view-only. See §5 for the talk case.
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

**Practical consequence: never open a second, independent connection for a second purpose (e.g.
two-way talk) while a live-view connection is already open on the same port.** Doing so will
silently kill the first connection the moment the second offer is accepted — this app's own
two-way-talk feature hit exactly this bug during development (talk opened a second connection,
assumed it could coexist with live view, and the two connections evicted each other in a loop:
starting talk killed live view, live view's own reconnect-on-drop logic then killed talk). The
fix, and the pattern to follow for any future multi-purpose WebRTC feature on this camera: **renegotiate the existing connection** — send a fresh offer with a changed transceiver/`talk` flag
over the *same* signaling exchange, never open a second connection to the same port. See §5 for
how two-way talk does this.

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

## 3. WAN path — the four-step sequence

There is no single "connect" call — WAN live view is a sequence of independent steps, each with
its own failure modes. All four go through AWS IoT Core (MQTT command relay) and, for playback
resolution, a Lambda proxy — never a direct-from-app AWS SDK call (see §4 for why).

### Step 1 — `StartCloudStreaming`

Fire-and-forget MQTT command (`camera_api`: `WanLiveViewClient.startCloudStreaming()`). Tells the
camera to begin pushing Stream 1 (the low-resolution substream) to its configured KVS channel.
This call succeeding only means the command was delivered — it does not mean video is flowing
yet (see §4 on why `stream_status: active` isn't sufficient evidence either).

### Step 2 — `GetCloudStreamingStatus`, with retry

Request/response MQTT command (`getCloudStreamingStatus()`) returning one of:

| Value | Meaning |
|---|---|
| `active` | Camera believes it is currently pushing frames. **Does not guarantee AWS is accepting them** — see §4. |
| `idle` | Not streaming, no known failure — the normal resting state before any client requests it. Also a **normal transient state immediately after `StartCloudStreaming`** while the substream spins up — retry a couple of times before treating this as a real problem. |
| `degraded` | Not streaming, and the last 3+ consecutive connection attempts failed. |
| `notCompiled` | This firmware build doesn't have KVS support compiled in at all — don't retry, there's nothing to wait for. |

### Step 3 — `resolvePlaybackUri` (via the Lambda relay)

Once `active`, resolve a playable URL (`resolvePlaybackUri()`, backed by `KvsPlaybackClient` →
the deployed `cloud_backend/kvs_playback_lambda` Function URL, which calls AWS KVS's
`GetDataEndpoint`/`GetHLSStreamingSessionURL` under its own execution role — see §4). The
returned HLS session URL is long-lived (12h, `Expires=43200` server-side) — you do not need to
re-resolve it for every reconnect within that window, only when it's actually expired or invalid
(see §5's caveat on when this assumption breaks).

The substream can legitimately still be spinning up for a few seconds after `StartCloudStreaming`
reports `active` — retry `resolvePlaybackUri` a few times (e.g. 3 attempts, ~2s apart) before
treating a failure here as terminal, mirroring step 2's own retry posture.

### Step 4 — HLS playback

Play the resolved URL with any standard HLS-capable player (this app uses `video_player`, backed
by ExoPlayer/AVFoundation natively — no KVS SDK needed in the app at all, since the Lambda already
resolves everything down to a plain HLS URL).

### Ending the session

`StopCloudStreaming` (fire-and-forget, same shape as Start) — available on **both** transports:
the WAN/MQTT command, and (added for exactly this reason) a LAN `/nuraeye` action of the same
name (`CloudStreamingLanClient.stopCloudStreaming()`). If you've just confirmed the camera is
reachable on LAN (e.g. switching back from WAN because the phone came back onto the home network),
prefer the LAN stop call — it avoids an unnecessary AWS/Lambda round trip for a camera you can
already reach directly. Fall back to the WAN stop only if the LAN attempt itself fails.

**Send `StopCloudStreaming` even if your session never fully reached "playing."** A real bug
found in this app: if `startCloudStreaming()` succeeds but the session is torn down before
playback resolution completes (steps 2-3 still in flight), the camera has *already* started
publishing — skipping the stop call in that window left it publishing to KVS indefinitely with no
viewer. Track "did I send Start" as a fact independent of whatever UI/connection state your app
happens to be in, and always pair it with a Stop.

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
recovers cleanly. It does **not** reliably hold for a different, real scenario: **the camera can
legitimately restart its own KVS producer mid-session** — this happens, among other triggers,
whenever a client toggles the camera's mic on/off while WAN streaming is active (see §7), since
the KVS producer needs to rebuild its stream to reflect the new audio-track composition. This is
expected, correct camera-side behavior, not corruption — but from the app's perspective it looks
identical to a stall (playback freezes, or an HLS player may throw a hard platform-level
exception), and the underlying PUT MEDIA session genuinely changed underneath the already-issued
HLS URL. This app's current recovery path (`live_view_screen.dart`'s `_recoverWanPlayback`)
assumes the same-URL case always applies and does not yet distinguish the two — real-device
testing found this requires the user to manually retry a few times before playback resumes after
a producer restart, rather than the app recovering on its own within its normal retry budget.
**This is a known, unresolved gap as of 2026-08-13** — not a solved pattern to copy as-is.
Recommend building in an explicit fallback: if a same-URL reconnect fails its own retry budget,
fall through to a fresh §3 sequence (re-check status, re-resolve a new URL) rather than giving up
or looping the same stale URL indefinitely.

## 6. The audio-track/mic-toggle interaction

`SetAudioRecording`/`GetAudioRecording` (`FR-NE-078`, `AudioVolumeClient`/`WanAudioVolumeClient`
in `camera_api`) toggles whether the camera is capturing microphone audio at all — the same
underlying camera state on both LAN and WAN transports ("one state, two transports"). **If cloud
streaming is currently active, toggling this forces the camera to immediately restart its KVS
producer** so the stream's track composition (whether an audio track is declared at all) stays
consistent with what's actually being fed to it — this is deliberate and correct (the alternative,
found and fixed in `BUG-023`, was a stream stuck declaring an audio track nobody was feeding,
which AWS rejects outright). A WAN viewer should expect a brief playback interruption/reconnect
as a normal consequence of anyone toggling this setting — camera-app, another mobile client, or
this one — not treat it as an error to surface to the user beyond the usual "reconnecting"
indicator. See §5 for the current, unresolved gap in how reliably playback actually resumes
afterward.

## 7. Client reference

Everything above is implemented by these existing `camera_api` classes — see `API_REFERENCE.md`
for exact method signatures:

| Purpose | Class |
|---|---|
| LAN signaling discovery (`GetWebRtcUri`) | `WebRtcUriClient` |
| LAN reachability probe | `WebRtcUriClient.checkReachable` |
| LAN cloud-streaming status/stop | `CloudStreamingLanClient` |
| WAN command relay (low-level) | `IotCommandClient` |
| WAN KVS playback URL resolution | `KvsPlaybackClient` |
| WAN live-view session (Start/Stop/Status/resolve, one interface) | `WanLiveViewClient` / `AwsWanLiveViewClient` |
| WAN audio-recording toggle | `WanAudioVolumeClient` |

None of these implement the offer/answer negotiation, the reconnect state machine, or the
transport-selection logic described above — that's the layer you build on top, same as this app's
own `LiveViewController`/`LiveViewScreen` do (not shipped as reusable `camera_api` code — see the
note at the top of this file for why).

## 8. Known limitations (as of 2026-08-13)

- **§5's reconnect gap** — same-URL-reconnect-only recovery doesn't reliably handle a
  camera-initiated KVS producer restart. Unresolved.
- No WAN talk (two-way audio) — see `TWO_WAY_TALK_GUIDE.md`.
- `stream_status: active` is not sufficient evidence of a healthy stream (§4) — no fix planned,
  this is inherent to what the status derivation observes; build your own diagnostics around it
  rather than expecting a firmware change.
- No resolution/bitrate telemetry exists for the WAN path (HLS gives no equivalent of WebRTC's
  `inbound-rtp` stats report) — if you need live quality metrics on WAN, you'll need to derive
  them from player-level buffering/stall signals rather than a byte-count-based bitrate the way
  LAN can.
