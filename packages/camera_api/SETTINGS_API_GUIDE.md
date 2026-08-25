# camera_api — Settings API Guide

`API_REFERENCE.md` is organized by **client class** — one section per Dart class, with its
methods, params, and return types. It has no concept of "camera setting" as a unit; a single
setting can be read/written through more than one client (LAN vs WAN, or occasionally more than
one LAN action), and `API_REFERENCE.md` won't tell you that up front.

This file is organized the other way: by **camera setting**. For each one it names the correct
LAN and WAN client/method pair, and — this is the part `API_REFERENCE.md` structurally can't
give you — explicitly separates it from other settings that sound alike or that expose a
similar-looking value. Use this file first when you know *which setting* you're implementing but
not yet *which client*; use `API_REFERENCE.md` once you know the client and need its exact
signature.

**Why this file exists:** Day/Night mode and Night Vision Type were confused with each other
during development — both are "night-related camera settings," both have a `grey`/`color`-ish
or `on`/`off`/`auto`-ish flavor to their values, and Day/Night mode alone is reachable through
two differently-named wire actions (ONVIF `IrCutFilter` and NuraEye `GetVideoMode`) that are
*not* obvious from either name alone as being the same underlying camera value. See that section
below for the actual resolution.

This is a **living reference** — add a section here whenever a new setting is wired up, not just
when a mix-up happens.

## How to read each entry

- **Concept** — what the setting actually controls on the camera, in plain language.
- **Not to be confused with** — other settings in this package whose name, values, or screen
  proximity make them easy to reach for by mistake.
- **LAN** — the client + method to call when connected on the same network as the camera.
- **WAN** — the client + method for the AWS IoT relay path, or "none" if no WAN path exists.
- **Notes** — caching behavior, wire-format quirks, or anything that would surprise you mid-way
  through wiring the call up.

For the general LAN-vs-WAN transport-selection algorithm (try LAN, fall back to WAN, when to
re-fetch Options) and the Options-caching convention, see
[.claude/rules/mobile-app-screen-conventions.md](../../../.claude/rules/mobile-app-screen-conventions.md) — this file cross-references
those rules per setting rather than repeating them.

---

## Day/Night Mode (IR Cut Filter)

**Concept:** whether the camera's IR-cut filter is forced on (day/color mode), forced off
(night/IR mode), or automatically switched based on ambient light (`AUTO`/`ON`/`OFF`). This is
the setting ONVIF calls `IrCutFilter`.

**Not to be confused with:** [Night Vision Type](#night-vision-type) — a completely separate
setting (grey/color/smart night-time rendering) that does not derive from or drive this one; see
that section for the full distinction. Also not to be confused with the *live effective* state
(is it day or night *right now*) versus the *configured* mode (`AUTO`/`ON`/`OFF`) — both are
read together but are different fields (see Notes).

**LAN:**
- Configured mode: `OnvifImagingClient.getImagingSettings()` → `ImagingSettings.irCutFilterMode`
  (`AUTO`/`ON`/`OFF`); set via `setImagingSettings(...)`.
- Live effective state (is it day or night right now): `NuraeyeClient.call('GetVideoMode')` →
  `effective_state` (bool, `true` = day).
- Options/choice list: `OnvifImagingClient.getImagingOptions()` →
  `ImagingOptions.irCutFilterModes`.

**WAN:** `WanImagingClient` — `getDayNightMode()` (configured mode, translated to the ONVIF
`ON`/`OFF`/`AUTO` vocabulary), `getEffectiveDayMode()` (live state), `getVideoModeStatus()`
(both in one round trip), `setDayNightMode(onvifMode)`. `getImagingOptions()` for the choice
list + WDR support flag.

**Notes:**
- ONVIF's `IrCutFilter` field and NuraEye's `GetVideoMode`/`SetVideoMode` action are **the same
  underlying camera concept exposed via two wire vocabularies** — NuraEye's wire values are
  lowercase `day`/`night`/`auto`; ONVIF's are `ON`/`OFF`/`AUTO`. `WanImagingClient` translates
  between them at its own boundary so app code only ever sees the ONVIF vocabulary regardless of
  transport. There is no case where you need both `OnvifImagingClient` and a raw `GetVideoMode`
  call for the *configured* mode — `GetVideoMode` is used on LAN specifically because it's the
  only place the *live effective* `day`/`night` state (not just the configured mode) is exposed;
  `OnvifImagingClient` has no effective-state field.
- `getImagingOptions()` (both transports) is process-lifetime cached per host — see the caching
  convention in `.claude/rules/mobile-app-screen-conventions.md`.
- `ImagingOptions.irCutFilterModes` is the actual choice list for this mode — if it's empty,
  there's nothing valid to offer (see the
  [capability-flags table](#per-setting-options-response-capability-flags--not-the-same-idea-as-the-two-above)).

## Night Vision Type

**Concept:** how the camera renders video once it's in night mode — plain grey/IR (`grey`),
forced color at night (`color`), or an automatic choice between the two based on scene
conditions (`smart`).

**Not to be confused with:** [Day/Night Mode](#daynight-mode-ir-cut-filter) above. These are
independently configurable — a camera can be in `AUTO` day/night mode while its night-vision
rendering is set to `smart`, or `ON` (forced night) with `grey` rendering, in any combination.
Day/Night mode decides *whether* the IR-cut filter is engaged; Night Vision Type decides *how
the image looks* once it is. Nothing in either wire protocol links the two values together.

**LAN:** `NightVisionClient.getNightVisionType()` / `.setNightVisionType(type)` — implements the
shared `NightVisionSource` interface.

**WAN:** `WanNightVisionClient` — same method names, same `NightVisionSource` interface, so UI
code can hold either behind one reference type without branching on transport.

**Notes:** `NightVisionStatus` carries `colorCapable`/`smartCapable` hardware/firmware support
flags, returned embedded in the status response itself (no separate Options call needed) — gate
the UI's available choices on those, not on assuming all three types are always selectable. The
REST-generated surface (`GetCapabilitiesResponse.nightVisionColorCapable`/
`.nightVisionSmartCapable`, unused today) duplicates the same two flags — prefer
`NightVisionStatus`'s copy, it's the one actually wired into the app.

## WDR (Wide Dynamic Range)

**Concept:** whether the sensor's wide-dynamic-range compensation is enabled, and its strength
level — helps with strong backlight/high-contrast scenes. Bundled into the same ONVIF
`GetImagingSettings`/`GetImagingOptions` call as Day/Night mode, but is a separate field.

**Not to be confused with:** general [Image Quality](#image-quality) (brightness/contrast/
saturation/sharpness) — WDR is a distinct sensor-level compensation mode, not one of the
standard ISP quality sliders, even though both live under "Imaging."

**LAN:** `OnvifImagingClient.getImagingSettings()`/`setImagingSettings()` (WDR fields), options
via `getImagingOptions()` → `ImagingOptions.wdrSupported`.

**WAN:** `WanImagingClient.getWdr()`/`setWdr(enabled, level)`.

**Notes:** `ImagingOptions.wdrSupported == false` means the WDR element was entirely absent from
the response (non-HDR sensor) — hide the control outright, don't just disable it. WDR support
must be read from `getImagingOptions()`'s own `wdrSupported` flag, never inferred from whether
`GetImagingSettings` happens to include the field. See
[Per-setting Options-response capability flags](#per-setting-options-response-capability-flags--not-the-same-idea-as-the-two-above)
for the WAN mirror of this same flag.

**Also the HDR/Linear sensor capture-mode switch (`FR-CF-147`).** On the two HDR-capable
sensors (IMX662, GC4663), the WDR On/Off field this section already covers **is** the sensor
capture-mode switch — not a separate control. The sensor's own dual-exposure readout
(`init_hdr_mode`) is boot-time-only with no live re-init path, so an actual WDR On<->Off
transition reboots the camera to take effect; the health-monitor task detects the
booted-vs-persisted mismatch and triggers the reboot (not the request path itself). WDR
*Level* is unaffected by this — it's still a pure runtime blend-strength control within
whichever mode is active. **UI must confirm before toggling WDR on a camera where
`wdrSupported` is true** — it may trigger a reboot, briefly interrupting live view/recording.
Mirrors the deterrence confirmation-gate pattern (`FR-MOB-105`). See
`imaging_settings_screen.dart`'s `_WdrCard` for the reference implementation.

## Image Quality

**Concept:** the standard ISP sliders — brightness, saturation, contrast, sharpness, exposure
mode/time/gain, white-balance mode.

**Not to be confused with:** [Image Defaults](#image-defaults-factory-reset-values) — the
factory-default *values* for these same fields, a read-only reference used for a "Reset to
Default" action, not the current live settings.

**LAN:** `OnvifImagingClient.getImagingSettings()`/`setImagingSettings()` (the non-Day/Night,
non-WDR fields), options via `getImagingOptions()`.

**WAN:** `WanImageQualityClient` — `getImageSettings()`/`setImageSettings(params)` (raw JSON
maps, not a typed struct), `getImageSettingsOptions()`.

## Image Defaults (factory-reset values)

**Concept:** the camera's factory-default values for the Image Quality fields above — read-only,
used to populate a "Reset to Default" action. Not itself a setting you can change.

**Not to be confused with:** [Image Quality](#image-quality) — the current, mutable values.

**LAN:** `NuraeyeClient.call('GetImageDefaults')`, or the generated `RestVideoImageClient` if
using the OpenAPI-generated surface directly.

**WAN:** `WanImageQualityClient.getImageDefaults()`.

## Mirror/Flip

**Concept:** horizontal mirror / vertical flip of the video output — `off`/`mirror`/`flip`/
`both`. This is a NuraEye-only setting; there is no ONVIF `MirrorFlipMode` concept on this
firmware (removed 2026-07-27, `FR-CF-129`/`FR-NE-039`) — don't look for or add an ONVIF Options
call for it, there is no camera-reported choice list to derive it from.

**LAN:** `MirrorFlipClient.getMirrorFlip()`/`.setMirrorFlip(mode)` (hand-written — prefer this
over the generated `RestVideoImageClient`, which hits the identical `/nuraeye/video/mirror-flip`
endpoint but exists only as unused reserve API surface, see
[Hand-written vs. generated REST clients](#hand-written-vs-generated-rest-clients) below).

**WAN:** `WanMirrorFlipClient` — same `MirrorFlipMode` enum, same method names.

## Anti-Flicker / Power-Line Frequency

**Concept:** eliminates video banding/flicker caused by artificial (mains-powered) lighting —
`50Hz`/`60Hz`/`Auto`. This is a NuraEye-only setting; there is no ONVIF-standard element for it
on any camera, not just this firmware — checked against the live `ImagingSettings20` schema and
confirmed no such field exists anywhere in it, including its Extension chain (see
`kb/raw/2026-08-12-feature-antiflicker-mode.md`). Same situation as [Mirror/Flip](#mirrorflip)
above — don't look for or add an ONVIF Options call for it.

**LAN:** `AntiFlickerClient.getAntiFlickerMode()`/`.setAntiFlickerMode(mode)` — REST-only, no
legacy `/nuraeye` JSON-RPC action exists for this setting (built REST-only from day one).

**WAN:** `WanAntiFlickerClient` — same `AntiFlickerMode` enum, same method names.

## Privacy Mode

**Concept:** a device-wide capture state — `none` (normal), `zone` (blank out configured mask
zones), `full` (stop all capture).

**Not to be confused with:** [Privacy Masks](#privacy-masks) — the actual rectangle zones that
`zone` mode blanks out. Privacy Mode is the on/off/which-scope switch; Privacy Masks is the
geometry it operates on. Setting Privacy Mode to `zone` with no masks configured is a valid but
probably-unintended no-op.

**LAN:** `PrivacyModeClient.getPrivacyMode()`/`.setPrivacyMode(mode)` (hand-written — prefer over
the generated `RestPrivacyClient`, same endpoint, see
[Hand-written vs. generated REST clients](#hand-written-vs-generated-rest-clients)).

**WAN:** `WanPrivacyModeClient` — same `PrivacyMode` enum.

## Privacy Masks

**Concept:** the actual rectangular zones (position, enabled flag, type, color) that Privacy
Mode's `zone` setting blanks out. Managed via ONVIF Media2 mask primitives
(`CreateMask`/`SetMask`/`DeleteMask`/`GetMasks`).

**Not to be confused with:** [Privacy Mode](#privacy-mode) above — the switch, not the geometry.
Also not to be confused with [OSD](#osd-on-screen-display) — both are Media2 "draw something on
the video" primitives with a similar create/set/delete/options shape, but OSD draws
timestamp/text overlays, masks draw opaque privacy rectangles; they are unrelated ONVIF
resources with separate token spaces.

**LAN:** `MaskClient` — `getMasks()`, `createMask(...)`/`setMask(...)`/`deleteMask(token)`,
`getMaskOptions()`.

**WAN:** `WanMaskClient` — same `MaskEntry`/`MaskColor`/`MaskOptions`/`OnvifPoint` types as LAN,
so app code doesn't need transport-specific geometry conversion.

**Notes:** `GetMaskOptions`/`WanMaskClient.getMaskOptions()` is process-lifetime cached per host
— see `.claude/rules/mobile-app-screen-conventions.md`'s caching convention; this is the setting that originally
motivated that rule (redundant re-fetches were starving the camera's RTSP pipeline).
`MaskEntry.type` only `"Color"` actually renders on this firmware — gate UI on
`MaskOptions.types`, don't assume all ONVIF-advertised types work. Two more gates apply before
even reaching `MaskOptions`: `Media2CapabilitiesClient.getServiceCapabilities().maskSupported`
(does this camera build advertise masks at all) and, within `MaskOptions` itself,
`rectangleOnly`/`singleColorOnly` (shape/color-picker freedom) plus `maxMasks == 0` as the
fallback-value signal for "not supported" — see the
[capability-flags table](#per-setting-options-response-capability-flags--not-the-same-idea-as-the-two-above).

## OSD (On-Screen Display)

**Concept:** timestamp overlay and free-text overlay burned into the video. ONVIF Media2
(`GetOSDs`/`CreateOSD`/`SetOSD`/`DeleteOSD`/`GetOSDOptions`), two fixed slots (`DateAndTime`,
`Plain`).

**Not to be confused with:** [Privacy Masks](#privacy-masks) — see that section's note; same
ONVIF Media2 shape, unrelated resource.

**LAN:** `OsdClient` — `getOsds()`, `createTimestampOsd(...)`/`createTextOsd(...)`/
`updateTextOsd(...)`/`updateTimestampPosition(...)`/`deleteOsd(token)`, `getOsdOptions()`.

**WAN:** `WanOsdClient` — `setOsd(...)` unifies create/update behind one method (empty/omitted
`token` creates, non-empty updates), otherwise mirrors the LAN shape.

**Notes:** neither transport is hardware-verified against a real camera as of this writing — no
`testing_utilities/*.py` reference script exists for OSD; wire format was matched directly
against firmware source. Treat with extra suspicion if a bug report touches OSD. Two capability
gates apply: `Media2CapabilitiesClient.getServiceCapabilities().osdSupported` (device-wide), and
within `OsdOptions`, `fontColorRangeAvailable` — whether the camera reports a continuous RGB
range (slider UI) vs. only a discrete `fontColors` list; checking `fontColors.isNotEmpty` alone
previously left the color picker never rendering on builds that only advertise the range. See
the [capability-flags table](#per-setting-options-response-capability-flags--not-the-same-idea-as-the-two-above).

## Video Encoder Settings (Stream 0, high-res)

**Concept:** bitrate, frame rate, GOV length, quality, encoder profile, resolution, codec
(H264/H265), CBR/VBR — for the **high-resolution** stream (Stream 0, `VideoEncoderCfg_1`, the
one VMS/NVR and MP4 recording consume). ONVIF Media2
(`GetVideoEncoderConfigurations`/`SetVideoEncoderConfiguration`/
`GetVideoEncoderConfigurationOptions`).

**Not to be confused with:** the mobile app's own low-res live-view substream (Stream 1) quality
— there is a separate WAN-only `SetStreamQuality`/`GetStreamQuality`/`GetOptions` firmware
command set (`FR-NE-069`) for that, but **no mobile-app screen exists for it yet** — don't wire
a "video quality" control to `OnvifVideoEncoderClient`/`WanVideoEncoderClient` unless it's
genuinely about the Stream 0 high-res encoder; a mobile-app-facing "stream quality" ask more
likely means the not-yet-built Stream 1 screen.

**LAN:** `OnvifVideoEncoderClient` — `getVideoEncoderSettings()`, `setVideoEncoderSettings(...)`
(always sends the full config, no partial-update mode), `getVideoEncoderSettingsOptions()`.

**WAN:** `WanVideoEncoderClient` — same method names; `getVideoEncoderSettingsOptions()` should
only ever be called as WAN-Set-failure recovery, never on a normal load — see
[.claude/rules/mobile-app-screen-conventions.md](../../../.claude/rules/mobile-app-screen-conventions.md) § "LAN/WAN transport
selection."

**Notes:** `VideoEncoderSettingsOptions.resolutions` must be read from the live Options response
(`resolutions.length <= 1` decides label-vs-dropdown at render time) — never hardcode "this
firmware only has one resolution," even though that's true today. Separately, each
`EncodingOptions.supportsCbr` is a **per-encoding** flag (H264 and H265 can report differently)
— the CBR/VBR toggle is only editable when the *currently selected* encoding's own flag is
`true`, not a single device-wide bool; see the
[capability-flags table](#per-setting-options-response-capability-flags--not-the-same-idea-as-the-two-above).

## Device Identity (Name / Location / Time Zone / Password)

**Concept:** the camera's display name and location labels (ONVIF `Scopes`), its time zone, and
its single local device account password (shared by ONVIF + NuraEye login).

**LAN:** `OnvifDeviceClient` — `getDeviceIdentity()`, `setDeviceName(name)`/
`setDeviceLocation(location)` (independent calls — name and location are set separately),
`getSystemDateAndTime()`/`setTimeZone(tz)`, `setUserPassword(username, newPassword)`.

**WAN:** `WanDeviceIdentityClient` — `getDeviceIdentity()` (all three fields combined in one
read), `setDeviceName`/`setDeviceLocation`/`setTimeZone`/`setUserPassword`, structurally matching
signatures (not a formal shared interface).

**Notes:** the time-zone *catalog* to pick from (`TimezoneOption` list) is a **separate,
NuraEye-only** call — `NetworkInfoClient.getSupportedTimezones()` — even though the *setting* of
time zone itself is an ONVIF action (`OnvifDeviceClient.setTimeZone`/
`WanDeviceIdentityClient.setTimeZone`). `TimezoneOption.code` is the string to pass to the
ONVIF/WAN setter. On either transport, **the caller must update its own stored
`CameraConnection.password` after a successful `setUserPassword`** — the client that made the
call keeps using the old password it was constructed with.

## Device Information (read-only)

**Concept:** the camera's fixed build/hardware identity — manufacturer, model, firmware
version, serial number, hardware ID (ONVIF `GetDeviceInformation`). Read-only, no setter.

**Not to be confused with:** [Device Identity](#device-identity-name--location--time-zone--password)'s
name/location/time zone — those are user-configurable; this is fixed per-unit/build data.

**LAN:** `OnvifDeviceClient.getDeviceInformation()`.

**WAN:** `WanDeviceIdentityClient.getDeviceInfo()` (`FR-NE-115`, added 2026-08-21) — returns the
same `DeviceInformation` type as the LAN client.

**Notes:** `CameraInfoScreen`'s "Device Information" card shows the cached value instantly
(`CachedCameraSettings`, warmed at onboarding) and only makes a live call on a cache miss —
same convention as every other read-only card in this guide.

## Device Reboot / Factory Reset

**Concept:** rebooting the camera on demand (ONVIF `SystemReboot`), and resetting it to factory
defaults at one of two levels (ONVIF `SetSystemFactoryDefault`):
- **Soft** — erases camera settings (ONVIF user config: imaging, masks, OSD, camera name/
  location, etc.) only. Network config (WiFi credentials, DHCP preferred IP) is preserved, so
  the device stays reachable at its existing address after it reboots.
- **Hard** — erases camera settings **and** network config. The device re-enters AP
  provisioning mode on reboot and must be fully re-onboarded (WiFi credentials re-entered,
  discovery/manual add repeated) before it's reachable again.

Unlike most entries in this guide, both actions are **real, standard ONVIF Device service
actions** with a full LAN path — this isn't a NuraEye-only setting. The WAN command set exists
purely because ONVIF SOAP has no WAN transport in this stack at all (same reasoning as
[Device Identity](#device-identity-name--location--time-zone--password)'s WAN mirror), not
because the setting itself needed inventing.

**Not to be confused with:** [Image Defaults](#image-defaults-factory-reset-values) — that's a
read-only *ISP value* lookup for one "Reset to Default" slider control, not a device-wide reset.

**LAN:** `OnvifDeviceClient` — `reboot()` (returns the camera's `tt:Message`, typically
`"Rebooting in 5 seconds"`), `factoryReset(FactoryResetMode mode)`.

**WAN:** `WanDeviceIdentityClient` — `reboot()`, `factoryReset(FactoryResetMode mode)`, same
signatures as the LAN client.

**Notes:** a success response from either method does **not** mean the device is back yet — both
actions trigger `bsp_rebootAsync()` (~5s async delay before the actual reset), so callers must
expect a real connectivity gap afterward, not just an instant confirm. Neither method has an
Options/capability query — there's nothing to bound, both take a fixed enum or no params at all.
**UI: `_DeviceManagementCard` in `camera_info_screen.dart`** (`FR-MOB-103`) — a "Device
Management" card with two rows, each behind its own confirmation flow: Reboot shows one
plain-language confirmation dialog; Factory Reset first asks the user to pick Soft or Hard (a
`SimpleDialog` with per-mode explanatory subtitles), then shows a second, destructive-styled
confirmation whose wording matches whichever mode was picked. On a successful Hard reset the
screen pops itself — the network config the app just used to reach the camera no longer exists,
so nothing else on the screen can succeed until it's re-onboarded; Soft reset and Reboot instead
show a result dialog and leave the user on the screen, since the camera stays reachable at the
same address. A Hard reset issued over WAN is also the one path that severs the app's own
ability to reach the camera again over WAN, since it wipes the WiFi credentials that WAN
connectivity itself was reached through — recovery requires re-onboarding on LAN.

## Event Preferences

**Concept:** whether the camera generates a given event *type* at all, device-wide
(`FR-CF-143`, `FR-NE-111`) — a per-camera on/off switch per event type
(`"VideoModeChanged"`/`"PrivacyModeChanged"`/`"PersonDetected"` today), not a per-detection-rule
setting.

**Not to be confused with:** the per-analytics-rule `mobile_notifications`/`buzzer_activation`
flags reachable via `NuraeyeClient.call('...alert-rules...')` (no dedicated `camera_api` client
exists for those yet) — that's a different, pre-existing concept: what *action* a specific
detection *rule* triggers when it fires, not whether an event *type* is generated at all. A
"mute" request from a user is almost always this section, not that one. (Both are slated to be
superseded by `FR-CF-144`/`FR-NE-112`'s generalized per-event response-action set once built —
not yet implemented, see that FR's `Planned` status.)

**A real, device-side suppression, not a client-side mute.** Disabling a type here stops the
camera from generating it at the source (`EventMgr_Send()`), on **every** delivery path it has
— this app's own MQTT feed, and ONVIF PullPoint (third-party NVR/VMS clients too), per direct
user decision. There is deliberately no separate "client-side mute" concept layered on top of
this: an earlier draft of this feature considered one (log the event, but suppress only this
app's own push notification), but that was dropped as redundant once `FR-CF-144`'s `mobile_alert`
response action was scoped — an event with `mobile_alert` unselected already means "log it,
don't push a notification for it," with no additional toggle needed.

**LAN:** `EventPreferencesClient` — `getEventPreferences()`, `setEventPreferences(Map<String,
bool> changes)` (partial update — only the keys present in `changes` change).

**WAN:** `WanEventPreferencesClient` — same method names and partial-update semantics.

**Notes:** the list of event types to show toggles for comes from
`CapabilitiesClient.getCapabilities().supportedEventTypes`
([Capabilities](#capabilities-discovery-not-a-setting)), never a hardcoded list — a future
firmware build that adds a real producer for e.g. tamper detection needs zero `camera_api`
changes, the new type just appears in that array. An unrecognized key in `setEventPreferences`
is a `CameraFailure` (the camera rejects the whole request with `HTTP 400` rather than applying
a partial subset) — don't send a key that isn't currently in `supportedEventTypes`.

## Response Actions (Deterrence-on-Event)

**Concept:** for **detection-type events only** (`"PersonDetected"` today — never state-change
events like `"VideoModeChanged"`/`"PrivacyModeChanged"`), which automatic response actions
(`siren`, `spotlight`, `warning`, `mobile_alert`) fire when that event triggers
(`FR-CF-144`, `FR-NE-112`). A per-event-type multi-select, not a single choice — an event can
have zero, one, or several response actions selected at once.

**Not to be confused with:**
- `EventPreferencesClient` (above) — that controls whether the event is generated **at all**;
  this controls what happens *in addition* once an already-enabled detection event fires. An
  event with every response action unselected still generates normally (still logged, still
  delivered to alert history) — it just doesn't trigger anything extra.
- The per-detection-rule `mobile_notifications`/`buzzer_activation` toggles
  (`NuraeyeClient.call('...alert-rules...')`) — a narrower, pre-existing concept this
  generalizes for the event types it covers.
- The manual, on-demand `ActivateDeterrence`/`DeactivateDeterrence`/`GetDeterrenceStatus`
  actions (`DeterrenceClient`, see [Deterrence — Manual Trigger & Auto-Stop
  Duration](#deterrence--manual-trigger--auto-stop-duration) below) — those are a human pressing
  a button in Live View to fire an action right now; this is the camera auto-firing an action
  because a detection event just happened. **Both share the exact same configured auto-stop
  duration** (`FR-NE-113`, `FEAT-236`) — there is no separate "automatic" vs. "manual" duration
  value anymore.

**`mobile_alert` has no device-side effect at all.** Selecting/unselecting it never changes
whether the camera delivers the event — that's `EventPreferencesClient`'s job alone, and stays
true regardless of this setting. It exists purely so the app can read, locally, whether an
incoming alert for a given event type should also surface a system push notification. If a
future need arises for "log this event, but never push a notification for it," this is already
that mechanism — there's no separate client-side mute concept layered on top of it.

**LAN:** `EventResponseActionsClient` — `getEventResponseActions()`,
`setEventResponseActions(Map<String, List<String>> changes)` (partial update — only the event
types present in `changes` change; each key's array fully **replaces** that event type's action
set, not additive).

**WAN:** `WanEventResponseActionsClient` — same method names and partial-update semantics.

**Notes:** the map of event types to response-action choices comes from
`CapabilitiesClient.getCapabilities().supportedEventDeterrenceOptions`
([Capabilities](#capabilities-discovery-not-a-setting)), never a hardcoded list — and it's
already the intersection of this SKU's hardware capability (no `siren` option offered on a
build without a buzzer) with which event types are even eligible for a response action at all
(state-change events are simply absent as keys, not present with an empty array). Sending an
action not present in that event type's eligible list is a `CameraFailure` (`HTTP 400`, whole
request rejected).

## Audio — Mic Gain / Recording Toggle / Test Tone

**Concept:** microphone input gain level, whether the mic is actively capturing at all (distinct
from gain), and speaker test-tone playback control.

**Not to be confused with:** [Speaker Volume](#speaker-volume-output) — the camera's *output*
level, a separate ONVIF-only setting with no relation to mic gain beyond both involving audio
hardware.

**LAN:** `AudioVolumeClient` — `getMicGain()`/`setMicGain(gain)`,
`isAudioRecordingEnabled()`/`setAudioRecordingEnabled(enabled)`,
`playTestSound()`/`stopTestSound()`/`isTestSoundPlaying()`.

**WAN:** `WanAudioVolumeClient` — same method set. `isAudioRecordingEnabled`/
`setAudioRecordingEnabled` were undocumented-as-WAN-capable and unwired in the app until
2026-08-11 even though the firmware command (`FR-NE-078`) had been hardware-verified since
2026-07-28 — a reminder to check the firmware FR's `Status` before assuming a WAN gap is real.

**Notes:** gate every method in this section on `AudioCapabilityClient.getAudioCapability()
.hasMicrophone` — a camera build with no microphone hardware has nothing meaningful to return
here.

## Speaker Volume (output)

**Concept:** the camera's speaker output level (0-100) — ONVIF Media2
(`GetAudioOutputConfigurations`/`SetAudioOutputConfiguration`), distinct from the phone's own
local volume and from [mic gain](#audio--mic-gain--recording-toggle--test-tone).

**LAN:** `SpeakerVolumeClient.getSpeakerVolume()`/`.setSpeakerVolume(current)` — pass a
`SpeakerVolume` built via `.withLevel(newLevel)` on a previously-loaded value; ONVIF requires the
sibling token/name/outputToken fields resent on every set.

**WAN:** `WanSpeakerVolumeClient` — returns/accepts a bare `int`, not the ONVIF-shaped
`SpeakerVolume` struct (no sibling fields to echo over the WAN command).

**Notes:** `getSpeakerVolume` returns `CameraFailure` if the camera has no
`AudioOutputConfiguration` at all — UI should gate on `AudioCapabilityClient.hasSpeaker` before
calling either transport's getter.

## Snapshot / Preview Image

**Concept:** a still-image capture. There are **three different mechanisms** depending on
transport and purpose — pick by scenario, not by "which one did I use last time."

| Scenario | Client | Notes |
|---|---|---|
| LAN, user-facing capture or click-to-draw backdrop | `SnapshotClient.getSnapshot()` | `GET /snapshot`; `profile: 'high'` for a real capture, `'medium'` for a lightweight mask/OSD editor backdrop. |
| WAN, transient settings-screen backdrop | `WanPreviewSnapshotClient.getPreviewSnapshot()` | End-to-end encrypted (AES-256-GCM under a camera-generated shared key); **caller must not persist the returned bytes** — no gallery save, no cache file. Requires the shared key already fetched (open a settings screen on LAN once first — `RestStreamingClient.getPreviewKey()`, redesigned 2026-08-21 from a per-app pushed RSA key so re-adding this camera on a second device doesn't lock the first one out). |
| WAN, live video | `WanLiveViewClient.resolvePlaybackUri()` | Not a snapshot — resolves a playable KVS HLS URL after `startCloudStreaming()` confirms active. See [Cloud Streaming](#cloud-streaming-wan-live-view) below. |

## Cloud Streaming (WAN live view)

**Concept:** starting/stopping the KVS push for WAN live view, and checking its status.

**Not to be confused with:** the [WAN Preview Snapshot](#snapshot--preview-image) mechanism — a
single encrypted still frame for a settings-screen backdrop, not video streaming.

**LAN:** `CloudStreamingLanClient` — `getCloudStreamingStatus()`, `stopCloudStreaming()` only
(no LAN `start` — starting cloud streaming only makes sense for a WAN-bound client). Used
opportunistically once LAN reachability is confirmed, to avoid an unnecessary AWS/Lambda round
trip when stopping.

**WAN:** `WanLiveViewClient`/`AwsWanLiveViewClient` — `startCloudStreaming()`/
`stopCloudStreaming()`/`getCloudStreamingStatus()`/`resolvePlaybackUri()`.

## WiFi

**Concept:** the configured WiFi SSID, live signal strength, and setting new credentials.
NuraEye-only, no ONVIF equivalent.

**LAN:** `NetworkInfoClient` — `getWifiSsid()`, `setupWifi(ssid, psk, {verify})`,
`getWifiSignalStrength()`.

**WAN:** none — WiFi is inherently a LAN-adjacent, physically-local operation.

**Notes:** `getWifiSsid()`/`getWifiSignalStrength()` are only meaningful when the camera's active
interface is actually wireless — check `OnvifDeviceClient.getNetworkInterfaceInfo().isWireless`
first; on a wired (Ethernet) camera these return stale/meaningless data rather than a clean
failure, since the underlying firmware config always holds a WiFi entry even when it isn't the
active interface. `setupWifi`'s `verify: true` (default) is itself overridden by firmware
behavior — it always forces save-only when currently reached over Ethernet, regardless of what
the app passes.

## Deterrence — Manual Trigger & Auto-Stop Duration

**Concept:** two related settings, per `FEAT-236` (2026-08-14, revised 2026-08-15 after
real-hardware testing — see the note at the bottom of this section):
- **Manual trigger** (`FR-NE-082`/`083`) — a human activating siren/spotlight/warning right now,
  from Live View, independent of any detection event.
- **Auto-stop configuration** (`FR-NE-113`) — how long/how many times each action
  (siren/spotlight/warning) runs before stopping on its own. **One configured value per action,
  shared by both this manual trigger and the automatic detection-triggered response** ([Response
  Actions](#response-actions-deterrence-on-event) above) — not a per-request or
  per-trigger-path setting. `ActivateDeterrence`'s request carries **no duration parameter at
  all** — the camera always applies its own persisted value.

**Mixed units — `warning` is a repeat count, not seconds.** `siren_seconds`/`spotlight_seconds`
are whole seconds; `warning_repeat_count` (renamed from `warning_seconds`, 2026-08-15) is how
many times the clip plays before stopping, not a duration. `warning` loops internally
(completion-driven — see the note below), rather than playing once and self-terminating on the
clip's own length (the pre-`FEAT-236` behavior, when `warning` had no auto-stop concept at all).

**Bounds come from the camera, never hardcode a range.** `getDeterrenceDurationOptions()` reports
the real `min`/`max` per key — build slider/stepper bounds from this response, same "every Set
has a matching Options, UI built from it" rule this repo already applies to every other setting.
An earlier version of this feature hardcoded a 0-60s UI range instead, found and corrected via
real-hardware testing (a value of `0` degenerates to "never really activates").

**Not to be confused with:** [Response Actions](#response-actions-deterrence-on-event) above —
that decides *which* actions auto-fire on a detection event; this decides *how long/how many
times* an action (fired either way) runs, and gives the user a way to fire one directly.

**LAN:** `DeterrenceClient` — `getDeterrenceStatus()`, `activateDeterrence(String action)`,
`deactivateDeterrence(String action)`, `getDeterrenceDurations()` →
`Map<String, int>` (`siren_seconds`/`spotlight_seconds`/`warning_repeat_count`),
`setDeterrenceDurations(Map<String, int> changes)` (partial update),
`getDeterrenceDurationOptions()` → `DeterrenceDurationOptions` (per-key `min`/`max`).

**WAN:** `WanDeterrenceClient` — same method names and semantics.

**Notes:** gate the manual-trigger controls and duration section on
`CapabilitiesClient.getCapabilities().sirenCapable`/`spotlightCapable`/`warningCapable`
([Capabilities](#capabilities-discovery-not-a-setting)) — never a hardcoded action list, and
**never gated on any event type's own enable/disable toggle**: manual triggering doesn't depend
on detection being enabled at all, unlike the per-event Response Actions cards. Reference
implementation: `mobile_app/lib/features/live_view/live_view_screen.dart` (`_ControlsBar`'s
deterrence row, manual trigger, plus a periodic `GetDeterrenceStatus` poll while an action is
active — added 2026-08-15, real-hardware finding: without it, the control kept showing "active"
forever after the camera's own auto-stop fired, since nothing re-checked status) and
`mobile_app/lib/features/alerts/event_settings_screen.dart` (the Deterrence section — a slider
per second-based action, a `+`/`-` stepper for `warning_repeat_count`).

**Real-hardware finding, 2026-08-15 — do not reintroduce a duration-based warning loop.** The
first version of `warning`'s auto-stop used a fixed-period timer to *guess* when the clip
finished and re-trigger it. Real-device testing found this cut the clip off partway through and
restarted it. The fix (firmware-side, `bsp_camera_ameba.c`'s `prvWarningPollTimerCallback()`)
polls the actual playback-finished signal and only re-triggers on a real completion, decremented
against a repeat count — this is why `warning`'s unit had to change from seconds to a count in
the first place, not just a naming preference.

**Superseded generated client note:** the generated `RestDeterrenceAlarmsClient` (`/nuraeye/
buzzer`, `/nuraeye/deterrence`, `/nuraeye/deterrence/durations`) exists but is **not** what
`DeterrenceClient`/`WanDeterrenceClient` call — like every other hand-written NuraEye client,
they go through `NuraeyeClient.call()`'s REST-backed action-name facade instead (see [Hand-written
vs. generated REST clients](#hand-written-vs-generated-rest-clients) below). `RestBuzzerClient`-
style direct usage is unused in the app.

## Local Storage

**Concept:** SD-card local recording enable/disable, plus live card-presence and capacity/free
space (`FR-CF-044`/`FR-NE-087`/`FR-MOB-083`). **Two independent facts, not one**: *capability*
(does this SKU have an SD slot at all — a fixed, build-time fact) and *card presence* (is a card
actually inserted right now — always live). A camera can be capability-supported with no card
present; the camera actively **rejects** turning recording on in that case (`500`) rather than
silently accepting it.

**Wired up 2026-08-21** — added the whole way through (client, capability field, UI card,
`StorageSettingsScreen`) in one pass; no earlier partial state to reconcile against.

**LAN:** `LocalStorageClient.getStatus()`/`setEnabled(bool)`. **WAN:**
`WanLocalStorageClient` — same methods, same `LocalStorageStatus` type.

**Capability:** `CameraCapabilities.localStorageCapable` (`CapabilitiesClient.getCapabilities()`)
— cached at onboarding as `CachedCameraSettings.localStorageSupported`, same convention as
`osdSupported`/`privacyModeSupported`. **Live card presence is never cached** — always a fresh
`getStatus()` call, since it can change the instant the SD slot is opened.

**UI convention — deliberately not FR-MOB-082's "hide the control" pattern**: the top-level
"Storage" entry on `CameraSettingsScreen` stays visible and disabled-with-message when
`localStorageSupported == false` (same `_GroupTile` pattern as OSD/Privacy Masks), never hidden
— direct user instruction. Within `StorageSettingsScreen` itself, the enable/disable toggle is
omitted (not just disabled) and replaced with a "No SD card present" warning whenever
`cardPresent == false`, since the camera would reject a Set attempt anyway. Turning the toggle
off requires an explicit confirmation dialog (stops future recording, does not erase existing
footage).

## Capabilities (discovery, not a setting)

**Concept:** what this specific camera build/unit supports — queried once at onboarding and
cached by the app, not read/written per-screen like the settings above. **This package has many
independent capability/support flags, not just one** — each gates a different setting or client,
and none of them are the same thing as that setting's current *value*. This section is the
complete inventory; the per-setting sections above each note their own gate inline, but check
here if you're not sure whether a flag you're about to ignore is load-bearing.

**LAN:**
- `CapabilitiesClient.getCapabilities()` → `wanCommandCapable`/`wanLiveViewCapable`/
  `supportedEventTypes`/`supportedEventDeterrenceOptions`/`sirenCapable`/`spotlightCapable`/
  `warningCapable` (the hand-written client, seven fields — see the WAN paragraph below for the
  first two, [Event Preferences](#event-preferences) for the third, [Response
  Actions](#response-actions-deterrence-on-event) for the fourth, and [Deterrence — Manual
  Trigger & Auto-Stop Duration](#deterrence--manual-trigger--auto-stop-duration) for the last
  three — added `FEAT-236`, 2026-08-14, mirroring fields the generated client below already had).
- The generated `RestCapabilitiesClient.getCapabilities()` (`/nuraeye/capabilities`) returns a
  **broader** response, `GetCapabilitiesResponse`, with the same fields plus
  `sirenCapable`/`spotlightCapable`/`warningCapable` (now also on the hand-written client above)
  and `localStorageCapable` (SD card), plus REST-surface duplicates of night-vision
  capability (`nightVisionColorCapable`/`nightVisionSmartCapable`, see below). **Nothing in the
  app currently calls this client** — if you're wiring up local-storage controls, this is the
  flag you need and it isn't being checked anywhere yet; don't assume an equivalent check
  already exists elsewhere (the deterrence flags this comment used to point at are now also
  covered by the hand-written client's `supportedEventDeterrenceOptions`, already wired into
  `EventSettingsScreen`). **Not yet regenerated for `supported_event_types`/
  `supported_event_deterrence_options`** (added to the OpenAPI spec 2026-08-13) — `tools/
  generate_dart_rest_client.py` needs a re-run before this generated model picks them up; the
  hand-written `CapabilitiesClient` above is unaffected and already has both.
- `Media2CapabilitiesClient.getServiceCapabilities()` → `osdSupported` (gates
  [OSD](#osd-on-screen-display)) / `maskSupported` (gates
  [Privacy Masks](#privacy-masks)) — whether the Media2 service advertises each feature at all,
  independent of anything `OsdOptions`/`MaskOptions` themselves report.
- `AudioCapabilityClient.getAudioCapability()` → `hasSpeaker` (gates
  [Speaker Volume](#speaker-volume-output)) / `hasMicrophone` (gates
  [mic gain](#audio--mic-gain--recording-toggle--test-tone) and two-way talk's return-audio leg).
- `OnvifDeviceClient.getNetworkInterfaceInfo()` → `.isWireless` — gates
  `NetworkInfoClient.getWifiSsid()`/`getWifiSignalStrength()`: both return meaningless/stale data
  (not a clean failure) if called while the active interface is wired Ethernet. Check
  `isWireless` first.

**WAN:** none of these have a WAN path — capability discovery is inherently a LAN-first,
onboarding-time operation (see `prefetchAndCache` in
[.claude/rules/mobile-app-screen-conventions.md](../../../.claude/rules/mobile-app-screen-conventions.md)).

### Being signed in — the prerequisite above every other WAN gate

**Every `Wan*Client` call requires the user to be authenticated, full stop — this is checked
before `wanCommandCapable`, before any Options flag, before anything else in this guide.** It's
easy to miss because it isn't a capability flag you read from a response; it's a precondition
enforced inside `IotCommandClient` itself: if `WanAuth.idTokenProvider()` (wired to
`auth_api`'s `AuthController` — see that package's `API_REFERENCE.md`) returns `null`, every
`Wan*Client` method throws `StateError('IotCommandClient called while unauthenticated')`
internally. That exception **is** caught and converted to a normal `CameraFailure` by every
`Wan*Client` wrapper — so it stays within this package's `CameraResult` contract and won't crash
a caller — but the failure text will be the raw `StateError` message (e.g.
`"StateError: IotCommandClient called while unauthenticated"`), not a friendly explanation, and
nothing about it distinguishes "not signed in" from any other failure unless the caller
recognizes that specific text.

**Practical effect:** gate any screen that calls a `Wan*Client` on `auth_api`'s
`AuthController.instance.status == AuthStatus.authenticated` first (or simply don't offer a
WAN-path control before sign-in completes — this app's own `AuthGate` already ensures no
camera-facing screen is reachable at all while unauthenticated, so in practice this mostly
matters for background/best-effort callers like `alerts_api`'s `CameraAlertsHub.ensureRunning()`,
which explicitly catches this failure and treats it as "nothing to sync yet" rather than
surfacing it — see that package's own docs). Don't rely on parsing `CameraFailure.reason`'s text
to detect this case in product code; check auth status up front instead.

### `wanCommandCapable` / `wanLiveViewCapable`

`wanCommandCapable` gates every `Wan*Client` listed anywhere in this guide — not just live view.
It means "this device has real AWS IoT credentials provisioned and the firmware build supports
the MQTT command channel at all." If it's `false`, no `Wan*Client` call — Imaging, MirrorFlip,
PrivacyMode, Mask, Osd, VideoEncoder, AudioVolume, SpeakerVolume, DeviceIdentity, ImageQuality,
none of them — will get a real response; they'll time out or fail against a camera that never
subscribes to the command topic in the first place. `wanLiveViewCapable` is a *stricter* subset
of the same flag, additionally requiring KVS build support — gates only
`WanLiveViewClient`/`resolvePlaybackUri`/`WanPreviewSnapshotClient`, not the command-relay
clients above.

Practical effect: don't reach for `isWan`/"is the transport currently WAN" as your only signal
for whether a `Wan*Client` call is safe to attempt — that's a *connectivity* decision (see
`.claude/rules/mobile-app-screen-conventions.md` § "LAN/WAN transport selection"), not a *capability* one. A camera
can be currently reached over WAN connectivity-wise while still having `wanCommandCapable ==
false` (e.g. no AWS credentials provisioned on that unit) — the settings entry point should
already be disabled from the cached capabilities check at onboarding, the same way it's disabled
until `_lastKnownTransport` is known (see that rule file's item 2).

### Per-setting Options-response capability flags — not the same idea as the two above

The flags above come from a dedicated `Get*Capabilities` call, checked once at onboarding. A
second, easily-confused kind of flag lives *inside* a setting's own `Get*Options` response —
still "is this supported," but scoped to one setting rather than the whole device, and (per the
Options-caching convention in `.claude/rules/mobile-app-screen-conventions.md`) fetched/cached alongside that
setting's bounds rather than at a separate onboarding step. These are noted individually in each
section above, collected here for a single lookup:

| Flag | On | From | Gates |
|---|---|---|---|
| `ImagingOptions.wdrSupported` | `OnvifImagingClient`/analogous WAN record | `getImagingOptions()` | [WDR](#wdr-wide-dynamic-range) control — hide, don't disable, when `false`. |
| `ImagingOptions.irCutFilterModes` (empty list) | same | same | [Day/Night Mode](#daynight-mode-ir-cut-filter) picker — no valid choices to offer. |
| `NightVisionStatus.colorCapable` / `.smartCapable` | `NightVisionStatus` | `getNightVisionType()` itself (embedded in the status response, not a separate Options call) | [Night Vision Type](#night-vision-type)'s Color/Smart choice chips respectively. |
| `EncodingOptions.supportsCbr` (**per-encoding** — H264 and H265 can differ) | `VideoEncoderSettingsOptions` | `getVideoEncoderSettingsOptions()` | [Video Encoder](#video-encoder-settings-stream-0-high-res)'s CBR/VBR toggle — only editable when the *currently selected* encoding's own flag is `true`. |
| `MaskOptions.rectangleOnly` / `.singleColorOnly` | `MaskOptions` | `getMaskOptions()` | [Privacy Masks](#privacy-masks) editor's shape freedom / color-picker availability. `maxMasks == 0` (the fallback when `GetMaskOptions`'s `<Options>` element is absent entirely) doubles as "masks not supported at all." |
| `OsdOptions.fontColorRangeAvailable` | `OsdOptions` | `getOsdOptions()` | [OSD](#osd-on-screen-display)'s RGB slider color picker — `true` when the camera reports a continuous `ColorspaceRange` rather than only a discrete list; without checking this the color UI can silently fail to render even though `fontColors` alone looks non-empty in some builds. |

**The pattern to internalize:** almost every settings screen in this package has *two* separate
things to check before trusting a control is usable — the device-wide capability flag (this
section) and the setting's own Options-response support flag (the table above) — and neither
substitutes for the other. `osdSupported` (device advertises OSD at all) and
`OsdOptions.fontColorRangeAvailable` (this specific OSD feature's color mode) are a real example
of both applying to the same screen at once.

---

## Hand-written vs. generated REST clients

A handful of settings (Mirror/Flip, Privacy Mode, and others under `lan/nuraeye/rest_*.dart`)
are reachable through **two different Dart client wrappers for the identical wire endpoint**:
the hand-written client listed in this guide (`MirrorFlipClient`, `PrivacyModeClient`, etc.) and
a machine-generated `Rest*Client` (`RestVideoImageClient`, `RestPrivacyClient`, ...) produced
from `design/Camera-REST-API.openapi.yaml`. These are not two different settings and not two
different camera behaviors — they hit the same `/nuraeye/*` path.

**Always use the hand-written client listed in this guide.** The generated clients are current
unused reserve API surface (`NuraeyeClient`/the hand-written wrappers do not call through them)
kept for a future consumer that wants the REST API's native shape — see `API_REFERENCE.md`'s
"Generated REST clients" section. Never hand-edit a `rest_*.dart` file; regenerate via
`/generate_dart_client` if the OpenAPI spec changes.
