import 'dart:convert';

import 'package:http/http.dart' as http;

import 'wan_auth.dart';

/// Fetches a WAN playback URL for a camera's KVS stream via `cloud_backend/kvs_playback_lambda`
/// — `mobile-app-android-3-video-image-pipeline/DESIGN.md` §7 item 2. Not a direct KVS call:
/// AWS rejects Cognito-federated credentials for `GetHLSStreamingSessionURL` regardless of IAM
/// policy (`kb/wiki/kvs-viewer-read-permissions-cognito-role.md`), so this goes through the
/// Lambda proxy instead, authenticated with the same Cognito ID token used for everything else
/// (not a separate credential) — the Lambda itself verifies that token before calling KVS under
/// its own plain execution role.
///
/// **Not yet cloud-verified** — no Lambda is deployed yet; see `kb/wiki/aws-iot-kvs-setup.md`
/// Part D and `testing_utilities/kvs_playback_lambda_test.py`.
///
/// **Moved into `camera_api` 2026-08-11** — see [IotCommandClient]'s doc for why/how the
/// `AuthController`/`AwsConfig` defaults became [WanAuth] hooks.
class KvsPlaybackClient {
  /// [idTokenProvider] and [client] are overridable for tests (mocking the real singleton/HTTP
  /// call out) — default to [WanAuth.idTokenProvider] / `http.Client()`.
  KvsPlaybackClient({http.Client? client, String? Function()? idTokenProvider})
    : _client = client ?? http.Client(),
      _idTokenProvider = idTokenProvider ?? WanAuth.idTokenProvider ?? (() => null);

  final http.Client _client;
  final String? Function() _idTokenProvider;

  /// Returns the HLS streaming session URL, or throws with the Lambda's error message
  /// (401 = bad/expired token, 403 = stream name outside this fleet, 502 = KVS lookup failed,
  /// e.g. the camera isn't actually streaming — caller should have sent `StartCloudStreaming`
  /// first via `IotCommandClient`).
  Future<String> getPlaybackUrl(String streamName) async {
    final idToken = _idTokenProvider();
    if (idToken == null) {
      throw StateError('getPlaybackUrl() called while unauthenticated');
    }
    final uri = Uri.parse(
      WanAuth.kvsPlaybackLambdaUrl ?? '',
    ).replace(queryParameters: {'streamName': streamName});
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(decoded['error'] as String? ?? 'KVS playback lookup failed (${response.statusCode})');
    }
    return decoded['hlsStreamingSessionUrl'] as String;
  }
}
