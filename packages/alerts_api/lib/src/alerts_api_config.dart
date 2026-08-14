/// Deployment-specific AWS IoT config — supplied by the app, never read from the environment by
/// this package itself. Mirrors `auth_api`'s `AuthApiConfig`.
class AlertsApiConfig {
  const AlertsApiConfig({required this.region, required this.iotEndpoint});

  final String region;

  /// AWS IoT Core data-plane MQTT broker hostname (fleet-wide, same for every camera).
  final String iotEndpoint;
}

/// Temporary AWS credentials needed to sign the MQTT-over-WSS connection URL. Deliberately a
/// separate type from `auth_api`'s `AwsCredentials` (identical shape) — this package has no
/// dependency on `auth_api`, so the app converts between the two at the call site. See
/// `AlertsApiConfig`'s doc and this package's `API_REFERENCE.md` § "Configuration."
class AlertsCredentials {
  const AlertsCredentials({
    required this.accessKeyId,
    required this.secretKey,
    required this.sessionToken,
    required this.expiresAt,
  });

  final String accessKeyId;
  final String secretKey;
  final String sessionToken;
  final DateTime expiresAt;
}

/// One camera to watch for alerts.
class WatchedCamera {
  const WatchedCamera({required this.thingName});

  final String thingName;
}

/// Connectivity state of the background alert listener, reported per onboarded camera.
enum AlertsConnectionState { connecting, connected, disconnected }

/// A snapshot of which watched cameras currently have a live alert subscription — the "alerts
/// health" signal. Previously collected internally but never surfaced to the UI (see this
/// package's `API_REFERENCE.md` § "Known limitations" history).
class AlertsStatus {
  const AlertsStatus({required this.connectedThingNames, required this.watchedThingNames});

  final Set<String> connectedThingNames;
  final Set<String> watchedThingNames;

  bool get allConnected =>
      watchedThingNames.isNotEmpty && connectedThingNames.length == watchedThingNames.length;

  bool isConnected(String thingName) => connectedThingNames.contains(thingName);
}
