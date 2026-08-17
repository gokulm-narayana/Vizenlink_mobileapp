# camera_api — API Reference

`camera_api` is a pure-Dart package (**zero `package:flutter` dependency**) that is the sole
network-access layer for talking to a NuraEye/VizenLink IP camera, over both LAN and WAN (AWS
IoT). It has no UI logic of its own — it is meant to be consumed by a Flutter app's business
logic layer (or, in principle, by any other pure-Dart tool, such as an in-app agent's tool
registry). Every method that talks to the network is asynchronous and returns a typed
[`CameraResult<T>`](#result-type) rather than throwing — see that section for the pattern every
caller uses.

This file is organized by **client class** (mechanical params/returns, no decision logic). If
you know *which camera setting* you're implementing but not yet *which client* is correct for
it — settings that sound alike or overlap across LAN/WAN (e.g. Day/Night mode vs. Night Vision
Type), which capability/support flag gates a given setting (e.g. `wdrSupported`,
`hasMicrophone`, `wanCommandCapable` — there are over a dozen of these across the package, each
gating a different client), or why a `Wan*Client` call is failing (every WAN call requires the
user to be signed in via `auth_api`, checked before any capability flag) — see
[SETTINGS_API_GUIDE.md](SETTINGS_API_GUIDE.md) first.

## Folder layout

```
lib/
  camera_api.dart              — public barrel file (only what it exports is public API)
  src/
    camera_connection.dart     — CameraConnection (identifies/authenticates one camera)
    camera_result.dart         — CameraResult / CameraSuccess / CameraFailure / CameraTimeout
    mirror_flip_types.dart     — shared MirrorFlipMode enum (LAN + WAN pair)
    anti_flicker_types.dart    — shared AntiFlickerMode enum (LAN + WAN pair)
    night_vision_types.dart    — shared NightVisionType/NightVisionStatus/NightVisionSource
    privacy_mode_types.dart    — shared PrivacyMode enum (LAN + WAN pair)
    device_reset_types.dart    — shared FactoryResetMode enum (LAN + WAN pair)
    util/
      onvif_rect_coordinates.dart  — pixel <-> ONVIF-normalized-polygon math (masks/OSD)
    lan/
      wsse_digest.dart              — shared WSSE-style SHA-1 digest auth
      insecure_camera_http_client.dart — HTTP client that trusts the camera's self-signed cert
      onvif/                        — pure ONVIF SOAP clients
        onvif_device_client.dart
        onvif_imaging_client.dart
        onvif_video_encoder_client.dart
        osd_client.dart
        mask_client.dart
        audio_capability_client.dart
        media2_capabilities_client.dart
        speaker_volume_client.dart
        soap_fault.dart             — shared <Fault> detection, used by every client's _post()
      nuraeye/                      — the proprietary /nuraeye/* REST API
        nuraeye_client.dart         — core dispatcher (hand-written, everything else calls through it)
        audio_volume_client.dart
        event_preferences_client.dart
        event_response_actions_client.dart
        capabilities_client.dart
        deterrence_client.dart
        cloud_streaming_client.dart
        mirror_flip_client.dart
        anti_flicker_client.dart
        network_info_client.dart
        night_vision_client.dart
        privacy_mode_client.dart
        snapshot_client.dart
        webrtc_uri_client.dart
        nuraeye_rest_client.dart    — GENERATED (base REST transport)
        rest_*.dart                 — GENERATED (typed per-group REST clients)
        rest_result.dart            — GENERATED (RestResult/RestSuccess/RestFailure/RestTimeout)
      discovery/
        ws_discovery_client.dart    — WS-Discovery UDP client (find cameras on the LAN)
    wan/                           — AWS IoT MQTT command relay + KVS playback
      wan_auth.dart                — app-supplied auth/config hooks (set once at startup)
      iot_command_client.dart      — low-level command-relay transport
      kvs_playback_client.dart     — KVS HLS playback-URL lookup
      wan_live_view_client.dart    — WanLiveViewClient interface
      aws_wan_live_view_client.dart — concrete WanLiveViewClient implementation
      wan_audio_volume_client.dart
      wan_deterrence_client.dart
      wan_device_identity_client.dart
      wan_image_quality_client.dart
      wan_imaging_client.dart
      wan_mask_client.dart
      wan_mirror_flip_client.dart
      wan_anti_flicker_client.dart
      wan_event_preferences_client.dart
      wan_event_response_actions_client.dart
      wan_night_vision_client.dart
      wan_osd_client.dart
      wan_preview_snapshot_client.dart
      wan_privacy_mode_client.dart
      wan_speaker_volume_client.dart
      wan_video_encoder_client.dart
```

`lan/onvif/` and `lan/nuraeye/` are kept as separate protocol families deliberately: the former
speaks ONVIF SOAP (WS-UsernameToken digest auth), the latter speaks the camera's proprietary
`/nuraeye/*` JSON REST API (bearer-session auth). `wan/` mirrors a subset of `lan/nuraeye/`'s
settings one-for-one, over AWS IoT MQTT via a Lambda relay, for when the phone isn't on the same
network as the camera.

## Table of contents

- [Result type](#result-type)
- [Connecting to a camera](#connecting-to-a-camera)
- [LAN — ONVIF](#lan--onvif)
  - [OnvifDeviceClient](#onvifdeviceclient)
  - [OnvifImagingClient](#onvifimagingclient)
  - [OnvifVideoEncoderClient](#onvifvideoencoderclient)
  - [OsdClient](#osdclient)
  - [MaskClient](#maskclient)
  - [AudioCapabilityClient](#audiocapabilityclient)
  - [Media2CapabilitiesClient](#media2capabilitiesclient)
  - [SpeakerVolumeClient](#speakervolumeclient)
- [LAN — NuraEye REST](#lan--nuraeye-rest)
  - [Hand-written clients](#hand-written-clients)
    - [NuraeyeClient](#nuraeyeclient)
    - [AudioVolumeClient](#audiovolumeclient)
    - [EventPreferencesClient](#eventpreferencesclient)
    - [EventResponseActionsClient](#eventresponseactionsclient)
    - [DeterrenceClient](#deterrenceclient)
    - [CapabilitiesClient](#capabilitiesclient)
    - [CloudStreamingLanClient](#cloudstreaminglanclient)
    - [MirrorFlipClient](#mirrorflipclient)
    - [AntiFlickerClient](#antiflickerclient)
    - [NetworkInfoClient](#networkinfoclient)
    - [NightVisionClient](#nightvisionclient)
    - [PrivacyModeClient](#privacymodeclient)
    - [SnapshotClient](#snapshotclient)
    - [WebRtcUriClient](#webrtcuriclient)
  - [Generated REST clients](#generated-rest-clients)
- [LAN — Discovery](#lan--discovery)
  - [WsDiscoveryClient](#wsdiscoveryclient)
- [WAN — AWS IoT / KVS](#wan--aws-iot--kvs)
  - [WanAuth](#wanauth)
  - [IotCommandClient](#iotcommandclient)
  - [KvsPlaybackClient](#kvsplaybackclient)
  - [WanLiveViewClient / AwsWanLiveViewClient](#wanliveviewclient--awswanliveviewclient)
  - [WanAudioVolumeClient](#wanaudiovolumeclient)
  - [WanSpeakerVolumeClient](#wanspeakervolumeclient)
  - [WanDeviceIdentityClient](#wandeviceidentityclient)
  - [WanImageQualityClient](#wanimagequalityclient)
  - [WanImagingClient](#wanimagingclient)
  - [WanMaskClient](#wanmaskclient)
  - [WanMirrorFlipClient](#wanmirrorflipclient)
  - [WanAntiFlickerClient](#wanantiflickerclient)
  - [WanEventPreferencesClient](#waneventpreferencesclient)
  - [WanEventResponseActionsClient](#waneventresponseactionsclient)
  - [WanDeterrenceClient](#wandeterrenceclient)
  - [WanNightVisionClient](#wannightvisionclient)
  - [WanOsdClient](#wanosdclient)
  - [WanPrivacyModeClient](#wanprivacymodeclient)
  - [WanVideoEncoderClient](#wanvideoencoderclient)
  - [WanPreviewSnapshotClient](#wanpreviewsnapshotclient)
- [Shared types](#shared-types)
- [Getting started](#getting-started)

---

## Result type

Every network-calling method returns `Future<CameraResult<T>>`. `CameraResult<T>` is a sealed
class with three cases:

```dart
sealed class CameraResult<T> {}

class CameraSuccess<T> extends CameraResult<T> {
  final T value;
}

/// A request the camera actively rejected or failed to service (HTTP error, SOAP Fault, MQTT
/// error response). Distinct from CameraTimeout because a rejection is informative (e.g. wrong
/// password, unsupported feature), while a timeout only means "no answer".
class CameraFailure<T> extends CameraResult<T> {
  final String reason;
}

/// No response arrived within the call's bounded timeout.
class CameraTimeout<T> extends CameraResult<T> {}
```

Callers pattern-match with Dart's `switch` and object patterns:

```dart
switch (result) {
  case CameraSuccess(:final value):
    // use value
  case CameraFailure(:final reason):
    // show reason to the user / log it
  case CameraTimeout():
    // camera unreachable / no response in time
}
```

This is the API-stability contract of the package: no client ever returns a formatted string,
throws an app-level exception, or exposes a raw HTTP/SOAP/MQTT error — always one of these three
structured values, so both a human UI and a future automated caller can consume the exact same
return shape.

A parallel, internal-only `RestResult<T>` (`RestSuccess`/`RestFailure`/`RestTimeout`) exists in
`lan/nuraeye/rest_result.dart` for the generated REST-transport layer — it additionally carries
an HTTP status code on failure. App code should not normally need to touch it; `NuraeyeClient`
already translates it into `CameraResult` at its boundary.

---

## Connecting to a camera

`CameraConnection` is an immutable value identifying and authenticating against one camera.
Every client in this package takes a `CameraConnection` (or something built from one) in its
constructor.

```dart
const CameraConnection({
  required String host,        // LAN IP/hostname — NOT used for WAN, and not a stable identity
  required String username,
  required String password,
  int httpsPort = 443,
  int rtspPort = 554,
  String? thingName,           // AWS IoT thing name — required for any WAN call
  bool? wanLiveViewCapable,    // null = unknown (not yet queried), not "unsupported"
  String? macAddress,          // stable identity across DHCP lease changes
});
```

Key members:

| Member | Description |
|---|---|
| `identityKey` | `macAddress ?? host` — the key every local cache/store should use to recognize "which camera is this." **Never key a local store on `host` directly** — a DHCP renewal can change it for the same physical camera. |
| `onvifDeviceEndpoint` / `onvifImagingEndpoint` / `onvifMediaEndpoint` | Fixed ONVIF SOAP endpoint URIs derived from `host`/`httpsPort`. |
| `snapshotEndpoint({String profile = 'high'})` | `GET /snapshot` URI. `profile` is `"high"`, `"medium"`, or `"low"` — one of the camera's fixed ONVIF profile names. Use `"high"` for a user-facing capture, `"medium"` for a lightweight click-to-draw backdrop (mask/OSD editors). |
| `copyWithThingName(String)` | Returns a new connection with `thingName` set (once resolved via `OnvifDeviceClient.getSerialNumber()` at onboarding). |
| `copyWithWanLiveViewCapable(bool)` | Returns a new connection with the WAN-capability flag set. |
| `copyWithMacAddress(String)` | Returns a new connection with `macAddress` set. |
| `copyWithPassword(String)` | Returns a new connection with `password` replaced — call after a successful password change; the old connection keeps using its old password otherwise. |
| `toJson()` / `CameraConnection.fromJson(Map)` | Plain-Dart JSON (de)serialization, for the app's own local persistence. |

`CameraConnection` is only ever mutated by constructing a new instance — every `copyWith*`
method returns a fresh object.

---

## LAN — ONVIF

Every client in this section speaks ONVIF SOAP over HTTPS, authenticated with a WS-UsernameToken
digest (`wsse_digest.dart`'s `WsseDigest`, shared with the NuraEye REST login and snapshot auth).
All requests go through `insecure_camera_http_client.dart`'s `createCameraHttpClient()`, which
trusts the camera's self-signed certificate and preserves outgoing HTTP header case (the
camera's embedded server matches header names case-sensitively).

**Every client's `_post()` checks the response body for a SOAP `<Fault>` element via
`soap_fault.dart`'s `soapFaultReason()`, in addition to the HTTP status code.** This camera's
firmware doesn't always return a non-200 status for a fault — Media2 validation errors (e.g.
`SetOSD` rejecting an out-of-range color via `ter:InvalidArgVal`) come back as `HTTP 200` with a
`<s:Fault>` body, which an HTTP-status-only check would silently treat as success. Any new ONVIF
client added to this section must call `soapFaultReason(response.body)` the same way, right
after the HTTP-status check and before parsing the expected success shape.

### OnvifDeviceClient

`lan/onvif/onvif_device_client.dart` — `GetDeviceInformation`, `GetServices` (real ONVIF
service-discovery — other clients resolve their Media2 endpoint through this rather than a
hardcoded path), the device-identity trio (`GetScopes`/`SetScopes`, `GetSystemDateAndTime`/
`SetSystemDateAndTime`), account-password change, and reboot/factory-reset (`SystemReboot`/
`SetSystemFactoryDefault` — see `WanDeviceIdentityClient` for the WAN mirrors, since ONVIF SOAP
itself has no WAN transport).

```dart
OnvifDeviceClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getSerialNumber` | `{Duration timeout}` | `CameraResult<String>` | The camera's serial number — also its AWS IoT thing name/KVS stream name. Used at onboarding to populate `CameraConnection.thingName`. |
| `getDeviceInformation` | `{Duration timeout}` | `CameraResult<DeviceInformation>` | Full `GetDeviceInformation` (manufacturer/model/firmware/serial/hardware ID). |
| `getNetworkInterfaceInfo` | `{Duration timeout}` | `CameraResult<NetworkInterfaceInfo>` | The camera's active network interface (name/MAC/IPv4). `NetworkInterfaceInfo.isWireless` distinguishes wired vs WiFi. |
| `getServices` | `{Duration timeout}` | `CameraResult<List<OnvifServiceEntry>>` | Real ONVIF service discovery (`IncludeCapability: false`) — a missing entry means this camera build genuinely doesn't offer that service. |
| `getDeviceIdentity` | `{Duration timeout}` | `CameraResult<DeviceIdentity>` | Current display name + location (`GetScopes`). Either can be empty. |
| `setDeviceName` | `String name, {Duration timeout}` | `CameraResult<void>` | Sets display name only — name and location are set independently. |
| `setDeviceLocation` | `String location, {Duration timeout}` | `CameraResult<void>` | Sets location label only. |
| `getSystemDateAndTime` | `{Duration timeout}` | `CameraResult<DeviceDateTime>` | Camera's UTC clock + POSIX-style time zone string. |
| `setTimeZone` | `String tz, {Duration timeout}` | `CameraResult<void>` | Changes only the time zone — internally re-reads the current clock first and echoes it back, since the firmware requires a full Manual date/time on every `SetSystemDateAndTime` call. |
| `setUserPassword` | `String username, String newPassword, {Duration timeout}` | `CameraResult<void>` | Changes the camera's single local device account password (shared by ONVIF + NuraEye). **Caller must update its own stored `CameraConnection.password` on success** — this client keeps using the password it was constructed with. |
| `reboot` | `{Duration timeout}` | `CameraResult<String>` | Reboots the camera (`SystemReboot`). Returns the camera's `tt:Message` (typically `"Rebooting in 5 seconds"`). Success does **not** mean the device is back yet — expect a real connectivity gap of several seconds. |
| `factoryReset` | `FactoryResetMode mode, {Duration timeout}` | `CameraResult<void>` | Resets to factory defaults (`SetSystemFactoryDefault`). See [`FactoryResetMode`](#shared-types) for the Soft/Hard distinction — `hard` wipes WiFi credentials, forcing re-onboarding. **The camera reboots automatically afterward** (`bsp_rebootAsync()`) — same connectivity-gap caveat as `reboot` above, success does not mean the device is back yet. |
| `close` | — | `void` | Closes the underlying HTTP client. |

Constants: `kMaxDeviceNameLength`/`kMaxDeviceLocationLength` = 32, `kMaxDevicePasswordLength` =
15 — client-side length limits matching firmware constraints.

### OnvifImagingClient

`lan/onvif/onvif_imaging_client.dart` — Day/Night, WDR, and ISP image-quality controls, all
riding ONVIF's `GetImagingSettings`/`SetImagingSettings`/`GetOptions`. No WAN counterpart exists
in this package for the *settings* client itself (see `WanImagingClient`/`WanImageQualityClient`
for the WAN mirrors of these same fields, added later).

```dart
OnvifImagingClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getImagingSettings` | `{Duration timeout}` | `CameraResult<ImagingSettings>` | Current brightness/saturation/contrast/sharpness, Day/Night mode, WDR mode+level, exposure mode/time/gain, white-balance mode. |
| `getImagingOptions` | `{Duration timeout, bool forceRefresh = false}` | `CameraResult<ImagingOptions>` | Bounds/choice lists for every field above. **Process-lifetime cached per host** — pass `forceRefresh: true` only for an explicit user "reload" action, never a normal load. |
| `setImagingSettings` | `ImagingSettings settings, {Duration timeout}` | `CameraResult<void>` | Applies only the non-null fields of `settings` (matches firmware's optional-field semantics). |
| `close` | — | `void` | Closes the underlying HTTP client. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears the process-lifetime Options cache. |

`ImagingOptions.wdrSupported == false` means the WDR options element was entirely absent
(non-HDR sensor) — the UI should hide WDR outright, not just disable it.

### OnvifVideoEncoderClient

`lan/onvif/onvif_video_encoder_client.dart` — high-resolution profile (Stream 0,
`VideoEncoderCfg_1`) encoder settings via ONVIF **Media2** (`GetVideoEncoderConfigurations`/
`SetVideoEncoderConfiguration`/`GetVideoEncoderConfigurationOptions`). Distinct from the WAN-only
`SetStreamQuality`/`GetStreamQuality`, which target Stream 1's low-res mobile substream.

```dart
OnvifVideoEncoderClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getVideoEncoderSettings` | `{Duration timeout}` | `CameraResult<VideoEncoderSettings>` | Current bitrate, frame rate, GOV length, quality, encoder profile, width/height, encoding (`"H264"`/`"H265"`), CBR/VBR flag. |
| `setVideoEncoderSettings` | `VideoEncoderSettings settings, {Duration timeout}` | `CameraResult<void>` | Always sends the full configuration — SOAP `SetVideoEncoderConfiguration` has no partial-update mode. |
| `getVideoEncoderSettingsOptions` | `{Duration timeout, bool forceRefresh = false}` | `CameraResult<VideoEncoderSettingsOptions>` | Bounds/choices per encoding (H264 and H265 report different ranges/profiles/CBR support). **Process-lifetime cached per host.** |
| `close` | — | `void` | Closes the HTTP client and internal `OnvifDeviceClient`. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears endpoint + Options caches. |

`VideoEncoderSettingsOptions.forEncoding(String)` returns the `EncodingOptions` for a given
codec; `.availableEncodings` lists the codecs the camera reports.

### OsdClient

`lan/onvif/osd_client.dart` — On-Screen Display: timestamp overlay and free-text overlay, via
ONVIF **Media2** (`GetOSDs`/`CreateOSD`/`SetOSD`/`DeleteOSD`/`GetOSDOptions`). **Not yet
hardware-verified against a real camera** (no `testing_utilities/*.py` reference script exists
for OSD; wire format matched directly against firmware source).

```dart
OsdClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getOsds` | `{Duration timeout}` | `CameraResult<List<OsdEntry>>` | Currently-configured OSD entries (both slots ship enabled by default). |
| `createTimestampOsd` | `{String posType, double posX, double posY, String dateFormat, String timeFormat, OsdColor? fontColor, Duration timeout}` | `CameraResult<String>` | Creates the `DateAndTime` slot. Returns the new OSD token. |
| `createTextOsd` | `String text, {String posType, double posX, double posY, OsdColor? fontColor, Duration timeout}` | `CameraResult<String>` | Creates the `Plain` (free-text) slot. Returns the new OSD token. |
| `updateTextOsd` | `String token, String text, {String posType, double posX, double posY, OsdColor? fontColor, Duration timeout}` | `CameraResult<void>` | Updates the Plain OSD in place, keeping its token. |
| `updateTimestampPosition` | `String token, {String posType, required double posX, required double posY, String dateFormat, String timeFormat, OsdColor? fontColor, Duration timeout}` | `CameraResult<void>` | Updates the DateAndTime OSD in place, keeping its token. |
| `getOsdOptions` | `{Duration timeout, bool forceRefresh = false}` | `CameraResult<OsdOptions>` | Font size range, color support, position/date/time-format choices. **Process-lifetime cached per host.** |
| `deleteOsd` | `String token, {Duration timeout}` | `CameraResult<void>` | Removes an OSD entry ("off" is modeled as delete, not a hide flag). |
| `close` | — | `void` | Closes the HTTP client and internal `OnvifDeviceClient`. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears endpoint + Options caches. |

Position-type constants: `kOsdPositionCustom`, `kOsdPositionUpperLeft`,
`kOsdPositionUpperRight`, `kOsdPositionLowerLeft`, `kOsdPositionLowerRight`. `posX`/`posY` (each
in `[-1, 1]`) are only meaningful/sent when `posType == kOsdPositionCustom`.

### MaskClient

`lan/onvif/mask_client.dart` — Privacy mask editor backend via ONVIF **Media2**
(`CreateMask`/`SetMask`/`DeleteMask`/`GetMasks`/`GetMaskOptions`). Always sends a 4-point
rectangle polygon. **Not yet hardware-verified** against a real camera.

```dart
MaskClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getMasks` | `{Duration timeout}` | `CameraResult<List<MaskEntry>>` | Currently-configured masks. |
| `getMaskOptions` | `{Duration timeout, bool forceRefresh = false}` | `CameraResult<MaskOptions>` | `MaxMasks`/`MaxPoints`/supported types/colors. **Process-lifetime cached per host** — see the class doc for why (real-world impact: redundant requests were starving the RTSP pipeline, since the HTTPD task runs at the highest FreeRTOS priority tier). |
| `createMask` | `{required List<OnvifPoint> polygon, required bool enabled, required String type, MaskColor? color, Duration timeout}` | `CameraResult<String>` | Creates a new mask. Returns its token. |
| `setMask` | `{required String token, required List<OnvifPoint> polygon, required bool enabled, required String type, MaskColor? color, Duration timeout}` | `CameraResult<void>` | Updates an existing mask in place. |
| `deleteMask` | `String token, {Duration timeout}` | `CameraResult<void>` | Removes a mask. |
| `close` | — | `void` | Closes the HTTP client and internal `OnvifDeviceClient`. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears endpoint + Options caches. |

`MaskEntry.type` is echoed by ONVIF but only `"Color"` (a fixed black rectangle) is actually
rendered by this firmware today — gate UI on `MaskOptions.types`/`colorList`, not on assuming
all three ONVIF mask types work.

### AudioCapabilityClient

`lan/onvif/audio_capability_client.dart` — audio hardware **presence** check (not
configuration), used to gate the two-way-talk control. **Media2** (`GetAudioSourceConfigurations`/
`GetAudioOutputConfigurations` with a fixed `ConfigurationToken`) — migrated off Media v1's
`GetAudioSources`/`GetAudioOutputs` 2026-08-12 for consistency with every other ONVIF client in
this package.

```dart
AudioCapabilityClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getAudioCapability` | `{Duration timeout}` | `CameraResult<AudioCapability>` | `hasSpeaker` (`GetAudioOutputConfigurations` non-empty) and `hasMicrophone` (`GetAudioSourceConfigurations` non-empty). |
| `close` | — | `void` | Closes the HTTP client and internal `OnvifDeviceClient`. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears the endpoint cache. |

### Media2CapabilitiesClient

`lan/onvif/media2_capabilities_client.dart` — whether this camera advertises OSD/Mask support at
all, via Media2 `GetServiceCapabilities`. Resolves its endpoint through `OnvifDeviceClient
.getServices()` rather than a hardcoded path; a camera with no Media2 service at all returns a
normal "not supported" success result, not a failure.

```dart
Media2CapabilitiesClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getServiceCapabilities` | `{Duration timeout}` | `CameraResult<Media2Capabilities>` | `osdSupported`/`maskSupported` booleans. |
| `close` | — | `void` | Closes the HTTP client and internal `OnvifDeviceClient`. |

### SpeakerVolumeClient

`lan/onvif/speaker_volume_client.dart` — camera-side speaker output volume via ONVIF Media2
(`GetAudioOutputConfigurations`/`SetAudioOutputConfiguration`). Distinct from the phone's own
local volume. Hardware-verified (against an earlier Media v1 build; not yet re-verified against
Media2 specifically).

```dart
SpeakerVolumeClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getSpeakerVolume` | `{Duration timeout}` | `CameraResult<SpeakerVolume>` | Current output level (0-100) plus the token/name/outputToken fields ONVIF requires echoing back on set. Returns `CameraFailure` if the camera reports no `AudioOutputConfiguration` at all (no speaker) — UI should have already gated on `AudioCapabilityClient.hasSpeaker` before calling. |
| `setSpeakerVolume` | `SpeakerVolume current, {Duration timeout}` | `CameraResult<void>` | Applies a new volume — pass a `SpeakerVolume` built via `.withLevel(newLevel)` on a previously-loaded value, since ONVIF requires the sibling fields resent. |
| `close` | — | `void` | Closes the HTTP client and internal `OnvifDeviceClient`. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears the endpoint cache. |

---

## LAN — NuraEye REST

Every client in this section ultimately calls through `NuraeyeClient`, which speaks the camera's
`/nuraeye/*` REST API (bearer-session auth, per `FR-NE-104`/`FR-NE-105`).

### Hand-written clients

These are the classes most app code actually touches — each wraps `NuraeyeClient.call()` with a
typed method per action.

#### NuraeyeClient

`lan/nuraeye/nuraeye_client.dart` — the core dispatcher every other NuraEye-protocol client in
this package calls through. Translates a legacy `action` string + params into the matching REST
resource call internally.

```dart
NuraeyeClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `call` | `String action, {Map<String, dynamic>? params, Duration timeout}` | `CameraResult<Map<String, dynamic>>` | Dispatches one legacy NuraEye action (e.g. `"GetWiFiInfo"`, `"SetNightVisionType"`) to its REST equivalent. Returns the parsed `output` map. |
| `areYouNuraeyeDevice` | `{Duration timeout}` | `CameraResult<bool>` | `POST /nuraeye/identity` challenge-response device-genuineness check, using a fixed challenge password (not the connection's real credentials) — locally recomputes and compares the expected reply digest. Unauthenticated; the cheapest round trip in this API. Single-shot — used as-is by `WebRtcUriClient.checkReachable()`, which deliberately wants a fast, non-retrying probe. |
| `areYouNuraeyeDeviceWithRetry` | `{int attempts = 3, Duration attemptTimeout = 8s, Duration retryDelay = 1s}` | `CameraResult<bool>` | Retrying variant for first-contact discovery/onboarding only (`DiscoveryScreen`'s candidate filter, `AddCameraCredentialsScreen`'s manual-entry check) — added 2026-08-15 after a real-device report and a live Python check confirmed a genuine camera can lose to `areYouNuraeyeDevice`'s single 5s attempt on a phone's *first* HTTPS request over a given WiFi connection (cold TLS handshake/radio wake-up), despite answering in ~0.4s once the connection is warm. Stops retrying as soon as one attempt succeeds; returns the last result once every attempt is exhausted. |
| `close` | — | `void` | Closes the HTTP client. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears session/capabilities/in-flight-login caches. |
| `clearSessionFor` (static) | `String host` | `void` | Drops the cached bearer session for `host` — call after a password change or when a camera is removed from the app, so a stale session can't mask a wrong re-entered password on a re-add. |

**Notable behavior:**
- **Bearer sessions are cached per camera host for the life of the app process** (not per
  `NuraeyeClient` instance — most call sites construct a short-lived instance per call).
  Proactively checked for expiry before use and refreshed on activity (mirrors the firmware's
  idle-based session timeout), with a one-time re-login retry on a `401` as a backstop.
- **Concurrent logins for the same host are serialized** — the firmware only holds 6 concurrent
  sessions total (LRU-evicted), so multiple simultaneous fresh `NuraeyeClient`s for one camera
  share a single in-flight login instead of each triggering their own.
- `GetCapabilities` responses are cached per host (a fixed build property, not per-request
  state).
- Failure strings are prefixed `HTTP <code>: <reason>` when a status code is known — some app
  code depends on finding the numeric code as text (e.g. detecting a `401` to show "incorrect
  password").

`call`'s recognized `action` strings (each maps to a REST resource internally): `GetWiFiInfo`,
`SetupWiFi`, `GetWiFiSignalStrength`, `GetSupportedTimezones`, `GetCloudStreamingStatus`,
`StopCloudStreaming`, `GetPrivacyMode`, `SetPrivacyMode`, `GetMicGain`, `SetMicGain`,
`GetAudioRecording`, `SetAudioRecording`, `PlayTestSound`, `StopTestSound`,
`GetTestSoundStatus`, `GetCapabilities`, `GetNightVisionType`, `SetNightVisionType`,
`GetMirrorFlip`, `SetMirrorFlip`, `GetWebRtcUri`, `GetImageDefaults`, `GetVideoMode`,
`RegisterPreviewKey`. Prefer the typed wrapper clients below over calling `call()` directly where
one exists.

#### AudioVolumeClient

`lan/nuraeye/audio_volume_client.dart` — microphone input gain, microphone recording on/off, and
speaker test-tone playback.

```dart
AudioVolumeClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getMicGain` | `{Duration timeout}` | `CameraResult<int>` | Current mic input gain. |
| `setMicGain` | `int gain, {Duration timeout}` | `CameraResult<void>` | Sets mic input gain. |
| `isAudioRecordingEnabled` | `{Duration timeout}` | `CameraResult<bool>` | Whether the mic is actively capturing at all (distinct from gain level). |
| `setAudioRecordingEnabled` | `bool enabled, {Duration timeout}` | `CameraResult<void>` | Toggles mic recording. |
| `playTestSound` | `{Duration timeout}` | `CameraResult<void>` | Plays a short prerecorded test tone through the speaker. |
| `stopTestSound` | `{Duration timeout}` | `CameraResult<void>` | Stops test-tone playback. |
| `isTestSoundPlaying` | `{Duration timeout}` | `CameraResult<bool>` | Whether the test tone is still playing. |
| `close` | — | `void` | Closes the internal `NuraeyeClient`. |

Speaker *output* volume is a separate ONVIF action — see `SpeakerVolumeClient` above.

#### CapabilitiesClient

`lan/nuraeye/capabilities_client.dart` — camera capability discovery, queried once at onboarding
and cached by the app.

```dart
CapabilitiesClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getCapabilities` | `{Duration timeout}` | `CameraResult<CameraCapabilities>` | `wanCommandCapable` (AWS IoT/MQTT support), `wanLiveViewCapable` (additionally requires KVS build support — both also require this specific device to have real AWS credentials provisioned, not just build-time support), `supportedEventTypes` (`FR-CF-143`/`FR-NE-111` — the alert event strings this build actually generates; empty on firmware too old to report it), `supportedEventDeterrenceOptions` (`FR-CF-144`/`FR-NE-112` — per detection event type, which response actions are eligible for it; only detection-type events appear as keys, empty map on firmware too old to report it), and `sirenCapable`/`spotlightCapable`/`warningCapable` (`FEAT-236`, 2026-08-14 — same hardware-presence flags `GetDeterrenceCapabilities` reports on its own dedicated endpoint, mirrored here so `DeterrenceClient`-consuming UI can reuse this already-fetched response instead of a second round trip; `false` on firmware too old to report them). |

#### EventPreferencesClient

`lan/nuraeye/event_preferences_client.dart` — `GetEventPreferences`/`SetEventPreferences`
(`FR-CF-143`, `FR-NE-111`) — see `WanEventPreferencesClient` for the WAN mirror.

```dart
EventPreferencesClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getEventPreferences` | `{Duration timeout}` | `CameraResult<Map<String, bool>>` | Current enabled/disabled state, keyed by the same strings `CapabilitiesClient`'s `supportedEventTypes` reports. |
| `setEventPreferences` | `Map<String, bool> changes, {Duration timeout}` | `CameraResult<void>` | Partial update — only the keys present in `changes` change; every other type's state is left untouched. An unrecognized key is a `CameraFailure` (camera returns `HTTP 400`, whole request rejected, no partial application). |

**Disabling a type is a real, device-side change** — the camera suppresses it at the source
(`EventMgr_Send()`), on every delivery path it has, including ONVIF PullPoint — not a
client-side filter, not scoped to this app's own feed.

#### EventResponseActionsClient

`lan/nuraeye/event_response_actions_client.dart` — `GetEventResponseActions`/
`SetEventResponseActions` (`FR-CF-144`, `FR-NE-112`) — see `WanEventResponseActionsClient` for
the WAN mirror.

```dart
EventResponseActionsClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getEventResponseActions` | `{Duration timeout}` | `CameraResult<Map<String, List<String>>>` | Current selected response actions per detection event type, keyed by the same strings `CapabilitiesClient`'s `supportedEventDeterrenceOptions` reports. |
| `setEventResponseActions` | `Map<String, List<String>> changes, {Duration timeout}` | `CameraResult<void>` | Partial update — only the event types present in `changes` change; each key's array fully **replaces** that event type's selected action set (not additive). An unrecognized event type key, or an action not eligible for that type, is a `CameraFailure` (camera returns `HTTP 400`, whole request rejected, no partial application). |

**Not to be confused with `EventPreferencesClient`** — that controls whether an event type is
generated at all; this controls what happens *in addition* when an already-enabled detection
event fires. `siren`/`spotlight`/`warning` are real physical device actions the camera
auto-triggers; `mobile_alert` has no device-side effect at all — this app reads it locally to
decide whether to show a push notification, never as a device-side gate.

#### DeterrenceClient

`lan/nuraeye/deterrence_client.dart` — `ActivateDeterrence`/`DeactivateDeterrence`/
`GetDeterrenceStatus` (`FR-NE-082`/`083`) plus `GetDeterrenceDurations`/`SetDeterrenceDurations`
(`FR-NE-113`, `FEAT-236`) — see `WanDeterrenceClient` for the WAN mirror.

```dart
DeterrenceClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getDeterrenceStatus` | `{Duration timeout}` | `CameraResult<DeterrenceStatus>` | Each deterrence action's own independent active/inactive state (`siren`/`spotlight`/`warning` fields, `activeActions` getter, `isActive(action)` helper) — siren/spotlight/warning are independent hardware outputs and can be active simultaneously (`FEAT-236`, 2026-08-14 fix; previously a single `{active, action}` pair could only ever report one action as "the" active one). |
| `activateDeterrence` | `String action, {Duration timeout}` | `CameraResult<void>` | `action` ∈ `siren`/`spotlight`/`warning`, gated on `CapabilitiesClient`'s `sirenCapable`/`spotlightCapable`/`warningCapable`. **No duration parameter** (removed `FEAT-236`, 2026-08-14) — the camera applies its own persisted duration from `getDeterrenceDurations`/`setDeterrenceDurations` instead, shared with the camera's own automatic detection-triggered response (`EventResponseActionsClient`). |
| `deactivateDeterrence` | `String action, {Duration timeout}` | `CameraResult<void>` | Stops immediately, regardless of how much of the configured duration remains. |
| `getDeterrenceDurations` | `{Duration timeout}` | `CameraResult<Map<String, int>>` | Current configured auto-stop value per action, keyed `siren_seconds`/`spotlight_seconds` (whole seconds) and `warning_repeat_count` (a repeat count, not seconds — see below). Only the keys `CapabilitiesClient` reports as capable are meaningful. |
| `setDeterrenceDurations` | `Map<String, int> changes, {Duration timeout}` | `CameraResult<void>` | Partial update — only the keys present in `changes` change. An unrecognized key, a value outside `getDeterrenceDurationOptions`' reported range for it, or an action this build isn't capable of is a `CameraFailure` (camera returns `HTTP 400`, whole request rejected). |
| `getDeterrenceDurationOptions` | `{Duration timeout}` | `CameraResult<DeterrenceDurationOptions>` | Camera-reported valid `min`/`max` per key — **build UI bounds from this, never hardcode a range** (real-hardware finding, 2026-08-15: an earlier version hardcoded 0-60s and let the UI set a degenerate `0`). |

**`warning`'s value is a repeat count, not seconds** (revised `FEAT-236`, 2026-08-15, after
real-hardware testing) — it repeats its prerecorded clip `warning_repeat_count` times before
stopping (or until an explicit `deactivateDeterrence`), rather than running for a duration. A
duration-based loop was tried first and found unreliable on real hardware (a fixed-period guess
timer cut the clip off partway through and restarted it) — the current implementation is
completion-driven internally (`bsp_camera_ameba.c`'s `prvWarningPollTimerCallback()`), so the
app only needs to know "how many times," not "how long."

#### CloudStreamingLanClient

`lan/nuraeye/cloud_streaming_client.dart` — LAN counterparts to two of `WanLiveViewClient`'s
three commands. No LAN `startCloudStreaming` — starting cloud streaming only makes sense for a
WAN-bound client.

```dart
CloudStreamingLanClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getCloudStreamingStatus` | `{Duration timeout}` | `CameraResult<StreamStatus>` | `active`/`idle`/`degraded`/`notCompiled`. A failed/timed-out LAN call here means "not reachable on this network," not "camera offline." |
| `stopCloudStreaming` | `{Duration timeout}` | `CameraResult<void>` | Stops the KVS push — used opportunistically once LAN reachability is confirmed, to avoid an unnecessary AWS/Lambda round trip. |

#### MirrorFlipClient

`lan/nuraeye/mirror_flip_client.dart` — LAN transport for mirror/flip mode.

```dart
MirrorFlipClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getMirrorFlip` | `{Duration timeout}` | `CameraResult<MirrorFlipMode>` | Current mode. |
| `setMirrorFlip` | `MirrorFlipMode mode, {Duration timeout}` | `CameraResult<void>` | Sets mode. |

See `wan/wan_mirror_flip_client.dart`'s `WanMirrorFlipClient` for the WAN counterpart (same
`MirrorFlipMode` enum).

#### AntiFlickerClient

`lan/nuraeye/anti_flicker_client.dart` — LAN transport for power-line frequency / anti-flicker
mode. No ONVIF-standard element exists for this setting (checked against the live
`ImagingSettings20` schema — see `kb/raw/2026-08-12-feature-antiflicker-mode.md`), same
situation as `MirrorFlipClient` above.

```dart
AntiFlickerClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getAntiFlickerMode` | `{Duration timeout}` | `CameraResult<AntiFlickerMode>` | Current mode (`hz50`/`hz60`/`auto`). |
| `setAntiFlickerMode` | `AntiFlickerMode mode, {Duration timeout}` | `CameraResult<void>` | Sets mode. |

See `wan/wan_anti_flicker_client.dart`'s `WanAntiFlickerClient` for the WAN counterpart (same
`AntiFlickerMode` enum).

#### NetworkInfoClient

`lan/nuraeye/network_info_client.dart` — WiFi info/setup/signal and the curated time-zone
catalog; no ONVIF equivalent.

```dart
NetworkInfoClient(CameraConnection connection, {http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getWifiSsid` | `{Duration timeout}` | `CameraResult<String>` | Configured WiFi SSID (the WiFi password is deliberately discarded, never surfaced). Only meaningful when the active interface is wireless. |
| `setupWifi` | `{required String ssid, required String psk, bool verify = true, Duration timeout}` | `CameraResult<void>` | Sends new WiFi credentials. `verify: true` (default) saves and attempts a connection; the firmware always forces save-only when currently reached over Ethernet, regardless of this flag. |
| `getWifiSignalStrength` | `{Duration timeout}` | `CameraResult<({int rssi, int snr})>` | Current WiFi signal strength. Only meaningful when wireless. |
| `getSupportedTimezones` | `{bool forceRefresh = false, Duration timeout}` | `CameraResult<List<TimezoneOption>>` | Camera-served curated time-zone list. **Process-lifetime cached per host.** Older firmware without this action returns `CameraFailure` — fall back to a hardcoded list rather than an empty picker. |
| `close` | — | `void` | Closes the internal `NuraeyeClient`. |
| `debugClearCaches` (static) | — | `void` | Test-only: clears the time-zone cache. |

`TimezoneOption.code` is the POSIX-style string to pass to `OnvifDeviceClient.setTimeZone` — the
*setting* of time zone stays an ONVIF action; only the catalog to pick from is NuraEye.

#### NightVisionClient

`lan/nuraeye/night_vision_client.dart` — LAN transport for night-vision type, implementing the
shared `NightVisionSource` interface.

```dart
class NightVisionClient implements NightVisionSource {
  NightVisionClient(NuraeyeClient nuraeye)
}
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getNightVisionType` | `{Duration timeout}` | `CameraResult<NightVisionStatus>` | Current type (`grey`/`color`/`smart`), capability flags, and (for `smart`) live sub-state. |
| `setNightVisionType` | `NightVisionType type, {Duration timeout}` | `CameraResult<void>` | Sets night-vision type. |

See `wan/wan_night_vision_client.dart`'s `WanNightVisionClient` for the WAN counterpart —
identical interface, so UI code can hold either behind a single `NightVisionSource` reference.

#### PrivacyModeClient

`lan/nuraeye/privacy_mode_client.dart` — LAN transport for privacy mode.

```dart
PrivacyModeClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getPrivacyMode` | `{Duration timeout}` | `CameraResult<PrivacyMode>` | Current mode (`none`/`zone`/`full`). |
| `setPrivacyMode` | `PrivacyMode mode, {Duration timeout}` | `CameraResult<void>` | Sets mode. `full` stops all capture; `zone` uses whatever mask zones are already configured. |

See `wan/wan_privacy_mode_client.dart`'s `WanPrivacyModeClient` for the WAN counterpart.

#### SnapshotClient

`lan/nuraeye/snapshot_client.dart` — `GET /snapshot` still-image capture. Notably built directly
on `dart:io`'s `HttpClient` rather than `package:http` (needed to preserve HTTP header case for
its `Authorization` header, since this is the one endpoint in the package that carries auth in a
header rather than a request body).

```dart
SnapshotClient(CameraConnection connection)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getSnapshot` | `{Duration timeout, String profile = 'high'}` | `CameraResult<Uint8List>` | Captures a still JPEG. `profile` — see `CameraConnection.snapshotEndpoint`'s doc for the `"high"`/`"medium"`/`"low"` choice. |
| `close` | — | `void` | Closes the underlying `HttpClient`. |

#### WebRtcUriClient

`lan/nuraeye/webrtc_uri_client.dart` — the mobile app's only LAN live-view discovery mechanism
(RTSP is reserved for VMS/NVR and is not exposed by this package). No WAN counterpart exists —
the signaling socket has no WAN reachability.

```dart
WebRtcUriClient(NuraeyeClient nuraeye)
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getWebRtcUri` | `String profileToken, {Duration timeout}` | `CameraResult<WebRtcTarget>` | Resolves the LAN WebRTC signaling port + URL (`http://`, not `https://` — the signaling socket is unauthenticated/unencrypted by firmware design) for one video profile (`Profile_1`/`Profile_2`/`Profile_3`). |
| `checkReachable` | `{Duration timeout = 3s}` | `Future<bool>` (not `CameraResult`) | Independent LAN reachability probe via `areYouNuraeyeDevice` — used to distinguish "camera not on this network" from "camera on this network but WebRTC signaling itself is failing." |
| `close` | — | `void` | Closes the internal `NuraeyeClient`. |

### Generated REST clients

The `rest_*.dart` files (plus `nuraeye_rest_client.dart` and `rest_result.dart`) are
**machine-generated** by `tools/generate_dart_rest_client.py` from
`design/Camera-REST-API.openapi.yaml`, regenerated via the `/generate_dart_client` command —
**never hand-edit these files.** They mirror the OpenAPI spec's `/nuraeye/*` paths 1:1, one
group-client class per OpenAPI tag, each method returning `Future<RestResult<T>>` (the
REST-specific result type, distinct from `CameraResult`).

`NuraeyeRestClient` (`nuraeye_rest_client.dart`) is the shared low-level transport every
generated client (and `NuraeyeClient` itself) calls through — it owns the camera's host/port/
scheme/bearer-token and unwraps the `{error_code, error_msg, output}` response envelope into a
`RestResult<Map<String, dynamic>>`.

**These generated per-group clients are currently unused by `NuraeyeClient`** (which builds
directly on `NuraeyeRestClient` instead) — they exist as a ready-made typed surface for future
use or for a consumer that wants the REST API's native shape rather than the legacy
action/params shape `NuraeyeClient.call()` presents.

| Class | Covers |
|---|---|
| `RestIdentityDiscoveryClient` | `identityChallenge`, `sessionLogin`, `sessionLogout` — device identity and bearer-session lifecycle. |
| `RestCapabilitiesClient` | `getCapabilities` — every build/unit capability flag in one response. |
| `RestNetworkConnectivityClient` | WiFi get/set, WiFi signal, time zones, cloud parameters. |
| `RestAudioClient` | Audio recording, audio settings (mic gain + speaker volume), test-sound status. |
| `RestVideoImageClient` | Image defaults, mirror/flip, night-vision type, video mode. |
| `RestStreamingClient` | Cloud streaming status/stop, WebRTC URI resolution, preview-key registration. |
| `RestPrivacyClient` | Privacy mode get/set. |
| `RestDeterrenceAlarmsClient` | Buzzer and deterrence-action status/control. |
| `RestStorageClient` | Local storage (SD card) status/enable. |
| `RestAlertsClient` | Per-rule alert configuration (mobile notifications, buzzer activation). |

Each generated file also defines its own plain-data response classes (e.g.
`GetCapabilitiesResponse`, `GetPrivacyModeResponse`) with a `fromJson` factory — these are
distinct types from the hand-written clients' own domain types (`CameraCapabilities`,
`PrivacyMode`, etc.) even where they cover the same data.

---

## LAN — Discovery

### WsDiscoveryClient

`lan/discovery/ws_discovery_client.dart` — pure-Dart WS-Discovery UDP client (multicast primary
+ unicast subnet-sweep fallback) for finding ONVIF/NuraEye devices on the LAN.

```dart
WsDiscoveryClient()
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `scanMulticast` | `{Duration timeout = 5s}` | `Future<List<WsDiscoveryCandidate>>` | Sends a multicast Probe to `239.255.255.250:3702` and collects `ProbeMatch` replies for `timeout`. The primary discovery tier. |
| `scanUnicast` | `{Duration overallCap = 15s, Duration stragglerWait = 5s}` | `Future<List<WsDiscoveryCandidate>>` | Fallback: sweeps every host on each local IPv4 interface's assumed `/24` subnet with a unicast Probe. Only run when `scanMulticast` finds nothing. |

Each `WsDiscoveryCandidate` is a raw probe match — **not yet verified as a genuine NuraEye
device**; call `NuraeyeClient.areYouNuraeyeDevice()` separately per candidate to confirm.
`WsDiscoveryCandidate.deviceServiceUri` gives the ONVIF device-service URL to probe.

Documented limitation: the unicast sweep assumes a `/24` subnet per interface rather than
deriving the real prefix length (`dart:io` has no portable API for that) — correct for the
overwhelming majority of home/community LANs, this app's target deployment.

---

## WAN — AWS IoT / KVS

Every client in this section talks to the camera indirectly, via AWS IoT Core MQTT commands and
a Lambda relay (`cloud_backend/kvs_playback_lambda`) rather than a direct HTTP/SOAP connection.
None of them import anything app-specific — they source their AWS credentials/config through
`WanAuth`'s static hooks instead.

### WanAuth

`wan/wan_auth.dart` — app-wide static hooks every WAN client falls back to when not given a
per-call override. **Set these exactly once, at app startup, before the first WAN call** (e.g.
in `main.dart`).

| Hook | Type | Purpose |
|---|---|---|
| `idTokenProvider` | `String? Function()?` | Returns the signed-in session's current Cognito ID token, or `null` if not signed in. Backs every AWS IoT command and KVS playback lookup. |
| `kvsPlaybackLambdaUrl` | `String?` | The deployed `cloud_backend/kvs_playback_lambda` Function URL. Every WAN command and KVS lookup goes through this one relay. Fleet-wide, not per-camera. |
| `previewPrivateKeyProvider` | `Future<RSAPrivateKey?> Function()?` | Returns the device's stored RSA private key for the WAN preview-snapshot decrypt path, or `null` if no keypair has been generated/registered yet. Backs `WanPreviewSnapshotClient`. |
| `onPreviewKeyNeedsRegistration` | `void Function(String thingName)?` | Called when the camera reports its previously-registered preview key is gone (e.g. after a factory reset) — the app should flag that camera for automatic re-registration next time it's reachable on LAN. |

### IotCommandClient

`wan/iot_command_client.dart` — the low-level AWS IoT command-relay transport every other WAN
client in this package sits on top of. Talks to the Lambda relay over plain HTTPS with the
Cognito ID token as a bearer token (not AWS SigV4 — Cognito-federated credentials are rejected by
AWS for direct MQTT publish, hence the relay).

```dart
IotCommandClient(String thingName, {String? Function()? idTokenProvider, http.Client? httpClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `sendStartCloudStreaming` | — | `Future<void>` | Fire-and-forget `StartCloudStreaming`. Throws on transport/relay failure. |
| `sendStopCloudStreaming` | — | `Future<void>` | Fire-and-forget `StopCloudStreaming`. |
| `sendCommandWithResponse` | `int command, {Map<String, dynamic>? params, double? timeoutSeconds}` | `Future<Map<String, dynamic>?>` | Generic request/response relay for any command that replies on the camera's response topic. Returns `null` on a server-side timeout (camera didn't respond within the window); the Lambda's own wait is clamped to 25s server-side regardless of `timeoutSeconds`. Has a one-shot automatic retry on an HTTP 504 from the relay itself (transient MQTT session jitter, not a stuck camera). Throws on a genuine relay/camera-side failure. |

Every WAN setting client below is a thin typed wrapper around `sendCommandWithResponse` with a
specific integer command constant (defined as `static const` fields on this class, e.g.
`IotCommandClient.getMirrorFlip`) and a params/response shape. App code does not normally need to
call `IotCommandClient` directly except through those wrappers.

### KvsPlaybackClient

`wan/kvs_playback_client.dart` — resolves a playable KVS URL via the Lambda relay.

```dart
KvsPlaybackClient({http.Client? client, String? Function()? idTokenProvider})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getPlaybackUrl` | `String streamName` | `Future<String>` | Returns the HLS streaming session URL. Throws on failure (401 bad/expired token, 403 stream outside this fleet, 502 KVS lookup failed — e.g. `StartCloudStreaming` was never sent first). **Cloud/hardware-verified** — the "not yet deployed" note here was stale by 2026-08-13; see `STREAMING_GUIDE.md` for the full sequence this fits into and `design/FR-mobile-app.md`'s `FR-MOB-031` for the verification history. |

### WanLiveViewClient / AwsWanLiveViewClient

`wan/wan_live_view_client.dart` defines the interface; `wan/aws_wan_live_view_client.dart`
provides the concrete implementation over `IotCommandClient` + `KvsPlaybackClient`.

```dart
abstract interface class WanLiveViewClient {
  Future<CameraResult<void>> startCloudStreaming();
  Future<CameraResult<void>> stopCloudStreaming();
  Future<CameraResult<StreamStatus>> getCloudStreamingStatus();
  Future<CameraResult<Uri>> resolvePlaybackUri();
}

class AwsWanLiveViewClient implements WanLiveViewClient {
  AwsWanLiveViewClient(
    String thingName, {
    IotCommandClient? iotCommandClient,
    KvsPlaybackClient? kvsPlaybackClient,
  })
}
```

| Method | Description |
|---|---|
| `startCloudStreaming` | Starts the KVS push for this camera. |
| `stopCloudStreaming` | Stops it. |
| `getCloudStreamingStatus` | Returns `active`/`idle`/`degraded`/`notCompiled` (`StreamStatus` enum). Retries a couple of times on a transient `idle` result right after starting, since the substream can legitimately still be spinning up. |
| `resolvePlaybackUri` | Resolves a playable URI once streaming is confirmed active, via `KvsPlaybackClient`. |

**Hardware/cloud-verified** (corrected 2026-08-13 — was stale). See
[STREAMING_GUIDE.md](STREAMING_GUIDE.md) for the full WAN sequence this class implements, and
its "Reconnect and failure semantics" section for a known, unresolved gap in how the app
recovers from a camera-initiated KVS producer restart mid-session.

**Fixed 2026-08-14**: `getCloudStreamingStatus()` was the one method on this class missing the
`try`/`catch` its three siblings all had — `IotCommandClient.sendCommandWithResponse()` throws
on a genuine relay/network failure, and with nothing to catch it here that exception propagated
straight out past every caller's `CameraResult` switch, crashing on a plain transient network
failure (found by the mobile app team on a real device as an uncaught `SocketException`). Fixed,
and the constructor now accepts `iotCommandClient`/`kvsPlaybackClient` overrides (matching every
other `Wan*Client` in this package) — it previously had no way to inject a fake client at all,
which is why no test had ever exercised this class's real logic directly (every existing test
went through a hand-written fake of the `WanLiveViewClient` *interface* instead). See
`test/aws_wan_live_view_client_test.dart` for the new coverage.

### WanAudioVolumeClient

`wan/wan_audio_volume_client.dart` — WAN counterpart to `AudioVolumeClient`'s mic-gain,
recording-toggle, and test-sound half. **Recording on/off (`isAudioRecordingEnabled`/
`setAudioRecordingEnabled`) was previously undocumented as WAN-capable and unwired in the app
— the firmware command (`FR-NE-078`) had been `Implemented` and hardware-verified since
2026-07-28; wired into this client and `LiveViewScreen` 2026-08-11.**

```dart
WanAudioVolumeClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getMicGain` | `{Duration timeout}` | `CameraResult<int>` | Current mic gain. |
| `setMicGain` | `int gain, {Duration timeout}` | `CameraResult<void>` | Sets mic gain. |
| `isAudioRecordingEnabled` | `{Duration timeout}` | `CameraResult<bool>` | Whether the mic is actively capturing at all. |
| `setAudioRecordingEnabled` | `bool enabled, {Duration timeout}` | `CameraResult<void>` | Toggles mic recording. |
| `playTestSound` | `{Duration timeout}` | `CameraResult<void>` | Plays the speaker test tone. |
| `stopTestSound` | `{Duration timeout}` | `CameraResult<void>` | Stops it. |
| `isTestSoundPlaying` | `{Duration timeout}` | `CameraResult<bool>` | Whether the test tone is still playing. |

### WanSpeakerVolumeClient

`wan/wan_speaker_volume_client.dart` — WAN counterpart to `SpeakerVolumeClient`. Returns a bare
`int` (not the ONVIF-shaped `SpeakerVolume` struct, since the WAN command has no
token/name/outputToken sibling fields to echo).

```dart
WanSpeakerVolumeClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getSpeakerVolume` | `{Duration timeout}` | `CameraResult<int>` | Current output volume (0-100). |
| `setSpeakerVolume` | `int volume, {Duration timeout}` | `CameraResult<void>` | Sets output volume. |

### WanDeviceIdentityClient

`wan/wan_device_identity_client.dart` — WAN counterpart to `OnvifDeviceClient`'s name/location/
time-zone/password setters, plus reboot/factory-reset. Not a formal shared interface with
`OnvifDeviceClient`, but structurally matching signatures so a call site can pick either.

```dart
WanDeviceIdentityClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getDeviceIdentity` | `{Duration timeout}` | `CameraResult<({String name, String location, String timezone})>` | All three fields in one combined WAN read. |
| `setDeviceName` | `String name, {Duration timeout}` | `CameraResult<void>` | Sets display name. |
| `setDeviceLocation` | `String location, {Duration timeout}` | `CameraResult<void>` | Sets location. |
| `setTimeZone` | `String tz, {Duration timeout}` | `CameraResult<void>` | Sets time zone. |
| `setUserPassword` | `String username, String newPassword, {Duration timeout}` | `CameraResult<void>` | Same single-account-slot semantics as the LAN client — **caller must update `CameraConnection.password` on success.** |
| `reboot` | `{Duration timeout}` | `CameraResult<void>` | WAN mirror of `OnvifDeviceClient.reboot` — no WAN transport exists for ONVIF SOAP, so this is the only way a WAN-only client can reboot the camera. |
| `factoryReset` | `FactoryResetMode mode, {Duration timeout}` | `CameraResult<void>` | WAN mirror of `OnvifDeviceClient.factoryReset` — **the camera reboots automatically afterward**, same as the LAN client. **A Hard reset issued over WAN wipes the WiFi credentials that WAN connectivity itself depends on** — the one path that reliably severs the app's own ability to reach this camera again until it's re-onboarded on LAN; warn the user accordingly. |

### WanImageQualityClient

`wan/wan_image_quality_client.dart` — WAN counterpart to `OnvifImagingClient`'s ISP image-quality
fields (brightness/contrast/saturation/sharpness/white-balance/exposure).

```dart
WanImageQualityClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getImageSettings` | `{Duration timeout}` | `CameraResult<Map<String, dynamic>>` | Current image-quality field values, as a raw JSON map. |
| `setImageSettings` | `Map<String, dynamic> params, {Duration timeout}` | `CameraResult<Map<String, dynamic>>` | Applies given fields. |
| `getImageSettingsOptions` | `{Duration timeout}` | `CameraResult<Map<String, dynamic>>` | Bounds for the fields above. |
| `getImageDefaults` | `{Duration timeout}` | `CameraResult<Map<String, dynamic>>` | Factory-default values — the "Reset to Default" source. |

### WanImagingClient

`wan/wan_imaging_client.dart` — WAN counterpart to `OnvifImagingClient`'s Day/Night and WDR
fields. Mirror/Flip and ISP image quality are out of scope here (see `WanMirrorFlipClient`/
`WanImageQualityClient`).

```dart
WanImagingClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getDayNightMode` | `{Duration timeout}` | `CameraResult<String>` | Configured mode, translated to the `ON`/`OFF`/`AUTO` vocabulary the LAN/ONVIF side uses (the wire protocol itself uses lowercase `day`/`night`/`auto`). |
| `getEffectiveDayMode` | `{Duration timeout}` | `CameraResult<bool>` | Live effective state (`true` = day) — initial value only; live updates come via a separate alert-hub mechanism the app layer owns. |
| `getVideoModeStatus` | `{Duration timeout}` | `CameraResult<({String configuredMode, bool isDayMode})>` | Combined configured+effective read in one round trip. `configuredMode` is untranslated (raw `day`/`night`/`auto`). |
| `setDayNightMode` | `String onvifMode, {Duration timeout}` | `CameraResult<void>` | Accepts `ON`/`OFF`/`AUTO`, translates internally. |
| `getWdr` | `{Duration timeout}` | `CameraResult<({bool enabled, double level})>` | Current WDR state. |
| `setWdr` | `bool enabled, double level, {Duration timeout}` | `CameraResult<void>` | Sets WDR state. |
| `getImagingOptions` | `{Duration timeout}` | `CameraResult<({List<String> dayNightModes, bool wdrSupported})>` | Day/Night choice list (`ON`/`OFF`/`AUTO` vocabulary) and WDR support flag. |

`thingName` is exposed as a public field so callers can filter a shared WAN alert stream down to
this specific camera.

### WanMaskClient

`wan/wan_mask_client.dart` — WAN counterpart to `MaskClient`. Reuses `MaskEntry`/`MaskColor`/
`MaskOptions`/`OnvifPoint` from the LAN side so callers work with identical types regardless of
transport.

```dart
WanMaskClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getMasks` | `{Duration timeout}` | `CameraResult<List<MaskEntry>>` | Currently-configured masks. |
| `getMaskOptions` | `{Duration timeout}` | `CameraResult<MaskOptions>` | Mask capability envelope. |
| `setMask` | `{String token = '', required List<OnvifPoint> polygon, required bool enabled, required String type, MaskColor? color, Duration timeout}` | `CameraResult<String>` | Empty/omitted `token` creates a new mask; non-empty updates an existing one. Returns the applied token. |
| `deleteMask` | `String token, {Duration timeout}` | `CameraResult<void>` | Removes a mask. |

### WanMirrorFlipClient

`wan/wan_mirror_flip_client.dart` — WAN counterpart to `MirrorFlipClient`. Same `MirrorFlipMode`
enum as LAN.

```dart
WanMirrorFlipClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getMirrorFlip` | `{Duration timeout}` | `CameraResult<MirrorFlipMode>` | Current mode. |
| `setMirrorFlip` | `MirrorFlipMode mode, {Duration timeout}` | `CameraResult<void>` | Sets mode. |

### WanAntiFlickerClient

`wan/wan_anti_flicker_client.dart` — WAN counterpart to `AntiFlickerClient`. Same
`AntiFlickerMode` enum as LAN.

```dart
WanAntiFlickerClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getAntiFlickerMode` | `{Duration timeout}` | `CameraResult<AntiFlickerMode>` | Current mode. |
| `setAntiFlickerMode` | `AntiFlickerMode mode, {Duration timeout}` | `CameraResult<void>` | Sets mode. |

### WanEventPreferencesClient

`wan/wan_event_preferences_client.dart` — WAN counterpart to `EventPreferencesClient`. Same
wire vocabulary and partial-update semantics as LAN. No WAN "supported types" command — see
`CapabilitiesClient.supportedEventTypes`, LAN-only.

```dart
WanEventPreferencesClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getEventPreferences` | `{Duration timeout}` | `CameraResult<Map<String, bool>>` | Current enabled/disabled state. |
| `setEventPreferences` | `Map<String, bool> changes, {Duration timeout}` | `CameraResult<void>` | Partial update — same semantics as the LAN client. |

### WanEventResponseActionsClient

`wan/wan_event_response_actions_client.dart` — WAN counterpart to `EventResponseActionsClient`.
Same wire vocabulary and partial-update semantics as LAN. No WAN "supported deterrence options"
command — see `CapabilitiesClient.supportedEventDeterrenceOptions`, LAN-only.

```dart
WanEventResponseActionsClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getEventResponseActions` | `{Duration timeout}` | `CameraResult<Map<String, List<String>>>` | Current selected response actions per detection event type. |
| `setEventResponseActions` | `Map<String, List<String>> changes, {Duration timeout}` | `CameraResult<void>` | Partial update — same semantics as the LAN client. |

### WanDeterrenceClient

`wan/wan_deterrence_client.dart` — WAN counterpart to `DeterrenceClient`. Same wire vocabulary
and "no duration parameter on activate" behavior as LAN (`FEAT-236`). No WAN "capabilities"
command — see `CapabilitiesClient.sirenCapable`/`spotlightCapable`/`warningCapable`, LAN-only.

```dart
WanDeterrenceClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getDeterrenceStatus` | `{Duration timeout}` | `CameraResult<DeterrenceStatus>` | Each deterrence action's own independent active/inactive state — same shape as `DeterrenceClient.getDeterrenceStatus`, see there. |
| `activateDeterrence` | `String action, {Duration timeout}` | `CameraResult<void>` | No duration parameter — the camera applies its own persisted duration. |
| `deactivateDeterrence` | `String action, {Duration timeout}` | `CameraResult<void>` | Stops immediately. |
| `getDeterrenceDurations` | `{Duration timeout}` | `CameraResult<Map<String, int>>` | Current configured auto-stop value per action. |
| `setDeterrenceDurations` | `Map<String, int> changes, {Duration timeout}` | `CameraResult<void>` | Partial update — same semantics as the LAN client. |
| `getDeterrenceDurationOptions` | `{Duration timeout}` | `CameraResult<DeterrenceDurationOptions>` | Camera-reported valid range per key — same semantics as the LAN client. |

### WanNightVisionClient

`wan/wan_night_vision_client.dart` — WAN counterpart to `NightVisionClient`, also implementing
`NightVisionSource`.

```dart
class WanNightVisionClient implements NightVisionSource {
  WanNightVisionClient(String thingName, {IotCommandClient? iotCommandClient})
}
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getNightVisionType` | `{Duration timeout}` | `CameraResult<NightVisionStatus>` | Same response shape as the LAN client. |
| `setNightVisionType` | `NightVisionType type, {Duration timeout}` | `CameraResult<void>` | Sets night-vision type. |

### WanOsdClient

`wan/wan_osd_client.dart` — WAN counterpart to `OsdClient`. Reuses `OsdEntry`/`OsdColor`/
`OsdOptions` from the LAN side. Scoped to the same two OSD text-string types `OsdClient` models
(`Plain`, `DateAndTime`).

```dart
WanOsdClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getOsds` | `{Duration timeout}` | `CameraResult<List<OsdEntry>>` | Currently-configured OSD entries. |
| `getOsdOptions` | `{Duration timeout}` | `CameraResult<OsdOptions>` | OSD capability envelope. |
| `setOsd` | `{String token = '', required String textType, String? text, String posType = 'Custom', double? posX, double? posY, String? dateFormat, String? timeFormat, OsdColor? fontColor, Duration timeout}` | `CameraResult<String>` | Empty/omitted `token` creates a new OSD of `textType`; non-empty updates an existing one. Returns the applied token. |
| `deleteOsd` | `String token, {Duration timeout}` | `CameraResult<void>` | Removes an OSD entry. |

### WanPrivacyModeClient

`wan/wan_privacy_mode_client.dart` — WAN counterpart to `PrivacyModeClient`. Same `PrivacyMode`
enum as LAN.

```dart
WanPrivacyModeClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getPrivacyMode` | `{Duration timeout}` | `CameraResult<PrivacyMode>` | Current mode. |
| `setPrivacyMode` | `PrivacyMode mode, {Duration timeout}` | `CameraResult<void>` | Sets mode. |

### WanVideoEncoderClient

`wan/wan_video_encoder_client.dart` — WAN counterpart to `OnvifVideoEncoderClient`. Structurally
matching methods, not a formal shared interface.

```dart
WanVideoEncoderClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getVideoEncoderSettings` | `{Duration timeout}` | `CameraResult<VideoEncoderSettings>` | Current encoder settings. |
| `setVideoEncoderSettings` | `VideoEncoderSettings settings, {Duration timeout}` | `CameraResult<VideoEncoderSettings>` | Applies every field in `settings` (no partial-update reason to diff, since callers always hold the full loaded+edited struct). Returns the actual applied (post-clamp) values. |
| `getVideoEncoderSettingsOptions` | `{Duration timeout}` | `CameraResult<VideoEncoderSettingsOptions>` | Per-encoding bounds/choices. **Per this project's UX convention, WAN Options should only ever be fetched as a recovery step immediately after a WAN Set failure** — normal loads use LAN Options only; this client itself does not enforce that, the call site must. |

### WanPreviewSnapshotClient

`wan/wan_preview_snapshot_client.dart` — end-to-end-encrypted WAN reference-snapshot preview,
distinct from the persisted WAN snapshot mechanism. The camera encrypts the frame before it
leaves the device (RSA-2048-OAEP-wrapped AES key + AES-GCM payload); this client is the only
place that ever holds the plaintext again, after decrypting locally with the device's own stored
private key (`WanAuth.previewPrivateKeyProvider`).

```dart
WanPreviewSnapshotClient(String thingName, {IotCommandClient? iotCommandClient})
```

| Method | Params | Returns | Description |
|---|---|---|---|
| `getPreviewSnapshot` | `{Duration timeout = 25s}` | `CameraResult<Uint8List>` | Fetches, decrypts, and returns one preview frame. Returns `CameraFailure` if no local key is registered yet (open a settings screen on LAN once first) — and, if the camera itself reports its registered key is gone, calls `WanAuth.onPreviewKeyNeedsRegistration` as a side effect. |

**Callers must not persist the returned bytes** (no gallery save, no cache file) — this is a
transient configuration-screen backdrop, not a kept/shared snapshot.

---

## Shared types

These live at the package root (`src/`) rather than under `lan/` or `wan/`, because both a LAN
and a WAN client pair share them:

- **`mirror_flip_types.dart`** — `enum MirrorFlipMode { off, mirror, flip, both }` plus
  `MirrorFlipModeWire` extension (`.wireValue` getter, `.fromWire(String)` static parser). Shared
  by `MirrorFlipClient`/`WanMirrorFlipClient`.
- **`anti_flicker_types.dart`** — `enum AntiFlickerMode { hz50, hz60, auto }` plus
  `AntiFlickerModeWire` extension (`.wireValue` getter, `.fromWire(String)` static parser).
  Shared by `AntiFlickerClient`/`WanAntiFlickerClient`.
- **`night_vision_types.dart`** — `enum NightVisionType { grey, color, smart }`,
  `NightVisionTypeWire` extension, `NightVisionStatus` (value-equality class: `type`,
  `colorCapable`, `smartCapable`, `subState`), and the `NightVisionSource` abstract interface
  (`getNightVisionType`/`setNightVisionType`) both `NightVisionClient` and `WanNightVisionClient`
  implement — lets UI code hold either behind one reference type.
- **`privacy_mode_types.dart`** — `enum PrivacyMode { none, zone, full }` plus `PrivacyModeWire`
  extension. Shared by `PrivacyModeClient`/`WanPrivacyModeClient`.
- **`device_reset_types.dart`** — `enum FactoryResetMode { soft, hard }` plus
  `FactoryResetModeWire` extension (`.wireValue` getter — `"Soft"`/`"Hard"`, the literal ONVIF
  `FactoryDefault` type values). **Soft** erases camera settings only, network config preserved
  (device stays reachable); **Hard** also erases network config, forcing the device back into AP
  provisioning mode. Shared by `OnvifDeviceClient.factoryReset`/
  `WanDeviceIdentityClient.factoryReset`. Unlike the other shared types above, this is a real
  ONVIF-standard type, not a NuraEye-only one — it lives here only because both a LAN and WAN
  client need it.
- **`util/onvif_rect_coordinates.dart`** — pixel-space ↔ ONVIF-normalized-coordinate conversion,
  used by the mask editor and OSD position drag:
  - `OnvifPoint(x, y)` — a single ONVIF point, each axis in `[-1, 1]`, Y increasing upward.
  - `PixelRect`/`PixelSize`/`PixelPoint` — pixel-space stand-ins for `dart:ui`'s `Rect`/`Size`/
    `Offset` (unavailable in this Flutter-free package).
  - `pixelRectToOnvifPolygon(PixelRect, PixelSize)` → `List<OnvifPoint>` — converts a pixel
    rectangle (top-left origin) into a clamped 4-point ONVIF polygon (top-left, top-right,
    bottom-right, bottom-left order).
  - `onvifPolygonToPixelRect(List<OnvifPoint>, PixelSize)` → `PixelRect` — the inverse, via
    bounding box (this firmware's masks are hardware rectangles regardless of point count).
  - `pixelPointToOnvifPos(PixelPoint, PixelSize)` → `OnvifPoint` / `onvifPosToPixelPoint(...)` →
    `PixelPoint` — single-point conversions for OSD placement.

Two other small shared pieces worth knowing about even though they aren't "types" in the same
sense:

- **`lan/wsse_digest.dart`**'s `WsseDigest` — the shared WSSE-style SHA-1 digest construction
  used identically by `NuraeyeClient`'s REST login, every ONVIF SOAP client's
  `WS-UsernameToken` header, and `SnapshotClient`'s `Authorization` header. `WsseDigest.generate
  (password)` produces a fresh nonce/timestamp/digest triple; `WsseDigest.computeDigest(...)` lets
  a caller (e.g. `areYouNuraeyeDevice`) recompute a digest for a known nonce/timestamp to verify
  a server-supplied reply.
- **`lan/insecure_camera_http_client.dart`**'s `createCameraHttpClient()` — the shared
  `package:http`-compatible client factory every LAN ONVIF/NuraEye client (except
  `SnapshotClient`, which uses `dart:io` directly for the same header-case reason) uses under the
  hood. Trusts the camera's self-signed TLS certificate (deliberately narrow: only for camera LAN
  connections) and preserves outgoing HTTP header name case, which the camera's embedded server
  requires.

---

## Getting started

A minimal example: connect to a camera on the LAN, read its display name via ONVIF, and handle
the result.

```dart
import 'package:camera_api/camera_api.dart';

Future<void> main() async {
  final connection = CameraConnection(
    host: '192.168.1.50',
    username: 'admin',
    password: 'changeme',
  );

  final device = OnvifDeviceClient(connection);
  try {
    final result = await device.getDeviceIdentity();
    switch (result) {
      case CameraSuccess(:final value):
        print('Camera name: ${value.name}, location: ${value.location}');
      case CameraFailure(:final reason):
        print('Camera rejected the request: $reason');
      case CameraTimeout():
        print('Camera did not respond in time — check network/credentials.');
    }
  } finally {
    device.close();
  }
}
```

A WAN example additionally requires setting `WanAuth`'s hooks once at app startup, before any
WAN client is used:

```dart
void configureWan() {
  WanAuth.idTokenProvider = () => currentCognitoIdToken; // your own auth state — see auth_api
  // This project's real, live deployed relay (VizenLinkKvsPlaybackProxy, confirmed live
  // 2026-08-12) — not a placeholder. Overridable via --dart-define=KVS_PLAYBACK_LAMBDA_URL=...
  // if this Lambda is ever redeployed at a new Function URL.
  WanAuth.kvsPlaybackLambdaUrl = 'https://jxce73jfkwoouhcmxvhsoysxxq0gavso.lambda-url.ap-south-1.on.aws/';
}

Future<void> readMirrorFlipOverWan(String thingName) async {
  final wan = WanMirrorFlipClient(thingName);
  final result = await wan.getMirrorFlip();
  switch (result) {
    case CameraSuccess(:final value):
      print('Mirror/flip mode: $value');
    case CameraFailure(:final reason):
      print('Rejected: $reason');
    case CameraTimeout():
      print('No response from camera over WAN.');
  }
}
```

Every client exposes a `close()` method (where it owns network resources) — call it when done
with a short-lived client instance, though most app code constructs clients per-call and lets
them be garbage-collected, since the expensive state (bearer sessions, resolved endpoints,
Options caches) is cached at the `static`/process level, not on the instance itself.
