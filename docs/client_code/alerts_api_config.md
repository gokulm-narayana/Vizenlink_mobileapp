# alerts_api config & model classes (`packages/alerts_api/lib/src/alerts_api_config.dart`)

Plain model/config classes for `alerts_api` — no behavior, no UI. Companion to
[camera_alerts_hub.md](camera_alerts_hub.md), which documents the actual API surface
(`CameraAlertsHub`/`AlertsAuth`) that consumes these types.

## Models

| Class | Fields | Used by |
|-------|--------|---------|
| `AlertsApiConfig` | `region: String`, `iotEndpoint: String` (AWS IoT Core data-plane MQTT broker hostname, fleet-wide) | Set once on `AlertsAuth.config` at app startup |
| `AlertsCredentials` | `accessKeyId: String`, `secretKey: String`, `sessionToken: String`, `expiresAt: DateTime` | Returned by `AlertsAuth.credentialsProvider`; deliberately a separate type from `auth_api`'s `AwsCredentials` (identical shape) since this package has no dependency on `auth_api` — the app converts between the two at the call site |
| `WatchedCamera` | `thingName: String` | Returned (as a list) by `AlertsAuth.cameraListProvider` — one entry per camera to watch for alerts |
| `AlertsConnectionState` (enum) | `connecting`, `connected`, `disconnected` | Per-camera connectivity state (not currently exposed on `AlertsStatus` directly — see that class's own two `Set<String>` fields for the aggregate view) |
| `AlertsStatus` | `connectedThingNames: Set<String>`, `watchedThingNames: Set<String>`, plus derived getters `allConnected: bool` and `isConnected(String thingName): bool` | Emitted on `CameraAlertsHub.statusUpdates`/`.lastStatus` — the "alerts health" signal for an "alerts unavailable/reconnecting" UI indicator |
