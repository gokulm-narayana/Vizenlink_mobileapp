# camera_api — Two-Way Talk Guide (WebRTC)

Companion to [STREAMING_GUIDE.md](STREAMING_GUIDE.md) — read that first, since two-way talk
reuses live view's own signaling endpoint and connection, not a separate mechanism. This file
covers what's different: the session-exclusivity model, the renegotiate-don't-reopen constraint,
and the call-style UX contract a talk implementation needs.

## 1. Concept and scope

Two-way talk streams the phone's microphone audio to the camera's speaker in near-real-time —
the camera's mic capture activates for the *return* audio leg (hearing the camera's side)
regardless of the current audio-recording toggle state (`FR-CF-024`/`STREAMING_GUIDE.md` §6),
and restores whatever that toggle's prior state was once the talk session ends. Acoustic echo
cancellation is applied automatically camera-side for the session's duration — no client-facing
control needed for it.

**LAN-only today.** There is no WAN leg — `FR-NE-081` ("Two-Way Talk WAN Relay") is `Status:
Planned`, needs a new AWS KVS Signaling Channel (a genuinely different mechanism from WAN live
view's Archived-Media/HLS path described in `STREAMING_GUIDE.md`, not a small extension of it) —
not built. Gate the talk control on LAN connectivity the same way any LAN-only control would be.

**Permission-gated** — access-control checks are defined in `design/FR-access-control.md`; if
your app has a role/permission system, wire the talk entry point through it the same way any
other privileged action would be.

## 2. Session model — renegotiate the existing connection, never open a second one

This is the single most important constraint in this document, and getting it wrong reproduces a
real, already-diagnosed bug. From `STREAMING_GUIDE.md` §2.3: **the camera supports exactly one
`RTCPeerConnection` per signaling port** — every accepted `POST /webrtc` offer tears down
whatever connection currently exists on that port and rebuilds it.

If your talk implementation opens a **second**, independent `RTCPeerConnection` to add talk audio
— assuming it can coexist alongside an already-open live-view connection — it cannot. The two
connections will evict each other in a loop: starting talk kills live view (talk's offer tears
down live view's connection per the rule above), live view's own reconnect-on-drop logic then
sends a fresh offer and kills talk the same way, repeating indefinitely. This happened during
this app's own development and was root-caused to exactly this mistake.

**The correct model: renegotiate the single existing peer connection.** Send a fresh
`POST /webrtc` offer over the *same* signaling exchange, with `{"talk": true}` set and your SDP
offer updated to add/enable the audio-send transceiver talk needs, rather than establishing an
independent connection. The camera's answer negotiates against your existing connection's new
state, not a second one.

## 3. Signaling

Same endpoint as live view (`STREAMING_GUIDE.md` §2.2): `POST /webrtc` on the resolved signaling
URL, body `{"type": "offer", "sdp": "<offer>", "talk": true}`. Everything about the offer/answer
wire format, `http://` (not `https://`), and no-STUN/TURN in that section applies unchanged here
— `talk: true` is the only difference from a plain live-view offer.

`POST /webrtc/stop` (no body) ends the session — releases the talk-session slot camera-side
*and* tears down the connection, same as a plain live-view stop.

## 4. Exclusivity — HTTP 409

Only one talk session may transmit through the camera's speaker at a time (`FR-CF-131`). If a
`{"talk": true}` offer arrives while another talk session is already active:

- The camera responds `HTTP 409 Conflict`, `Content-Length: 0`, empty body.
- **The existing session is left completely untouched** — this is a pure rejection, not an
  eviction. (An earlier firmware version got this backwards — a second request silently evicted
  the first session instead of being rejected; fixed and hardware-verified under repeated
  cycling, `FR-CF-131`.)
- Your app has no way to know *when* the resource frees up other than trying again — there is no
  push notification for "the other session ended." Model this as a **reactive** indicator (retry
  or let the user retry, show "in use" state) rather than attempting to poll for availability.

A `409` is a normal, expected response your client must handle explicitly — not an error to
surface as a generic failure. Distinguish it from every other failure mode in your UI (see §5).

## 5. Call-style UX contract

Talk is a live, real-time session the user actively participates in — treat it with the same UX
discipline any call-style feature needs, not as a settings toggle:

1. **Open the presentation before the session connects, not after.** Own a
   `connecting → talking → (busy | error)` state machine and perform the connect call from
   within it, so a slow or failing connection is visibly "Calling…" rather than nothing
   happening until success or failure. Give `busy` (the `409` case) a visually distinct
   treatment from a hard error — they mean different things to the user (someone else is using
   it vs. something is actually broken).
2. **Route-to-loudspeaker, defaulted on.** Two-way audio needs a way to make the far side louder
   without the user reaching for hardware volume buttons — expose a speakerphone toggle
   (`flutter_webrtc`'s `Helper.setSpeakerphoneOn` if you're on that plugin), defaulted **on**. A
   quiet earpiece-routed default reproduces a real "too quiet" complaint this app hit on first
   build.
3. **A grace window before treating a transient ICE `disconnected` as a real drop** — same
   guidance as `STREAMING_GUIDE.md` §2.4, worth restating here because a talk session is
   short-lived and a user is actively waiting, so ending it prematurely on a momentary blip is
   more noticeable than the same mistake on a passive live-view session.
4. **Every exit path funnels through one teardown method** — an explicit End/Close action and the
   session dropping on its own (via your connection-state stream) should both go through the same
   teardown code, so there's no path that clears your UI without also sending `POST /webrtc/stop`
   and releasing the underlying session.
5. **In-call settings (e.g. volume) belong on the call's own UI, not the idle control.** Adjusting
   them is only ever relevant *during* the session — don't surface them when idle.
6. **A player-level mute, if your app has a separate "mute the camera's audio" control for plain
   live view, is a different concern from the talk session's own audio and needs a different
   control.** Talk's speakerphone toggle routes *outbound* call audio; a plain-playback mute (if
   you have one) mutes what you're *hearing* independent of any call — conflating the two into
   one control will surprise a user who mutes playback expecting it not to affect an active call,
   or vice versa.

## 6. Client reference

There is no dedicated `camera_api` class for the talk session itself — talk reuses the same
LAN signaling discovery (`WebRtcUriClient.getWebRtcUri`, `STREAMING_GUIDE.md` §2.1) as live view;
the `{"talk": true}` flag and the offer/answer exchange in §3 above are the only protocol
additions, implemented directly against your own `RTCPeerConnection`/WebRTC plugin the same way
you implement live view's own offer/answer (`camera_api` is pure-Dart with no `flutter_webrtc`
dependency, so this stays app-level code — see `STREAMING_GUIDE.md`'s opening note for why).

## 7. Known limitations (as of 2026-08-13)

- **No WAN leg** — LAN-only, per §1.
- **No role-based permission gating implemented in this app yet** — the access-control checks
  `design/FR-access-control.md` defines are a firmware-side concept; whether/how a mobile client
  enforces them client-side (vs. just handling the camera's own rejection) is not yet decided.
- **Return-audio-leg hardware risk — open, unresolved.** The leg carrying the camera's mic audio
  back to the phone has a real, firmware-side finding from hardware testing: the one test that
  specifically checked this leg found zero audio frames received. This was shipped anyway per
  explicit product decision (the outbound leg — phone mic to camera speaker — works and was the
  higher priority), flagged as a known gap rather than silently shipped, and remains a priority
  item for the next hardware test pass. If you're implementing your own talk client, do not
  assume the return-audio leg works without testing it yourself first.
