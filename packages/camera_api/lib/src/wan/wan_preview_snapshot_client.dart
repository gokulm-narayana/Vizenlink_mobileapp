import 'dart:convert';
import 'dart:typed_data';

import 'package:camera_api/camera_api.dart';
import 'package:pointycastle/export.dart';


/// WAN reference-snapshot preview, end-to-end encrypted (`FR-MOB-101`/`FR-NE-108`/
/// `FR-SECL-017`) — distinct from `FR-MOB-032`'s persisted WAN snapshot mechanism. The camera
/// encrypts the frame before it ever leaves the device; this client is the only place that ever
/// holds the plaintext bytes again, after decrypting locally with the device's own cached
/// shared key ([WanAuth.previewSharedKeyProvider]) — the cloud relay only ever carries
/// ciphertext.
///
/// Callers must not persist the returned bytes (no gallery save, no cache file) — this is a
/// transient configuration-screen backdrop, not a kept/shared snapshot; see `FR-MOB-101`'s
/// "what this item does not do" note.
///
/// **Moved into `camera_api` 2026-08-11** — [WanAuth.previewSharedKeyProvider]/
/// [WanAuth.onPreviewKeyNeedsRegistration] replace the direct `PreviewKeyStore` dependency
/// (app-layer, `flutter_secure_storage`-backed) this used to have.
///
/// **Redesigned 2026-08-21**: the camera-side envelope no longer carries a per-request
/// RSA-wrapped AES key (`wrapped_key`) — decryption now uses the persisted shared key from
/// [WanAuth.previewSharedKeyProvider] directly against AES-256-GCM.
class WanPreviewSnapshotClient {
  WanPreviewSnapshotClient(this.thingName, {IotCommandClient? iotCommandClient})
    : _iot = iotCommandClient ?? IotCommandClient(thingName);

  final String thingName;
  final IotCommandClient _iot;

  /// [timeout] default of 25s reflects a real round trip measured against hardware
  /// (2026-08-11): the camera's synchronous capture (up to 5s) plus RSA-2048-OAEP encryption on
  /// embedded hardware pushed this past the Lambda relay's generic 12s default, which had been
  /// silently reporting every `GetPreviewSnapshot` call as a timeout even though the camera did
  /// reply. See `_publish_and_wait`'s `timeoutSeconds` override in `handler.py`.
  Future<CameraResult<Uint8List>> getPreviewSnapshot({
    Duration timeout = const Duration(seconds: 25),
  }) async {
    try {
      final sharedKey = await WanAuth.previewSharedKeyProvider?.call(thingName);
      if (sharedKey == null) {
        return const CameraFailure(
          'No preview key fetched yet on this device — open a settings screen on LAN once '
          'first so the camera can hand it out.',
        );
      }

      final output = await _iot.sendCommandWithResponse(
        IotCommandClient.getPreviewSnapshot,
        timeoutSeconds: timeout.inMilliseconds / 1000.0,
      );
      if (output == null) return const CameraTimeout();

      final error = output['error'];
      if (error is String) {
        if (error == 'no_preview_key_registered') {
          // Likely a factory reset wiped the camera's previously-registered key — flagged for
          // automatic re-registration next time the app is on LAN with this camera (see
          // live_view_screen.dart's `_onLiveViewState`), rather than requiring the user to
          // notice and re-add the camera manually.
          WanAuth.onPreviewKeyNeedsRegistration?.call(thingName);
          return const CameraFailure(
            'Camera has no preview key registered — it will be re-registered automatically '
            'next time this camera is reachable on your home network.',
          );
        }
        return CameraFailure(error);
      }

      final nonceB64 = output['nonce'];
      final tagB64 = output['tag'];
      final dataB64 = output['data'];
      if (nonceB64 is! String || tagB64 is! String || dataB64 is! String) {
        return CameraFailure('GetPreviewSnapshot response missing fields: $output');
      }

      final nonce = base64Decode(nonceB64);
      final tag = base64Decode(tagB64);
      final ciphertext = base64Decode(dataB64);

      final plaintext = _decryptAesGcm(ciphertext, tag, nonce, sharedKey);
      return CameraSuccess(plaintext);
    } catch (e) {
      return CameraFailure(e.toString());
    }
  }

  Uint8List _decryptAesGcm(Uint8List ciphertext, Uint8List tag, Uint8List nonce, Uint8List key) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), tag.length * 8, nonce, Uint8List(0)));
    final combined = Uint8List(ciphertext.length + tag.length)
      ..setRange(0, ciphertext.length, ciphertext)
      ..setRange(ciphertext.length, ciphertext.length + tag.length, tag);
    return cipher.process(combined);
  }
}
