import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Shared WSSE-style digest construction — `base64(SHA1(nonce_raw_bytes + created_iso8601 +
/// password))` — used identically by `/nuraeye` JSON auth ([NuraeyeClient]), ONVIF SOAP
/// WS-UsernameToken headers ([OnvifImagingClient]), and `GET /snapshot`'s `Authorization`
/// header ([SnapshotClient]). One implementation so the three call sites can never silently
/// diverge from each other or from the real reference implementation
/// (`testing_utilities/onvif_client.py`'s `_wsse_header()`/`_snapshot_auth_header()`).
class WsseDigest {
  WsseDigest._({required this.createdIso, required this.nonceBase64, required this.digestBase64});

  factory WsseDigest.generate(String password) {
    final created = DateTime.now().toUtc();
    final createdIso = _formatCreated(created);
    final random = Random.secure();
    final nonceBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final nonceBase64 = base64.encode(nonceBytes);

    return WsseDigest._(
      createdIso: createdIso,
      nonceBase64: nonceBase64,
      digestBase64: computeDigest(password, nonceBase64: nonceBase64, createdIso: createdIso),
    );
  }

  final String createdIso;
  final String nonceBase64;
  final String digestBase64;

  /// Computes `base64(SHA1(nonce_raw_bytes + created_iso8601 + plaintext))` for an
  /// already-known nonce/created pair — used to locally verify a server reply against a
  /// *different* plaintext than the one originally sent (e.g. `AreYouNuraeyeDevice`'s response
  /// digest), mirroring the archived `android_app`'s `NuraeyeService.areYouNuraeyeDevice()`,
  /// which recomputes and compares rather than trusting a bare success flag.
  static String computeDigest(
    String plaintext, {
    required String nonceBase64,
    required String createdIso,
  }) {
    final digestInput = <int>[
      ...base64.decode(nonceBase64),
      ...utf8.encode(createdIso),
      ...utf8.encode(plaintext),
    ];
    return base64.encode(sha1.convert(digestInput).bytes);
  }

  /// Matches the reference implementation's `%Y-%m-%dT%H:%M:%S.000Z` — millisecond precision is
  /// fixed at `.000`, not the actual sub-second time, since the firmware only checks the digest
  /// input's byte content, not real clock precision.
  static String _formatCreated(DateTime utc) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)}'
        'T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}.000Z';
  }
}
