import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// This camera's LAN HTTPS endpoints (`/nuraeye`, `/onvif/*`) are served with a self-signed
/// certificate by design — there is no CA-issued cert for a LAN-only IP address, and no
/// certificate-pinning scheme exists yet. The existing Python reference tooling
/// (`testing_utilities/onvif_client.py`'s `_LegacyTLSAdapter`) already establishes this same
/// trust bypass for exactly this reason. `dart:io`'s default `HttpClient` rejects an untrusted
/// cert outright, which is the real cause of the "LAN unavailable" state seen when connecting
/// to a real camera — this client accepts it instead.
///
/// **Deliberately narrow:** this bypasses certificate *trust* only (the camera's cert isn't
/// signed by a CA this device trusts) — it does not disable TLS itself, and it is only ever
/// used for camera LAN connections, never a general-purpose HTTP client. If a future device
/// gets a real CA-issued cert, this can be made conditional on [CameraConnection] without
/// touching any `camera_api` call site (DESIGN.md §3's additive-evolution rule).
///
/// **Preserves outgoing header-name case (`BUG-005`, `BUG-008` Iteration 3)** — `package:http`'s
/// own `IOClient` calls `HttpHeaders.set(name, value)` without `preserveHeaderCase: true`, and
/// `dart:io` lowercases every custom header name by default when serializing a request. This
/// camera's embedded HTTP server (`bsp_http_server_getRequestHeader()` →
/// `httpd_request_get_header_field()`) looks up header names case-sensitively — first found for
/// `GET /snapshot`'s `Authorization` digest header (`BUG-005`), then again for the REST API's
/// `Authorization: Bearer <token>` header (`BUG-008` Iteration 3) once `NuraeyeClient` started
/// sending one. Fixed once, here, for every current and future `camera_api` LAN client that goes
/// through this factory — not per call site.
http.Client createCameraHttpClient() => _CasePreservingHttpClient();

class _CasePreservingHttpClient extends http.BaseClient {
  _CasePreservingHttpClient() : _inner = HttpClient() {
    _inner.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }

  final HttpClient _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final ioRequest = await _inner.openUrl(request.method, request.url);
    request.headers.forEach((name, value) {
      ioRequest.headers.set(name, value, preserveHeaderCase: true);
    });

    if (request is http.Request && request.bodyBytes.isNotEmpty) {
      ioRequest.contentLength = request.bodyBytes.length;
      ioRequest.add(request.bodyBytes);
    } else if (request.contentLength != null) {
      ioRequest.contentLength = request.contentLength!;
    }

    final ioResponse = await ioRequest.close();
    final headers = <String, String>{};
    ioResponse.headers.forEach((name, values) => headers[name] = values.join(', '));

    return http.StreamedResponse(
      ioResponse,
      ioResponse.statusCode,
      contentLength: ioResponse.contentLength == -1 ? null : ioResponse.contentLength,
      headers: headers,
      isRedirect: ioResponse.isRedirect,
      persistentConnection: ioResponse.persistentConnection,
      reasonPhrase: ioResponse.reasonPhrase,
      request: request,
    );
  }

  @override
  void close() => _inner.close(force: true);
}
