import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-camera cache of the camera-generated shared AES-256 preview key — backs
/// `WanAuth.previewSharedKeyProvider`/`onPreviewKeyNeedsRegistration`
/// (`packages/camera_api/lib/src/wan/wan_auth.dart`), which
/// `WanPreviewSnapshotClient` uses to decrypt end-to-end-encrypted WAN
/// preview snapshots.
///
/// **Redesigned 2026-08-21**: the camera now generates and owns the preview
/// key itself (`GetPreviewKey`, LAN-only) instead of this device generating
/// an RSA keypair and registering its public half with `RegisterPreviewKey`
/// — any number of apps can fetch the same shared key, not just the last one
/// to register. This class now just caches, per camera, whatever key was
/// last fetched over LAN.
class PreviewKeyStore {
  PreviewKeyStore._();

  static final PreviewKeyStore instance = PreviewKeyStore._();

  final _storage = const FlutterSecureStorage();

  String _keyFor(String thingName) => 'preview_shared_key_$thingName';

  /// The cached shared key for [thingName], or `null` if this device has
  /// never fetched one for that camera over LAN yet. Matches
  /// `WanAuth.previewSharedKeyProvider`'s signature directly.
  Future<Uint8List?> getSharedKey(String thingName) async {
    final stored = await _storage.read(key: _keyFor(thingName));
    if (stored == null) return null;
    return base64Decode(stored);
  }

  /// Whether a shared key has already been fetched and cached for
  /// [thingName] — used to gate a LAN sync so it doesn't re-fetch
  /// `GetPreviewKey` on every single reachability check, only once per
  /// camera (or again after [flagNeedsRefetch]).
  Future<bool> hasSharedKey(String thingName) async =>
      await _storage.read(key: _keyFor(thingName)) != null;

  /// Caches [key] as fetched from the camera's `GetPreviewKey` response.
  Future<void> storeSharedKey(String thingName, Uint8List key) =>
      _storage.write(key: _keyFor(thingName), value: base64Encode(key));

  /// Called via `WanAuth.onPreviewKeyNeedsRegistration` when the camera
  /// reports it has no preview key generated (e.g. a factory reset wiped
  /// it) — clears the local cache so the next LAN sync re-fetches
  /// `GetPreviewKey` automatically instead of the camera silently failing
  /// every WAN preview request until the user notices and re-adds it
  /// manually.
  Future<void> flagNeedsRefetch(String thingName) =>
      _storage.delete(key: _keyFor(thingName));
}
