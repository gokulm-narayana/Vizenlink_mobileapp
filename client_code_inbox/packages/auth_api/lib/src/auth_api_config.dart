/// Deployment-specific Cognito identifiers — supplied by the app (normally sourced from
/// `--dart-define` at build time), never read from the environment by this package itself. See
/// `auth_api`'s `API_REFERENCE.md` § "Configuration" for why: this package must stay reusable
/// across different Cognito pools/accounts/regions without a source change.
class AuthApiConfig {
  const AuthApiConfig({
    required this.region,
    required this.userPoolId,
    required this.appClientId,
    required this.identityPoolId,
  });

  final String region;
  final String userPoolId;
  final String appClientId;
  final String identityPoolId;

  String get cognitoIdpEndpoint => 'https://cognito-idp.$region.amazonaws.com/';

  String get cognitoIdentityEndpoint => 'https://cognito-identity.$region.amazonaws.com/';

  String get _loginsKey => 'cognito-idp.$region.amazonaws.com/$userPoolId';

  /// The `Logins` map key Cognito Identity's `GetId`/`GetCredentialsForIdentity` calls expect —
  /// exposed as a getter (not just used internally) since it's a stable, documented part of the
  /// wire contract, not an implementation detail.
  String get loginsKey => _loginsKey;
}
