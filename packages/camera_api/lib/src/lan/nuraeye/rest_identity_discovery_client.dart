// GENERATED CODE — DO NOT HAND-EDIT.
//
// Produced by tools/generate_dart_rest_client.py from design/Camera-REST-API.openapi.yaml.
// Fix the generator and re-run `python3 tools/generate_dart_rest_client.py` to regenerate.

import 'nuraeye_rest_client.dart';
import 'rest_result.dart';

class RestIdentityDiscoveryClient {
  RestIdentityDiscoveryClient(this._client);

  final NuraeyeRestClient _client;

  /// REST equivalent of the legacy AreYouNuraeyeDevice action
  Future<RestResult<IdentityChallengeResponse>> identityChallenge({required String nonce, required String created, required String digest}) {
    final body = <String, dynamic>{
      'nonce': nonce,
      'created': created,
      'digest': digest,
    };
    return _client.post('/nuraeye/identity', body).then((result) => result.map((json) => IdentityChallengeResponse.fromJson(json)));
  }

  /// Exchange device credentials for a bearer token (FR-NE-105)
  Future<RestResult<SessionLoginResponse>> sessionLogin({required String username, required String passwordDigest, required String nonce, required String created, String? clientLabel}) {
    final body = <String, dynamic>{
      'auth_credentials': {
        'username': username,
        'password_digest': passwordDigest,
        'nonce': nonce,
        'created': created,
      },
      if (clientLabel != null) 'client_label': clientLabel,
    };
    return _client.post('/nuraeye/session/login', body).then((result) => result.map((json) => SessionLoginResponse.fromJson(json)));
  }

  /// Revoke the presented bearer token (idempotent)
  Future<RestResult<void>> sessionLogout() {
    return _client.post('/nuraeye/session/logout', const <String, dynamic>{});
  }
}

class IdentityChallengeResponse {
  final String? reply;

  const IdentityChallengeResponse({this.reply});

  factory IdentityChallengeResponse.fromJson(Map<String, dynamic> json) => IdentityChallengeResponse(
        reply: json['reply'] as String?,
      );
}

class SessionLoginResponse {
  final String? token;
  final int? expiresInSec;

  const SessionLoginResponse({this.token, this.expiresInSec});

  factory SessionLoginResponse.fromJson(Map<String, dynamic> json) => SessionLoginResponse(
        token: json['token'] as String?,
        expiresInSec: json['expires_in_sec'] as int?,
      );
}

