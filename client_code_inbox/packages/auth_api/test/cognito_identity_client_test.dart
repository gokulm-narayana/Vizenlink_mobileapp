import 'dart:convert';

import 'package:auth_api/auth_api.dart';
import 'package:auth_api/src/cognito_identity_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const config = AuthApiConfig(
    region: 'ap-south-1',
    userPoolId: 'ap-south-1_fake',
    appClientId: 'fake-client-id',
    identityPoolId: 'ap-south-1:fake-pool-id',
  );

  test('getCredentials calls GetId then GetCredentialsForIdentity and parses the result', () async {
    final targets = <String>[];
    final client = CognitoIdentityClient(
      config,
      client: MockClient((request) async {
        final target = request.headers['X-Amz-Target']!;
        targets.add(target);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['Logins'], isA<Map<String, dynamic>>());

        if (target.endsWith('GetId')) {
          return http.Response(jsonEncode({'IdentityId': 'ap-south-1:fake-identity-id'}), 200);
        }
        expect(target, endsWith('GetCredentialsForIdentity'));
        expect(body['IdentityId'], 'ap-south-1:fake-identity-id');
        return http.Response(
          jsonEncode({
            'IdentityId': 'ap-south-1:fake-identity-id',
            'Credentials': {
              'AccessKeyId': 'AKIDEXAMPLE',
              'SecretKey': 'secret',
              'SessionToken': 'session-token',
              'Expiration': 1893456000, // 2030-01-01T00:00:00Z
            },
          }),
          200,
        );
      }),
    );

    final creds = await client.getCredentials('fake-id-token');

    expect(targets, [
      'AWSCognitoIdentityService.GetId',
      'AWSCognitoIdentityService.GetCredentialsForIdentity',
    ]);
    expect(creds, isA<AwsCredentials>());
    expect(creds.accessKeyId, 'AKIDEXAMPLE');
    expect(creds.secretKey, 'secret');
    expect(creds.sessionToken, 'session-token');
    expect(creds.expiresAt, DateTime.utc(2030, 1, 1));
  });
}
