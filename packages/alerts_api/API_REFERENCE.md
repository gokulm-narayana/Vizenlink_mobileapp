# alerts_api — API Reference

`alerts_api` is the always-on background WAN camera-alert listener for the VizenLink mobile
app — a direct, AWS-SigV4-signed MQTT-over-WSS subscription to AWS IoT Core per onboarded
camera, kept alive independent of any single screen's lifecycle (Android foreground service).
Extracted 2026-08-12 alongside `auth_api` (see
[design/WORKFLOW_EXCEPTIONS.md](../../../design/WORKFLOW_EXCEPTIONS.md)'s 2026-08-12 entry) so
the UI/business-logic layer has a documented, stable contract for camera alert delivery, the
same way `camera_api` documents camera access.

Not pure-Dart: owns an Android foreground service (`flutter_foreground_task`) and local
notifications (`flutter_local_notifications`), both inherently platform-specific. **Android
only today** — the iOS foreground-service model differs and isn't built yet; every method is a
silent no-op on iOS.

This package has no dependency on `auth_api` or `camera_api` — it takes camera list and AWS
credentials via injected hooks (see "Configuration" below), the same decoupling shape
`camera_api`'s own `WanAuth` uses.

## Configuration

Set `AlertsAuth`'s static hooks once at app startup, before the first `ensureRunning()` call:

```dart
AlertsAuth.config = const AlertsApiConfig(
  region: 'ap-south-1',
  iotEndpoint: 'a1zfm34z2p80an-ats.iot.ap-south-1.amazonaws.com',
);
AlertsAuth.cameraListProvider = () async => OnboardingCameraStore.instance.cameras
    .where((c) => c.thingName != null)
    .map((c) => WatchedCamera(thingName: c.thingName!))
    .toList();
AlertsAuth.credentialsProvider = () async {
  final creds = await AuthController.instance.awsCredentials(); // from auth_api
  return AlertsCredentials(
    accessKeyId: creds.accessKeyId,
    secretKey: creds.secretKey,
    sessionToken: creds.sessionToken,
    expiresAt: creds.expiresAt,
  );
};

// Optional — persist every received alert without a separate subscription:
CameraAlertsHub.instance.onAlertPersist = (thingName, event, body) =>
    AlertHistoryStore.instance.insert(thingName, event, body);
```

**`region`/`iotEndpoint` above are this project's real, live values** (the fleet-wide AWS IoT
Core broker every camera connects to — not per-account or secret, same as a hostname) — use them
as-is; there is no separate value to go request. `AlertsAuth.cameraListProvider`/
`credentialsProvider` are genuinely app-specific (they depend on how your app tracks onboarded
cameras and its own auth state) and must be implemented for real, not copied verbatim — the
snippet above shows the shape, using `auth_api`'s `AuthController.awsCredentials()` as the
credentials source.

If any of the three `AlertsAuth` hooks is unset, `ensureRunning()` returns immediately without
doing anything (no crash, no error) — safe to call before configuration is complete, though
alerts obviously won't flow until it is.

## CameraAlertsHub

`CameraAlertsHub.instance` — the main-isolate API surface. Call sites only ever need this class;
`CameraAlertsTaskHandler` (the background-isolate half) is an internal implementation detail.

| Member | Description |
|---|---|
| `ensureRunning()` | Starts (or updates) the listener for every camera `AlertsAuth.cameraListProvider` currently returns. Call after login, on app resume, and periodically while signed in. Best-effort/silent — never throws. |
| `stop()` | Stops the service entirely. Call on logout. |
| `events` (`Stream<CameraAlertEvent>`) | Every alert received, across all watched cameras — filter by `thingName`. |
| `statusUpdates` (`Stream<AlertsStatus>`) | **Added 2026-08-12.** Broadcasts whenever the set of currently-connected cameras changes — use for an "alerts unavailable/reconnecting" indicator. Previously this connectivity data was collected internally but never surfaced. |
| `lastStatus` (`AlertsStatus?`) | The most recent status snapshot, or `null` if none has arrived yet — for reading current state without waiting on the next `statusUpdates` event. |
| `onAlertPersist` | Optional instance field — set to a callback to persist every alert as it arrives, without a separate subscription. Instance-scoped (not a static `AlertsAuth` hook) since it's naturally set once per `instance`, not startup-wide config. |

`CameraAlertEvent` — `thingName`, `event` (e.g. `"VideoModeChanged"`, `"PrivacyModeChanged"` —
matches the camera's alert JSON `event` field exactly), `body` (raw decoded JSON map).

`AlertsStatus` — `connectedThingNames`/`watchedThingNames` (`Set<String>`), plus `allConnected`
and `isConnected(thingName)` convenience getters.

## Known limitations

- **No exponential backoff on reconnect** — a fixed periodic retry (every foreground-task tick,
  ~60s) drives self-healing, not backoff. Acceptable today given the low reconnect frequency in
  practice, but worth knowing if reconnect storms ever become a concern.
- **No explicit Android battery-optimization/OEM-whitelist handling.** A dismissed notification
  is proactively re-posted as a partial mitigation and diagnostic canary, but some OEM battery
  managers can still kill the underlying process; there's no `requestIgnoreBatteryOptimizations`
  -style prompt.
- **iOS is not implemented** — every method is a no-op there today.

## Notification behavior

The background isolate shows a local notification on `VideoModeChanged` and `PrivacyModeChanged`
events directly (independent of whether any screen is listening to `events`) — this is
unconditional today, not configurable per-event-type from the app side.
