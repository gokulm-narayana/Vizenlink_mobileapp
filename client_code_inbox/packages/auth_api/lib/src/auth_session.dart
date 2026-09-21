import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'cognito_auth_client.dart';

/// A persisted, restorable session. [expiresAt] is computed once at store-time from Cognito's
/// `ExpiresIn` (seconds), not re-derived later, so restoring after an app restart doesn't need
/// to know when the tokens were originally issued relative to "now."
class AuthSession {
  const AuthSession({
    required this.email,
    required this.accessToken,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthSession.fromTokens(String email, CognitoTokens tokens) => AuthSession(
    email: email,
    accessToken: tokens.accessToken,
    idToken: tokens.idToken,
    refreshToken: tokens.refreshToken,
    expiresAt: DateTime.now().toUtc().add(Duration(seconds: tokens.expiresIn)),
  );

  final String email;
  final String accessToken;
  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// A margin before the real expiry so a scheduled refresh always lands before Cognito itself
  /// would reject the token, not right up against it.
  bool get needsRefreshSoon =>
      DateTime.now().toUtc().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'email': email,
    'accessToken': accessToken,
    'idToken': idToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    email: json['email'] as String,
    accessToken: json['accessToken'] as String,
    idToken: json['idToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}

/// Temporary AWS credentials from the Identity Pool credential exchange — kept in memory only by
/// [AuthController] (not persisted), re-fetched whenever the underlying [AuthSession] refreshes
/// since these are keyed to the ID token used to obtain them.
class AwsCredentials {
  const AwsCredentials({
    required this.accessKeyId,
    required this.secretKey,
    required this.sessionToken,
    required this.expiresAt,
  });

  final String accessKeyId;
  final String secretKey;
  final String sessionToken;
  final DateTime expiresAt;

  bool get needsRefreshSoon =>
      DateTime.now().toUtc().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
}

/// Android Keystore/iOS Keychain-backed persistence for [AuthSession] — real bearer tokens, not
/// just settings, so this uses secure storage rather than plain preferences.
class AuthSessionStore {
  AuthSessionStore._();
  static final AuthSessionStore instance = AuthSessionStore._();

  static const _key = 'auth_session';
  final _storage = const FlutterSecureStorage();

  Future<AuthSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(AuthSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}
