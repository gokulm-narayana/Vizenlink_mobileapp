# camera_api — Two-Way Talk Guide

Companion to [STREAMING_GUIDE.md](STREAMING_GUIDE.md). Two-way talk is a **separate, dedicated
connection** — not a mode of the live-view stream. It runs over the camera's audio-only RTSPS
talk module, discovered via its own REST endpoint, completely independent of whatever the
live-view screen is doing.

> **History:** talk used to ride the WebRTC live-view `RTCPeerConnection` with a `{"talk": true}`
> flag on the `POST /webrtc` offer, and briefly (never completed) a third RTP track bolted onto
> the live-view RTSP connection. Both were removed 2026-09-11 in favour of the dedicated module
> below. If you find `WebRtcTalkSessionBusyException`, `connect(url, talk: true)`, or
> `setupTalkUplink()` referenced anywhere, that's stale.

## 1. Concept and scope

Two-way talk streams the phone's microphone to the camera's speaker and plays the camera's
microphone back on the phone — full-duplex, AAC-LC 8000 Hz mono in both directions. The camera
force-activates its own mic capture for the return leg regardless of the audio-recording toggle
(`FR-CF-024`) and converges back to whatever that toggle says once talk ends; acoustic echo
cancellation is applied camera-side automatically.

**LAN-only.** There is no WAN leg — `FR-NE-081` ("Two-Way Talk WAN Relay") is `Status: Planned`.
Gate the talk control on LAN connectivity the same way any LAN-only control is gated. A future
WAN leg would be an additive `transport` value in the discovery response (§3), not a new
mechanism to special-case.

**Speaker-gated.** Offer the talk control only when the camera reports a speaker
(`AudioCapabilityClient.getAudioCapability().hasSpeaker`) — hide it entirely otherwise
(`FR-MOB-082`), don't show it disabled.

**Permission-gated (firmware concept).** `design/FR-access-control.md` defines who may talk; the
app has no role system yet (`Mobile-Android-1` not built), so today the control is shown
unconditionally and the app only handles the camera's own busy rejection (§4).

## 2. The dedicated talk module

`module_rtsps_talk.c` on the camera is a single-client **TLS-only** RTSP server on **port 560**.
It is `RECORD`-based (the client sends media, unlike live view's `PLAY`) and advertises exactly
two audio tracks:

| Track | SDP | Direction | Interleaved RTP channels |
|---|---|---|---|
| `streamid=0` | `a=sendonly` | camera mic → client | `0-1` |
| `streamid=1` | `a=recvonly` | client mic → camera | `2-3` |

Both are `MPEG4-GENERIC/8000`, AAC-hbr, payload type 97, `config=1588`. There is no in-band
`AudioSpecificConfig` — the 8000 Hz / mono / AAC-LC parameters must match the firmware exactly or
audio silently garbles.

RTP framing (both directions): a `$`-interleave marker + 1-byte channel + 2-byte length, then a
12-byte RTP header (marker bit set, PT 97, 16-bit sequence, timestamp = `seq * 1024`, arbitrary
SSRC), then a 4-byte RFC 3640 AU-header section (`00 10` = 16 AU-header bits, then
`auLen << 3`), then the raw AAC access unit.

## 3. Discovery — `POST /nuraeye/talk-uri`

`TalkUriClient.getTalkUri()` → `POST /nuraeye/talk-uri` (body ignored). Success:

```json
{
  "error_code": 0,
  "error_msg": "Success",
  "output": {
    "transport": "rtsps",
    "port": 560,
    "path": "/talk",
    "url": "rtsps://192.168.1.50:560/talk"
  }
}
```

`transport` is always `"rtsps"` (the module is TLS-only — there is no `rtsp://` form).
`400` means local-IP resolution failed, or the firmware was built without `AUDIO_ENABLED`
("Two-way talk unavailable on this build"). `TalkUriClient` surfaces both as `CameraFailure`.

Mirrors `LiveStreamUriClient.getLiveStreamUri`'s shape exactly (transport chosen server-side,
reported back) so a WAN leg slots in later without a client rewrite.

## 4. Session sequence and exclusivity

Open a TLS socket to `url`'s host/port and run:

```
OPTIONS                                    -> 200 (no auth)
DESCRIBE       Accept: application/sdp      -> 401 challenge -> retry with Digest -> 200
SETUP  <url>/streamid=0  Transport: RTP/AVP/TCP;unicast;interleaved=0-1  -> 200
SETUP  <url>/streamid=1  Transport: RTP/AVP/TCP;unicast;interleaved=2-3  -> 200
RECORD                                      -> 200   (both SETUPs required, else 455)
... bidirectional $-framed RTP ...
TEARDOWN                                    -> 200
```

RTSP-level **Digest** auth (RFC 2617): `realm="ONVIF"`, **no `qop`**, `algorithm=MD5`. The
`Authorization`/request-line URI is `rtsp://host:560/talk` (no `s`) — the same convention the
live-view/playback RTSP clients use; the camera's `rtsp_digest_verify()` trusts the
client-supplied string.

**Exclusivity (`FR-CF-131`):** only one talk session per camera. A second attempt is rejected at
**`RECORD`** with a non-200 status (`453` / `455` / `503`) — the existing session is left
untouched, this is a pure rejection, not an eviction. There is **no** push for "the slot freed
up"; model it as a reactive "someone else is currently talking" indicator, let the user retry.
(This replaced the WebRTC path's HTTP `409`.)

## 5. Return-audio playback

The downlink (`streamid=0`, camera mic) is raw AAC access units after RFC 3640 depacketization.
The reference app plays them by re-adding a 7-byte ADTS header per AU and serving a continuous
`audio/aac` stream over a `127.0.0.1` HTTP loopback to a hidden player — the same
loopback-to-native-player shape `RtspLiveViewProxy` uses for video, minus the fMP4 muxing. During
a call the app force-mutes the live-view video player and plays only this return audio, then
restores the player's prior mute state on teardown.

> ⚠️ **Unverified pending hardware.** Endless-ADTS-over-HTTP progressive playback works on
> ExoPlayer/AVPlayer in principle, but this exact path hasn't been checked on a device yet. If a
> platform player rejects the unbounded stream, wrap the AUs in an audio-only fragmented-MP4
> instead (a stripped `RtspFmp4Muxer` variant).

## 6. Call-style UX contract

Talk is a live session the user participates in — same discipline as any call-style feature (see
`.claude/rules/mobile-app-screen-conventions.md` § "Call-style screen UX conventions"):

1. **Open the presentation before connecting.** Own a `connecting → talking → (busy | error)`
   state machine and run the connect from inside it, so a slow/failed connect shows "Calling…"
   rather than nothing. Give `busy` (§4) a visually distinct treatment from a hard error.
2. **Route-to-loudspeaker, defaulted on** (`flutter_webrtc`'s `Helper.setSpeakerphoneOn`).
3. **Every exit path funnels through one teardown** — an explicit End action and the session
   dropping on its own both send `TEARDOWN` and stop the mic/recorder + return-audio player.
4. **In-call settings (speaker volume / mic gain) belong on the call panel**, not the idle tile.
5. **The plain live-view mute is a separate control** from the call's audio — the reference app
   disables the live-view mute button during a call (the player is force-muted anyway).
6. **Block back-navigation while a call is active** (`PopScope`) so the session isn't abandoned.

## 7. Client reference

| Piece | Where | Role |
|---|---|---|
| `TalkUriClient` / `TalkTarget` | `camera_api` (`talk_uri_client.dart`) | `POST /nuraeye/talk-uri` discovery |
| `RtspTalkSession` | app (`lib/features/live_view/rtsp/rtsp_talk_session.dart`) | the port-560 RTSPS `RECORD` session + mic uplink |
| `TalkDownlinkPlayer` | app (`lib/features/live_view/rtsp/talk_downlink_player.dart`) | return-audio playback |
| `TalkPanel` / `TalkStatus` / `AudioControlsSheet` | app (`lib/features/live_view/talk/talk_panel.dart`) | shared call-style UI |

Only `TalkUriClient` lives in `camera_api` — the RTSP session, mic capture (`package:record`),
and playback (`video_player`) are all app-level, since `camera_api` is pure-Dart with no
`dart:io` socket / native-media dependencies (see `STREAMING_GUIDE.md`'s opening note).

The wire protocol above is mirrored by `testing_utilities/two_way_talk_rtsp_test.py`'s
`RtspsTalkSession` — the hardware-verification reference; match it, not this prose, if they
disagree.

## 8. Known limitations

- **No WAN leg** — LAN-only (§1).
- **No role-based permission gating** in the app yet (§1).
- **Return-audio playback unverified on hardware** (§5).
- **`MMIC_CMD_SET_OUT_STAT<n>` semantics** (the camera-side per-output-slot enable the talk
  encoder relies on) are inferred from a closed-source header — see the stage DESIGN §8.
