# CameraAlertsHub / AlertsAuth (`packages/alerts_api/lib/src/camera_alerts_hub.dart`)

Main-isolate API surface of `alerts_api` — the always-on background WAN camera-alert listener
(direct AWS-SigV4-signed MQTT-over-WSS to AWS IoT Core, kept alive independent of any screen via
an Android foreground service; **Android only today**, every method a silent no-op on iOS). See
`packages/alerts_api/API_REFERENCE.md` for the full narrative doc this table summarizes.
`CameraAlertsTaskHandler` (the background-isolate half, in `camera_alerts_task_handler.dart`) is
an internal implementation detail — no call site outside this package should ever need it
directly. Model types (`AlertsApiConfig`, `AlertsCredentials`, `WatchedCamera`, `AlertsStatus`)
are documented separately in [alerts_api_config.md](alerts_api_config.md).

This package has no dependency on `auth_api`/`camera_api` — it takes the camera list and AWS
credentials via the `AlertsAuth` static hooks below, mirroring `camera_api`'s own `WanAuth`
pattern.

## AlertsAuth (static config hooks)

| Name | Signature | Purpose | Used for |
|------|-----------|---------|----------|
| `config` | `static AlertsApiConfig?` | Deployment's AWS IoT region/endpoint. | Set once at app startup, before the first `ensureRunning()` call. |
| `cameraListProvider` | `static Future<List<WatchedCamera>> Function()?` | Returns the cameras that should currently be watched; called on every `ensureRunning()`. | Wire to the app's own onboarded-camera store (e.g. `HomesController`'s cameras with a non-null `thingName`). |
| `credentialsProvider` | `static Future<AlertsCredentials> Function()?` | Returns fresh AWS credentials to sign the MQTT connection; a thrown exception is treated as "nothing to sync yet." | Wire to `auth_api`'s `AuthController.awsCredentials()`, converting to `AlertsCredentials`. |

If any of the three hooks is unset, `ensureRunning()` returns immediately doing nothing (no
crash) — safe to call before configuration is complete.

## CameraAlertsHub

| Name | Signature | Purpose | Used for |
|------|-----------|---------|----------|
| `instance` | `static final CameraAlertsHub` | Singleton — the only way to obtain this class. | Every call site uses `CameraAlertsHub.instance`. |
| `ensureRunning` | `Future<void> ensureRunning()` | Starts (or updates) the listener for every camera `AlertsAuth.cameraListProvider` currently returns, pushing fresh credentials down to the background isolate. Best-effort/silent — never throws. | Call after login, on app resume, and periodically while signed in (this class already self-schedules a 20-minute periodic re-call once started). |
| `stop` | `Future<void> stop()` | Stops the foreground service entirely. | Call on logout — the background isolate has no way to know the user signed out otherwise. |
| `events` | `Stream<CameraAlertEvent>` (broadcast) | Every alert received, across all watched cameras. | Any screen wanting live camera-alert state — filter by `thingName`. |
| `statusUpdates` | `Stream<AlertsStatus>` (broadcast) | Broadcasts whenever the set of currently-connected cameras changes. | An "alerts unavailable/reconnecting" UI indicator. |
| `lastStatus` | `AlertsStatus?` (getter) | Most recent status snapshot, or `null` if none has arrived yet. | Reading current state without waiting on the next `statusUpdates` event (e.g. initial widget build). |
| `onAlertPersist` | `void Function(String thingName, String event, Map<String, dynamic> body)?` (instance field) | Optional callback invoked on every received alert, before it's broadcast on `events`. | Persisting alert history locally without a separate subscription — set once on `instance`. |

`CameraAlertEvent` — `thingName: String`, `event: String` (e.g. `"VideoModeChanged"`,
`"PrivacyModeChanged"` — matches the camera's alert JSON `event` field exactly),
`body: Map<String, dynamic>` (raw decoded JSON).

## Known limitations (from the package's own API_REFERENCE.md)

- No exponential backoff on reconnect — fixed ~60s periodic retry via the foreground-task tick.
- No explicit Android battery-optimization/OEM-whitelist handling.
- iOS not implemented — every method above is a no-op there today.
- The background isolate shows a local notification on `VideoModeChanged`/`PrivacyModeChanged`
  events unconditionally, independent of whether any screen is listening to `events`.
