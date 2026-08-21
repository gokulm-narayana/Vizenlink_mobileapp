import 'package:pointycastle/export.dart';

/// Real, temporary per-user AWS credentials (Cognito Identity Pool `GetCredentialsForIdentity`
/// result) — the shape [WanAuth.awsCredentialsProvider] returns. A minimal, `camera_api`-local
/// copy of `auth_api`'s `AwsCredentials` (this package can't depend on `auth_api` — see
/// [WanAuth]'s own doc) rather than expiry-tracking of its own: the provider is expected to
/// re-fetch/refresh internally (`AuthController.awsCredentials()` already does), so this class
/// only carries what a single MQTT connect actually needs.
class WanAwsCredentials {
  const WanAwsCredentials({
    required this.accessKeyId,
    required this.secretKey,
    required this.sessionToken,
  });

  final String accessKeyId;
  final String secretKey;
  final String sessionToken;
}

/// App-wide hooks the WAN clients in this package call through instead of importing anything
/// app-specific (a `ChangeNotifier`-based auth controller, a `flutter_secure_storage`-backed key
/// store) directly — `camera_api` stays pure-Dart and UI/app-independent per its own package doc.
///
/// **Set these exactly once, at app startup** (e.g. `main.dart`, before the first WAN call) —
/// every WAN client falls back to them when it isn't given a per-call override (the existing
/// `idTokenProvider`/etc. constructor parameters, kept for tests). Moved here 2026-08-11 when
/// the `Wan*Client` classes themselves moved from `mobile_app/lib/features/**/wan/` into this
/// package — see that move's own commit/kb note for the full rationale (mobile team gets a
/// complete `lan/`+`wan/` API surface, not just LAN).
class WanAuth {
  WanAuth._();

  /// The signed-in session's current Cognito ID token, or `null` if not signed in. Backs
  /// `KvsPlaybackClient` (still Lambda-relayed — see [kvsPlaybackLambdaUrl]'s doc).
  static String? Function()? idTokenProvider;

  /// The deployed `cloud_backend/kvs_playback_lambda` Function URL
  /// (`kb/wiki/aws-iot-kvs-setup.md` Part D). **2026-08-18**: `IotCommandClient` no longer routes
  /// through this relay (see its own doc) — this URL now backs only `KvsPlaybackClient`'s KVS
  /// HLS-session lookup, which is a separate, still-unverified Cognito-federation restriction
  /// (`kb/wiki/kvs-viewer-read-permissions-cognito-role.md`), not touched by that change.
  static String? kvsPlaybackLambdaUrl;

  /// Real, temporary AWS credentials for the signed-in user's federated Identity Pool role, or
  /// `null` if not signed in — backs `IotCommandClient`'s direct MQTT-over-WSS connection to AWS
  /// IoT Core. Expected to internally cache/refresh (mirrors `idTokenProvider`'s "current value"
  /// contract) — `IotCommandClient` calls this every time it needs a connection, not just once.
  static Future<WanAwsCredentials?> Function()? awsCredentialsProvider;

  /// AWS IoT Core data-plane endpoint (e.g. `xxxxx-ats.iot.ap-south-1.amazonaws.com`, no scheme)
  /// — fleet-wide, same value the camera firmware itself connects to. Backs
  /// `IotCommandClient`'s MQTT-over-WSS connect.
  static String? awsIotEndpoint;

  /// AWS region the Identity Pool / IoT endpoint above live in (e.g. `ap-south-1`) — needed for
  /// SigV4 request signing. Backs `IotCommandClient`'s MQTT-over-WSS connect.
  static String? awsRegion;

  /// The device's stored RSA private key for the WAN preview-snapshot decrypt path
  /// (`FR-MOB-101`/`FR-SECL-017`) — `null` if no keypair has been generated/registered yet.
  /// Backs `WanPreviewSnapshotClient.getPreviewSnapshot()`.
  static Future<RSAPrivateKey?> Function()? previewPrivateKeyProvider;

  /// Called when the camera reports `no_preview_key_registered` for [thingName] (e.g. after a
  /// factory reset wiped its previously-registered key) — the app's job is to flag that camera
  /// for automatic re-registration next time it's reachable on LAN. Backs
  /// `WanPreviewSnapshotClient.getPreviewSnapshot()`'s error-recovery path.
  static void Function(String thingName)? onPreviewKeyNeedsRegistration;
}
