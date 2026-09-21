import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api_config.dart';
import 'auth_session.dart';
import 'cognito_auth_client.dart';

/// Identity Pool federation — `GetId` + `GetCredentialsForIdentity` against the `cognito-identity`
/// service, turning a signed-in User Pool ID token into real, temporary, per-user AWS
/// credentials. Both calls are unsigned/public APIs (no AWS credentials needed to make them) —
/// same direct-HTTP-over-JSON-API pattern as [CognitoAuthClient], no AWS SDK dependency.
class CognitoIdentityClient {
  CognitoIdentityClient(this.config, {http.Client? client}) : _client = client ?? http.Client();

  final AuthApiConfig config;
  final http.Client _client;

  Future<Map<String, dynamic>> _call(String target, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse(config.cognitoIdentityEndpoint),
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityService.$target',
      },
      body: jsonEncode(body),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final rawType = decoded['__type'] as String? ?? 'UnknownError';
      final code = rawType.contains('#') ? rawType.split('#').last : rawType;
      final message = decoded['message'] as String? ?? decoded['Message'] as String? ?? code;
      throw CognitoAuthException(code, message);
    }
    return decoded;
  }

  Future<AwsCredentials> getCredentials(String idToken) async {
    final logins = {config.loginsKey: idToken};

    final idResult = await _call('GetId', {
      'IdentityPoolId': config.identityPoolId,
      'Logins': logins,
    });
    final identityId = idResult['IdentityId'] as String;

    final credsResult = await _call('GetCredentialsForIdentity', {
      'IdentityId': identityId,
      'Logins': logins,
    });
    final creds = credsResult['Credentials'] as Map<String, dynamic>;

    return AwsCredentials(
      accessKeyId: creds['AccessKeyId'] as String,
      secretKey: creds['SecretKey'] as String,
      sessionToken: creds['SessionToken'] as String,
      // Cognito returns this as epoch seconds.
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (creds['Expiration'] as num).toInt() * 1000,
        isUtc: true,
      ),
    );
  }
}
