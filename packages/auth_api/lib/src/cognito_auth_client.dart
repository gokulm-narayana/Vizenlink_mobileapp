import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api_config.dart';

/// Thrown for every Cognito Identity Provider error response. [code] is the exception name
/// Cognito returns in the `__type` field (e.g. `UsernameExistsException`,
/// `NotAuthorizedException`, `UserNotConfirmedException`, `CodeMismatchException`,
/// `InvalidPasswordException`, `LimitExceededException`, `TooManyRequestsException`) — callers
/// map specific codes to specific copy where the anti-enumeration/duplicate-email requirements
/// need it and fall back to [friendlyMessage] otherwise.
class CognitoAuthException implements Exception {
  const CognitoAuthException(this.code, this.message);

  final String code;
  final String message;

  /// User-facing text for [code]s common enough across every Cognito-calling flow to warrant one
  /// shared mapping, rather than each screen inventing its own — currently just Cognito's
  /// throttling codes. Added 2026-08-14: a real "limit exceed" report on repeated
  /// `ChangePassword` attempts turned out to be Cognito's own `LimitExceededException`
  /// surfacing its raw AWS message text verbatim (no code fix needed on the throttle itself —
  /// it's expected AWS behavior — but the copy shown to the user was bad). Any call site with a
  /// more specific mapping for a given [code] (anti-enumeration text for a wrong password,
  /// "email already exists" for sign-up, etc.) should check that first and only fall back to
  /// this getter — never call it unconditionally ahead of a call-specific check, or a throttle
  /// during e.g. sign-in would lose the sign-in-specific copy for the codes that already have
  /// one.
  String get friendlyMessage {
    switch (code) {
      case 'LimitExceededException':
      case 'TooManyRequestsException':
        return 'Too many attempts. Please wait a few minutes and try again.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'CognitoAuthException($code: $message)';
}

/// Result of a successful [CognitoAuthClient.initiateAuth]/[CognitoAuthClient.refresh] call.
class CognitoTokens {
  const CognitoTokens({
    required this.accessToken,
    required this.idToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory CognitoTokens.fromAuthenticationResult(
    Map<String, dynamic> result, {
    String? fallbackRefreshToken,
  }) {
    return CognitoTokens(
      accessToken: result['AccessToken'] as String,
      idToken: result['IdToken'] as String,
      // Refresh flows don't return a new RefreshToken (Cognito keeps issuing the same one) —
      // the caller passes the existing one through in that case.
      refreshToken: (result['RefreshToken'] as String?) ?? fallbackRefreshToken ?? '',
      expiresIn: result['ExpiresIn'] as int,
    );
  }

  final String accessToken;
  final String idToken;
  final String refreshToken;

  /// Seconds, per Cognito's `ExpiresIn` (access/ID tokens are 1 hour by default).
  final int expiresIn;
}

/// Direct HTTP client for the Cognito Identity Provider JSON API
/// (`AWSCognitoIdentityProviderService.*` actions) — no AWS SDK dependency, calling the
/// well-defined JSON wire protocol straight over `http`. `SignUp`/`InitiateAuth` etc. are
/// public, unauthenticated-request API calls — they need only the App Client ID, never AWS
/// credentials or a signature.
class CognitoAuthClient {
  CognitoAuthClient(this.config, {http.Client? client}) : _client = client ?? http.Client();

  final AuthApiConfig config;
  final http.Client _client;

  Future<Map<String, dynamic>> _call(String target, Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse(config.cognitoIdpEndpoint),
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'AWSCognitoIdentityProviderService.$target',
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

  /// Creates the account; the user is `UNCONFIRMED` until [confirmSignUp].
  /// Throws `CognitoAuthException('UsernameExistsException', ...)` for a duplicate email.
  /// [name], if given, is stored as Cognito's standard `name` attribute.
  Future<void> signUp(String email, String password, {String? name}) =>
      _call('SignUp', {
        'ClientId': config.appClientId,
        'Username': email,
        'Password': password,
        'UserAttributes': [
          {'Name': 'email', 'Value': email},
          if (name != null && name.trim().isNotEmpty)
            {'Name': 'name', 'Value': name.trim()},
        ],
      });

  /// Completes sign-up with the code emailed to the user.
  Future<void> confirmSignUp(String email, String code) => _call('ConfirmSignUp', {
    'ClientId': config.appClientId,
    'Username': email,
    'ConfirmationCode': code,
  });

  Future<void> resendConfirmationCode(String email) => _call('ResendConfirmationCode', {
    'ClientId': config.appClientId,
    'Username': email,
  });

  /// Login. Cognito itself already returns the same `NotAuthorizedException`/generic error for
  /// both "wrong password" and "no such user" (it doesn't disclose which) — anti-enumeration
  /// behavior callers get for free, without needing to special-case anything here except mapping
  /// `UserNotConfirmedException` to its own distinct "confirm your email first" case.
  Future<CognitoTokens> initiateAuth(String email, String password) async {
    final result = await _call('InitiateAuth', {
      'ClientId': config.appClientId,
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'AuthParameters': {'USERNAME': email, 'PASSWORD': password},
    });
    return CognitoTokens.fromAuthenticationResult(
      result['AuthenticationResult'] as Map<String, dynamic>,
    );
  }

  /// Silent session refresh — called before the access/ID token expires.
  Future<CognitoTokens> refresh(String refreshToken) async {
    final result = await _call('InitiateAuth', {
      'ClientId': config.appClientId,
      'AuthFlow': 'REFRESH_TOKEN_AUTH',
      'AuthParameters': {'REFRESH_TOKEN': refreshToken},
    });
    return CognitoTokens.fromAuthenticationResult(
      result['AuthenticationResult'] as Map<String, dynamic>,
      fallbackRefreshToken: refreshToken,
    );
  }

  /// Sign-out — invalidates every refresh/access token for this user server-side (not just
  /// clearing them locally), so a captured token can't be replayed afterward. This is the only
  /// sign-out variant this package exposes today — there is no local-only (skip server call)
  /// alternative; a caller wanting that can simply not call this method before clearing its own
  /// local session state.
  Future<void> globalSignOut(String accessToken) =>
      _call('GlobalSignOut', {'AccessToken': accessToken});

  /// Always succeeds from the caller's point of view even for an unregistered email (Cognito's
  /// own behavior when "prevent user existence errors" is enabled on the App Client), satisfying
  /// an anti-enumeration requirement on password reset the same way [initiateAuth] does on login.
  Future<void> forgotPassword(String email) =>
      _call('ForgotPassword', {'ClientId': config.appClientId, 'Username': email});

  Future<void> confirmForgotPassword(String email, String code, String newPassword) =>
      _call('ConfirmForgotPassword', {
        'ClientId': config.appClientId,
        'Username': email,
        'ConfirmationCode': code,
        'Password': newPassword,
      });

  /// Changes the signed-in user's own password (distinct from [forgotPassword]'s
  /// forgot-password flow, which doesn't require knowing the current password). Requires a
  /// valid, non-expired access token.
  Future<void> changePassword(
    String accessToken,
    String previousPassword,
    String proposedPassword,
  ) => _call('ChangePassword', {
    'AccessToken': accessToken,
    'PreviousPassword': previousPassword,
    'ProposedPassword': proposedPassword,
  });
}
