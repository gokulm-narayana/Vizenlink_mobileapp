import 'dart:io';
import 'dart:typed_data';

import '../../camera_connection.dart';
import '../../camera_result.dart';
import '../wsse_digest.dart';

/// `GET /snapshot` (`FR-CF-013`, `FR-MOB-032/069`) — still-image capture. Uses the same
/// stateless WSSE-style digest as [NuraeyeClient]/[OnvifImagingClient], delivered as an
/// `Authorization` HTTP header instead of a JSON/SOAP body field, matching
/// `camera_app/camera.c`'s `prvCheckSnapshotAuth()` and the reference implementation in
/// `testing_utilities/onvif_client.py`'s `_snapshot_auth_header()`.
///
/// **Uses `dart:io`'s `HttpClient` directly, not `package:http` (unlike every other client in
/// this package) — `BUG-005`, found 2026-07-29.** `package:http`'s `IOClient` calls
/// `HttpHeaders.set(name, value)` without `preserveHeaderCase: true`, and `dart:io` lowercases
/// every custom header name by default when serializing the request — so the camera actually
/// received `authorization: ...`, not `Authorization: ...`. This endpoint is the only one in
/// `camera_api` that carries its auth in an HTTP *header* rather than a request *body*
/// (`/nuraeye`'s JSON body, ONVIF's SOAP body) — confirmed via the camera's own serial log
/// (`prvCheckSnapshotAuth`'s `LOG_W("Snapshot request missing Authorization header")`), which
/// is why this bug never showed up in `NuraeyeClient`/`OnvifImagingClient`. Setting the header
/// with `preserveHeaderCase: true` (a `dart:io`-only capability, not exposed through
/// `package:http`'s `Map<String, String>` headers API) fixes it.
class SnapshotClient {
  SnapshotClient(this.connection) : _http = HttpClient() {
    _http.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }

  final CameraConnection connection;
  final HttpClient _http;

  /// [profile] — see `CameraConnection.snapshotEndpoint`'s doc for the `"high"`/`"medium"`/
  /// `"low"` choice; defaults to `"high"` here too, matching that default.
  Future<CameraResult<Uint8List>> getSnapshot({
    Duration timeout = const Duration(seconds: 10),
    String profile = 'high',
  }) async {
    final digest = WsseDigest.generate(connection.password);
    final authHeader = 'Digest username="${connection.username}", '
        'nonce="${digest.nonceBase64}", created="${digest.createdIso}", '
        'response="${digest.digestBase64}"';

    try {
      final request = await _http
          .getUrl(connection.snapshotEndpoint(profile: profile))
          .timeout(timeout);
      request.headers.set('Authorization', authHeader, preserveHeaderCase: true);
      final response = await request.close().timeout(timeout);

      if (response.statusCode != 200) {
        // Drain the response body so the underlying connection can be reused/closed cleanly.
        await response.drain<void>();
        return CameraFailure('HTTP ${response.statusCode}: snapshot request rejected');
      }

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return CameraSuccess(Uint8List.fromList(bytes));
    } on Exception catch (e) {
      return CameraFailure(e.toString());
    }
  }

  void close() => _http.close();
}
