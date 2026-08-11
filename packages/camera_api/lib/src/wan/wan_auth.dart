import 'package:pointycastle/export.dart';

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

  /// The signed-in session's current Cognito ID token, or `null` if not signed in. Backs every
  /// AWS IoT command (`IotCommandClient`) and KVS playback lookup (`KvsPlaybackClient`).
  static String? Function()? idTokenProvider;

  /// The deployed `cloud_backend/kvs_playback_lambda` Function URL
  /// (`kb/wiki/aws-iot-kvs-setup.md` Part D) — every WAN command and KVS playback lookup goes
  /// through this one relay. Fleet-wide, not per-camera or secret — set once from whatever
  /// build-time config mechanism the app uses (e.g. `--dart-define`).
  static String? kvsPlaybackLambdaUrl;

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
