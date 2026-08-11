import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Mocks the camera's `/nuraeye/*` REST API (`FR-NE-104`/`FR-NE-105`) for `NuraeyeClient` tests.
/// Transparently answers `POST /nuraeye/session/login` with a fixed bearer token — every
/// authenticated `NuraeyeClient` call logs in once before its real request, so without this every
/// test would have to script that round trip itself — then dispatches every other request to
/// [handler]. [token] only needs to vary across calls within the same test for a session-expiry/
/// retry scenario; a fixed default is fine everywhere else.
http.Client mockNuraeyeRest(
  Future<http.Response> Function(http.Request request) handler, {
  String token = 'test-session-token',
  int expiresInSec = 1800,
  void Function()? onLogin,
}) {
  return MockClient((request) async {
    if (request.url.path == '/nuraeye/session/login') {
      onLogin?.call();
      return http.Response(
        jsonEncode({
          'error_code': 0,
          'error_msg': 'Success',
          'output': {'token': token, 'expires_in_sec': expiresInSec},
        }),
        200,
      );
    }
    return handler(request);
  });
}

/// A [handler] body for [mockNuraeyeRest] that dispatches purely on `request.url.path` — the
/// common case where a test doesn't need to also distinguish GET vs POST on the same path.
Future<http.Response> Function(http.Request) routeByPath(
  Map<String, http.Response Function(http.Request)> routes,
) {
  return (request) async {
    final route = routes[request.url.path];
    if (route == null) return http.Response('{"error_code":404,"error_msg":"not found","output":{}}', 404);
    return route(request);
  };
}

http.Response jsonOk(Map<String, dynamic> output) => http.Response(
      jsonEncode({'error_code': 0, 'error_msg': 'Success', 'output': output}),
      200,
    );

http.Response jsonError(int status, String message) => http.Response(
      jsonEncode({'error_code': status, 'error_msg': message, 'output': {}}),
      status,
    );
