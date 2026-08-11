// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'rest_result.dart';

/// Owns the camera's host/port/scheme and bearer token, and unwraps every response's
/// SuccessEnvelope/ErrorResponse shape (`{error_code, error_msg, output}`) into a
/// `RestResult<Map<String, dynamic>>`. Every generated domain client
/// (`RestAudioClient`, `RestVideoImageClient`, ...) calls through this — never package:http
/// directly. `lan/nuraeye/nuraeye_client.dart`'s hand-written `NuraeyeClient` also builds on
/// this directly (not on the generated per-group clients, which nothing currently calls).
class NuraeyeRestClient {
  NuraeyeRestClient({
    required this.host,
    this.port,
    this.scheme = 'https',
    this.timeout = const Duration(seconds: 10),
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String host;
  final int? port;
  final String scheme;
  final Duration timeout;
  final http.Client _http;

  String? _token;

  /// Set after a successful [sessionLogin]-style call; cleared on logout.
  void setToken(String? token) => _token = token;

  Uri _uri(String path) => Uri(scheme: scheme, host: host, port: port, path: path);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<RestResult<Map<String, dynamic>>> get(String path) async {
    try {
      final response = await _http.get(_uri(path), headers: _headers).timeout(timeout);
      return _unwrap(response);
    } on TimeoutException {
      return const RestTimeout();
    } catch (e) {
      return RestFailure(e.toString());
    }
  }

  Future<RestResult<Map<String, dynamic>>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _http
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(timeout);
      return _unwrap(response);
    } on TimeoutException {
      return const RestTimeout();
    } catch (e) {
      return RestFailure(e.toString());
    }
  }

  RestResult<Map<String, dynamic>> _unwrap(http.Response response) {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return RestFailure('Malformed response body', statusCode: response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final output = decoded['output'];
      return RestSuccess(output is Map<String, dynamic> ? output : const <String, dynamic>{});
    }

    final message = decoded['error_msg'] as String? ?? 'Request failed';
    return RestFailure(message, statusCode: response.statusCode);
  }
}
