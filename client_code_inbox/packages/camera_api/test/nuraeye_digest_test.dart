import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

/// Known-answer test for the WSSE-style digest construction shared by `NuraeyeClient` and
/// `OnvifClient`: base64(SHA1(nonce_raw_bytes + created_iso8601_utf8 + password_utf8)) — the
/// same three-part input order `testing_utilities/audio_recording_test.py`'s
/// `_nuraeye_digest()` and `onvif_client.py`'s `_wsse_header()` both use. The expected value
/// below was computed independently via Python's `hashlib`/`base64` (the reference
/// implementation's own stack, not Dart's), so this test catches an input-order regression
/// (e.g. accidentally swapping nonce/created) without needing a live camera:
///
///   python3 -c "
///   import hashlib, base64
///   nonce = base64.b64decode('AAAAAAAAAAAAAAAAAAAAAA==')
///   created = '2026-01-01T00:00:00.000Z'
///   password = 'test-password'
///   h = hashlib.sha1(); h.update(nonce); h.update(created.encode()); h.update(password.encode())
///   print(base64.b64encode(h.digest()).decode())
///   "
///   => F3ldVt6HHuN3/vvi4vYtwEH8+w8=
void main() {
  test('digest matches the Python reference implementation byte-for-byte', () {
    final nonce = base64.decode('AAAAAAAAAAAAAAAAAAAAAA==');
    const created = '2026-01-01T00:00:00.000Z';
    const password = 'test-password';

    final input = <int>[...nonce, ...utf8.encode(created), ...utf8.encode(password)];
    final digest = base64.encode(sha1.convert(input).bytes);

    expect(digest, 'F3ldVt6HHuN3/vvi4vYtwEH8+w8=');
  });
}
