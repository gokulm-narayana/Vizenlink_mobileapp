# `packages/camera_api` — all changes this session (2026-08-12)

Every client file in `packages/camera_api` that was touched this session, what changed in it, and
why. Two layers of history are covered:

- **Committed** (`git log` shows one commit, `1f7a093`, containing the bulk of this session's
  earlier work: scanning, per-screen wiring, the OSD Media2 migration, etc.) — not visible in
  `git diff` against `HEAD`, described here from the session's own record instead.
- **Uncommitted** (currently sitting in the working tree — `git status`/`git diff` against `HEAD`
  is authoritative for this part) — the SOAP-fault-detection fix and everything after it, including
  today's OSD colorspace fix.

## Uncommitted changes (current working tree, verified against `git diff`)

### New file: `lib/src/lan/onvif/soap_fault.dart`

```dart
String? soapFaultReason(String body) {
  try {
    final doc = XmlDocument.parse(body);
    if (doc.findAllElements('Fault', namespace: '*').isEmpty) return null;
    final reasonText = doc.findAllElements('Text', namespace: '*');
    return reasonText.isNotEmpty
        ? reasonText.first.innerText.trim()
        : 'SOAP fault (no reason given)';
  } on Exception {
    return null;
  }
}
```

Fixes a systemic bug: every ONVIF client's `_post()` only checked the HTTP status code, never the
SOAP body — a `<Fault>` element returned under HTTP 200 was silently treated as success. Applied
(added `final faultReason = soapFaultReason(response.body); if (faultReason != null) return
CameraFailure(faultReason);` right after the HTTP-200 check) to:

| File | Anything besides the fault fix? |
|---|---|
| `onvif_device_client.dart` | No — fault fix only (rest of diff is `dart format` reflow) |
| `audio_capability_client.dart` | No — fault fix only |
| `media2_capabilities_client.dart` | No — fault fix only |
| `onvif_imaging_client.dart` | No — fault fix only |
| `speaker_volume_client.dart` | No — fault fix only |
| `mask_client.dart` | **Yes** — see below |
| `onvif_video_encoder_client.dart` | **Yes** — see below |
| `osd_client.dart` | **Yes** — see below |

A regression test for the fault-detection fix was added in `test/onvif_device_client_test.dart`
("setDeviceName surfaces CameraFailure for a SOAP Fault returned with HTTP 200").

### `mask_client.dart` — fault fix + mask color/cap support

Beyond the fault fix above:
- `MaskColor` parsing added to `getMasks()` — reads `colorX`/`colorY`/`colorZ`/`colorspace` off
  each mask's `Color` element (previously ignored).
- `getMaskOptions()` now also parses `maxMasks`, used by Privacy Mode's zone cap (`_maxZones` uses
  `getMaskOptions().maxMasks` when known, still bounded by the app's own `maxDrawableZones = 8`).

### `onvif_video_encoder_client.dart` — fault fix + options cache

Beyond the fault fix above: added a process-lifetime `static final Map<String,
VideoEncoderSettingsOptions> _optionsCacheByHost` (same pattern as `MaskClient`'s own
`_endpointCacheByHost`/`_optionsCacheByHost`), per this repo's
`mobile-app-screen-conventions.md` rule that capability/options responses are a fixed
firmware-build property and shouldn't be re-fetched on every screen open.

### `osd_client.dart` — fault fix + real-hardware colorspace fix

Beyond the fault fix above, one functional addition from today's real-hardware debugging session:

```dart
const kOnvifColorspaceRgb = 'http://www.onvif.org/ver10/colorspace/RGB';
const kOnvifColorspaceYCbCr = 'http://www.onvif.org/ver10/colorspace/YCbCr';
```

**Why:** Saving the On-Screen Display screen's Time (`DateAndTime`) slot against a real camera
failed every time with a SOAP `ter:InvalidArgVal` ("Argument Value Invalid") fault. Two earlier
guesses were tried and ruled out first:

1. *Guessed date/time format strings* (app-side, not `camera_api`) — fixed via
   `_resolveDateFormatWire`/`_resolveTimeFormatWire` in `on_screen_display_screen.dart`. Retest:
   identical fault. Not the cause (the guessed strings were already valid).
2. *`GetOSDOptions` missing a `Type` filter* — added `<tr2:Type>DateAndTime</tr2:Type>` to the
   request, then reverted after reading the firmware source and confirming the request handler
   (`onvif_media2.c`) only ever parses `ConfigurationToken` for this call, and the response
   generator (`onvif_media_osd.c`) emits `DateFormat`/`TimeFormat` unconditionally whenever the
   camera's configured OSD types include `DateAndTime` (which this camera's shipped config
   always does) — so this was never actually the problem.

**Real cause**, found by reading the camera's own firmware source directly
(`~/Desktop/vizenlinkvms/nuraeye-rt/onvif/`, not part of this repo):
- `onvif_media_osd.c`'s `prvIsSupportedColor` rejects a font color unless its parsed `colorspace`
  enum matches an entry in the camera's advertised `ColorspaceRange`.
- `onvif_parser.c` converts the wire `Colorspace="..."` attribute into that enum via an exact
  `strcmp` against two hardcoded constants defined in `onvif_consts.c`:
  ```c
  const char* onvif_const_colorspace_rgb   = "http://www.onvif.org/ver10/colorspace/RGB";
  const char* onvif_const_colorspace_ycbcr = "http://www.onvif.org/ver10/colorspace/YCbCr";
  ```
- `on_screen_display_screen.dart`'s `_colorToWire` was sending a bare `colorspace: 'RGB'`, which
  matches neither constant — the parsed colorspace is left unset on the device, `prvIsSupportedColor`
  can never match it, and `onvif_media_osd_validateNewConfig` returns `OnvifError_InvalidReqArgVal`
  — exactly the fault reproduced on every attempt.

**Fix:** the two constants above added to `osd_client.dart`; `on_screen_display_screen.dart`'s
`_colorToWire` changed from `colorspace: 'RGB'` to `colorspace: kOnvifColorspaceRgb`. Not yet
confirmed by a user retest against the real camera as of this report.

### Docs

- `API_REFERENCE.md` — updated alongside the above (no method signatures changed, so only minor
  wording touch-ups).
- New file `SETTINGS_API_GUIDE.md` — which client/capability flag governs a given camera setting,
  organized by setting name rather than by client class (complements `API_REFERENCE.md`, which is
  organized by client class).

## Committed changes (already in `HEAD`, from earlier this session)

Not visible in `git diff` since they're baked into the one existing commit — recorded here from
this session's own history for a complete picture:

- **`osd_client.dart` — Media v1 → Media2 migration.** `GetOSDs`/`CreateOSD`/`SetOSD`/`DeleteOSD`/
  `GetOSDOptions` moved from ONVIF Media v1 to Media2, matching `MaskClient`/
  `OnvifVideoEncoderClient`'s existing Media2-only convention and the WAN path's own
  `onvif_media2_osd_applyNewConfig`.
- **`osd_client.dart` — position-type reporting.** `OsdOptions.positionTypes` now reports all 5
  camera-supported position types (4 fixed corners + Custom) instead of only `Custom` — direct
  user report that the app had no fixed-position option, only free dragging.
- **`osd_client.dart` — font color range support.** `OsdOptions.fontColorRangeAvailable` added —
  this firmware reports a continuous RGB `ColorspaceRange`, not a discrete `ColorList`, so the
  color picker UI needs to gate on a range, not a fixed swatch list.
- **`mask_client.dart` — `_endpointCacheByHost`/`_optionsCacheByHost` pattern.** The reference
  implementation for the process-lifetime caching convention other clients (`osd_client.dart`,
  `onvif_video_encoder_client.dart`) later followed.
- **General client build-out** for every screen wired this session (Night Mode, Video Mode,
  Imaging, Video Encoder, Privacy Mode) — `NightVisionClient`, `OnvifImagingClient`,
  `MirrorFlipClient`, `OnvifVideoEncoderClient`, `PrivacyModeClient`, `MaskClient` — these were
  authored/extended earlier this session and are part of the existing commit, not part of the
  uncommitted diff above.

## Verification run for the uncommitted changes

- `cd packages/camera_api && flutter test` — all tests pass; no test asserts the exact
  `Colorspace` wire string or the reverted `Type` filter, so nothing needed updating for either.
- `flutter analyze` (repo root) — no issues.
- `flutter test test/widget_test.dart` — same 7 pre-existing sandbox failures (real-network
  WS-Discovery scans can't complete in the test environment), no new regressions.
- App relaunched on the iOS Simulator with the fix live; **awaiting the user's retest against the
  real camera** to confirm the `ter:InvalidArgVal` fault is actually cleared.
