/// Identifies and authenticates against one camera. Immutable — building a new connection
/// (e.g. after the user edits the connect form) is cheap and makes call sites unambiguous
/// about which credentials were in effect for a given request.
class CameraConnection {
  const CameraConnection({
    required this.host,
    required this.username,
    required this.password,
    this.httpsPort = 443,
    this.rtspPort = 554,
    this.thingName,
    this.wanLiveViewCapable,
    this.wanCommandCapable,
    this.macAddress,
  });

  /// IP or hostname on the LAN. Not used for the WAN path (WAN addresses the camera via its
  /// AWS IoT `thingName`, not an IP). **Not a stable identity** — a DHCP lease renewal can
  /// change this for the same physical camera; use [identityKey] for any local
  /// identity/cache-lookup purpose instead of comparing `host` directly.
  final String host;
  final String username;
  final String password;
  final int httpsPort;
  final int rtspPort;

  /// The camera's network-interface MAC address (`GetNetworkInterfaces`' `HwAddress`), fetched
  /// best-effort at onboarding time — see
  /// `design/stages/mobile-app-android-2-camera-onboarding/DESIGN.md` §5.4. Null when unknown
  /// (query failed, or this connection predates the field). Stable across a DHCP-assigned IP
  /// change, unlike [host] — the reason [identityKey] prefers it.
  final String? macAddress;

  /// The key every local store (`OnboardingCameraStore`, `CameraSettingsCacheStore`,
  /// `CameraSnapshotCache`) should use to recognize "which camera is this" — [macAddress] when
  /// known, [host] otherwise (a camera onboarded before this field existed, or whose MAC query
  /// failed). Never use [host] directly for identity/cache-keying purposes; it's only a network
  /// address, and it can change out from under a physical camera on a DHCP lease renewal.
  String get identityKey => macAddress ?? host;

  /// AWS IoT thing name, required only for WAN calls (`IotCommandClient`). Null when this
  /// connection is LAN-only (e.g. the minimal connect screen hasn't collected it yet).
  final String? thingName;

  /// Whether this camera supports WAN (remote) live view (`FR-NE-092`'s `GetCapabilities`,
  /// queried once at onboarding). **Null means "unknown," not "unsupported"** — either this
  /// connection predates the capability-discovery feature, or the onboarding-time query itself
  /// failed (best-effort, never blocks onboarding). `LiveViewController` treats null as "assume
  /// supported" (fail open) rather than silently withholding WAN from every
  /// already-onboarded camera the moment this shipped — see that class's own doc.
  final bool? wanLiveViewCapable;

  /// Whether this camera supports WAN (remote) commands at all — AWS IoT/MQTT built into this
  /// firmware **and** this specific device actually provisioned with real credentials
  /// (`FR-NE-092`'s `GetCapabilities`, queried once at onboarding, same call as
  /// [wanLiveViewCapable]). **Null means "unknown," not "unsupported"** — same fail-open
  /// convention as [wanLiveViewCapable]: either this connection predates the field, or the
  /// onboarding-time query failed (best-effort, never blocks onboarding). **Added 2026-08-14**
  /// — the value was already being fetched at onboarding (`AddCameraCredentialsScreen` logged
  /// it) but never persisted, so nothing downstream could gate on it; the Alerts screen showed
  /// full event-configuration controls even for a camera with no AWS IoT support at all, even
  /// though `CameraAlertsHub`'s entire delivery path is WAN MQTT — a camera that can't publish
  /// can never actually deliver an alert, so those controls configured something with no
  /// observable effect. Distinct from [wanLiveViewCapable]: a build can have AWS IoT (alerts
  /// work) without KVS (WAN live view doesn't) — the cost-constrained-SKU case `FR-CF-137`
  /// exists for — so one can't be inferred from the other.
  final bool? wanCommandCapable;

  /// Builds a new connection with [thingName] replaced — used at onboarding time once
  /// `OnvifDeviceClient.getSerialNumber()` resolves it (see `AddCameraCredentialsScreen`).
  /// `CameraConnection` itself stays immutable; this returns a fresh instance rather than
  /// mutating in place.
  CameraConnection copyWithThingName(String thingName) => CameraConnection(
        host: host,
        username: username,
        password: password,
        httpsPort: httpsPort,
        rtspPort: rtspPort,
        thingName: thingName,
        wanLiveViewCapable: wanLiveViewCapable,
        wanCommandCapable: wanCommandCapable,
        macAddress: macAddress,
      );

  /// Builds a new connection with [wanLiveViewCapable]/[wanCommandCapable] replaced — used at
  /// onboarding time once `CapabilitiesClient.getCapabilities()` resolves them (see
  /// `AddCameraCredentialsScreen`). Both come from the same `GetCapabilities` call, so they're
  /// set together rather than via two separate `copyWith*` methods.
  CameraConnection copyWithWanCapabilities({
    required bool wanLiveViewCapable,
    required bool wanCommandCapable,
  }) =>
      CameraConnection(
        host: host,
        username: username,
        password: password,
        httpsPort: httpsPort,
        rtspPort: rtspPort,
        thingName: thingName,
        wanLiveViewCapable: wanLiveViewCapable,
        wanCommandCapable: wanCommandCapable,
        macAddress: macAddress,
      );

  /// Builds a new connection with [macAddress] replaced — used at onboarding time once
  /// `OnvifDeviceClient.getNetworkInterfaceInfo()` resolves it (see
  /// `AddCameraCredentialsScreen`, `design/stages/mobile-app-android-2-camera-onboarding/
  /// DESIGN.md` §5.4).
  CameraConnection copyWithMacAddress(String macAddress) => CameraConnection(
        host: host,
        username: username,
        password: password,
        httpsPort: httpsPort,
        rtspPort: rtspPort,
        thingName: thingName,
        wanLiveViewCapable: wanLiveViewCapable,
        wanCommandCapable: wanCommandCapable,
        macAddress: macAddress,
      );

  /// Builds a new connection with [password] replaced — used after a successful
  /// `OnvifDeviceClient.setUserPassword()` call (see `ChangePasswordScreen`) to keep
  /// `OnboardingCameraStore`'s persisted copy in sync with what the camera now actually expects.
  CameraConnection copyWithPassword(String password) => CameraConnection(
        host: host,
        username: username,
        password: password,
        httpsPort: httpsPort,
        rtspPort: rtspPort,
        thingName: thingName,
        wanLiveViewCapable: wanLiveViewCapable,
        wanCommandCapable: wanCommandCapable,
        macAddress: macAddress,
      );

  Uri get onvifDeviceEndpoint => Uri.https('$host:$httpsPort', '/onvif/device_service');
  Uri get onvifImagingEndpoint => Uri.https('$host:$httpsPort', '/onvif/imaging_service');
  Uri get onvifMediaEndpoint => Uri.https('$host:$httpsPort', '/onvif/media_service');

  /// ONVIF Profile G Recording Control service (`FR-OV-080`) — real path confirmed in
  /// `onvif/config/onvif_server_config.c`'s `recording.service_info.p_service_url_path`.
  /// Client-only for now (`OnvifRecordingClient`, not yet wired into any screen) — see
  /// `design/stages/04-recording-playback/DESIGN.md`'s NF15 section.
  Uri get onvifRecordingEndpoint => Uri.https('$host:$httpsPort', '/onvif/recording');

  /// ONVIF Profile G Search service (`FR-OV-081`) — real path confirmed in
  /// `onvif/config/onvif_server_config.c`'s `search.service_info.p_service_url_path`.
  /// Client-only for now (`OnvifSearchClient`) — see [onvifRecordingEndpoint]'s doc.
  Uri get onvifSearchEndpoint => Uri.https('$host:$httpsPort', '/onvif/search');

  /// ONVIF Profile G Replay Control service (`FR-OV-082`) — real path confirmed in
  /// `onvif/config/onvif_server_config.c`'s `replaycontrol.service_info.p_service_url_path`.
  /// Client-only for now (`OnvifReplayControlClient`) — see [onvifRecordingEndpoint]'s doc.
  Uri get onvifReplayEndpoint => Uri.https('$host:$httpsPort', '/onvif/replay');
  /// [profile] must be one of this camera's fixed ONVIF profile names — `"high"`, `"medium"`,
  /// or `"low"` (`onvif_user_config.c`'s `Profile_1`/`_2`/`_3`, matched server-side by
  /// `camera.c`'s `GET` handler via `strstr` against each profile's own
  /// `p_snapshot_url_path`). Defaults to `"high"` — the right choice when the caller actually
  /// wants the best-quality frame (the live-view snapshot-save button, the home dashboard
  /// thumbnail), but callers that only need a reference/background image to draw on top of
  /// (mask/OSD editors) should pass `"medium"` explicitly (see `ReferenceImageCard`) — no
  /// reason to pull a full high-res JPEG (1920x1080/2560x1440 vs. medium's 1280x720) over the
  /// network and decode it just to use as a click-to-draw backdrop.
  Uri snapshotEndpoint({String profile = 'high'}) =>
      Uri.https('$host:$httpsPort', '/snapshot', {'profile': profile});

  /// Pure-Dart JSON (de)serialization for local persistence (`OnboardingCameraStore`, app
  /// layer) — kept here rather than in the app layer since it's plain data-shape logic with no
  /// `package:flutter`/storage-plugin dependency of its own.
  Map<String, dynamic> toJson() => {
        'host': host,
        'username': username,
        'password': password,
        'httpsPort': httpsPort,
        'rtspPort': rtspPort,
        if (thingName != null) 'thingName': thingName,
        if (wanLiveViewCapable != null) 'wanLiveViewCapable': wanLiveViewCapable,
        if (wanCommandCapable != null) 'wanCommandCapable': wanCommandCapable,
        if (macAddress != null) 'macAddress': macAddress,
      };

  factory CameraConnection.fromJson(Map<String, dynamic> json) => CameraConnection(
        host: json['host'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        httpsPort: json['httpsPort'] as int? ?? 443,
        macAddress: json['macAddress'] as String?,
        rtspPort: json['rtspPort'] as int? ?? 554,
        thingName: json['thingName'] as String?,
        wanLiveViewCapable: json['wanLiveViewCapable'] as bool?,
        wanCommandCapable: json['wanCommandCapable'] as bool?,
      );
}
