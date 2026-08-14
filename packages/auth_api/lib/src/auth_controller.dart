import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_api_config.dart';
import 'auth_session.dart';
import 'cognito_auth_client.dart';
import 'cognito_identity_client.dart';

enum AuthStatus {
  /// Session hasn't been restored from storage yet — callers should show a loading state, not
  /// the sign-in screen, so a logged-in user never sees a flash of the login screen on launch.
  unknown,
  unauthenticated,
  authenticated,
}

/// App-wide session orchestration — owns the current [AuthSession], persistence, silent
/// refresh, and sign-out. A `ChangeNotifier` singleton so multiple screens can listen without
/// threading state through constructors.
///
/// **Must be configured once before use** — call [configure] at app startup (mirrors
/// `camera_api`'s `WanAuth` hook-wiring pattern). This package never reads a dart-define or an
/// app-specific store directly; everything it needs beyond raw Cognito calls is either passed in
/// via [configure] or supplied through the [onSignOut]/[onSessionEstablished] hooks, so it stays
/// reusable across different Cognito accounts/regions and different apps' local-data stores.
class AuthController extends ChangeNotifier {
  AuthController._();
  static final AuthController instance = AuthController._();

  CognitoAuthClient? _client;
  CognitoIdentityClient? _identityClient;

  /// Called once at app startup (e.g. in `main.dart`), before the first [restore] call.
  ///
  /// - [onSignOut]: callbacks run (in order) during [signOut], after the server-side session is
  ///   invalidated — this is where an app clears its own account-scoped local data (camera list,
  ///   settings caches, alert history, etc.). This package has no knowledge of what local data
  ///   an app keeps; it only guarantees these run before the auth state itself flips to
  ///   unauthenticated.
  /// - [onSessionEstablished]: called (fire-and-forget, best-effort — a failure here must never
  ///   block sign-in/restore) whenever a session becomes active or is refreshed, given the new
  ///   [AuthSession]. Use this for any app-specific "now that we have a token" side effect (e.g.
  ///   attaching an IoT policy via a Lambda call) — this package performs no such side effect
  ///   itself.
  static void configure(
    AuthApiConfig config, {
    List<Future<void> Function()> onSignOut = const [],
    Future<void> Function(AuthSession session)? onSessionEstablished,
  }) {
    instance._client = CognitoAuthClient(config);
    instance._identityClient = CognitoIdentityClient(config);
    instance._onSignOut = onSignOut;
    instance._onSessionEstablished = onSessionEstablished;
  }

  List<Future<void> Function()> _onSignOut = const [];
  Future<void> Function(AuthSession session)? _onSessionEstablished;

  CognitoAuthClient get _requireClient {
    final client = _client;
    if (client == null) {
      throw StateError('AuthController.configure() must be called before use');
    }
    return client;
  }

  CognitoIdentityClient get _requireIdentityClient {
    final client = _identityClient;
    if (client == null) {
      throw StateError('AuthController.configure() must be called before use');
    }
    return client;
  }

  AuthStatus status = AuthStatus.unknown;
  AuthSession? session;
  AwsCredentials? _awsCredentials;

  /// Set on a failed sign-in/sign-up/reset/change-password call for the screen to read once and
  /// clear — kept here rather than returned from the call itself so a forced-relogin path (no
  /// screen awaiting a Future) can also surface an error the same way.
  String? lastError;

  /// Distinct from [lastError]: set only when [status] transitions to [AuthStatus.unauthenticated]
  /// because a refresh genuinely failed (the refresh token itself is no longer valid) — not on a
  /// normal, user-initiated [signOut]. A UI can use this to show "your session expired, please
  /// sign in again" instead of silently landing back on the sign-in screen with no explanation.
  /// Read-once, like [lastError] — callers should clear it after showing it (or it's cleared
  /// automatically on the next successful [signIn]).
  String? sessionExpiredMessage;

  Timer? _refreshTimer;

  /// Called once at app startup, after [configure], before the first frame — restores a
  /// persisted session and refreshes it if it's already stale, so a genuinely expired session is
  /// caught immediately rather than only on the next authenticated action.
  Future<void> restore() async {
    final stored = await AuthSessionStore.instance.read();
    if (stored == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    if (stored.needsRefreshSoon) {
      final refreshed = await _tryRefresh(stored);
      if (refreshed == null) {
        // Refresh token itself is no longer valid — genuine expiry, not routine background
        // refresh. Falls back cleanly to Log In, with an explicit expired-session signal.
        await _clearLocalSession();
        status = AuthStatus.unauthenticated;
        sessionExpiredMessage = 'Your session has expired. Please sign in again.';
        notifyListeners();
        return;
      }
      session = refreshed;
    } else {
      session = stored;
    }
    status = AuthStatus.authenticated;
    _scheduleRefresh();
    notifyListeners();
    unawaited(_notifySessionEstablished());
  }

  Future<void> _notifySessionEstablished() async {
    final current = session;
    final hook = _onSessionEstablished;
    if (current == null || hook == null) return;
    try {
      await hook(current);
    } catch (_) {
      // Best-effort — see configure()'s doc comment.
    }
  }

  Future<void> signUp(String email, String password) async {
    lastError = null;
    try {
      await _requireClient.signUp(email, password);
    } on CognitoAuthException catch (e) {
      lastError = e.code == 'UsernameExistsException'
          ? 'An account with this email already exists.'
          : e.message;
      rethrow;
    }
  }

  Future<void> confirmSignUp(String email, String code) =>
      _requireClient.confirmSignUp(email, code);

  Future<void> resendConfirmationCode(String email) =>
      _requireClient.resendConfirmationCode(email);

  /// Sign-up establishes an authenticated session immediately, no separate login step, so this
  /// is called right after `confirmSignUp` succeeds, same as [signIn].
  Future<void> signIn(String email, String password) async {
    lastError = null;
    sessionExpiredMessage = null;
    try {
      final tokens = await _requireClient.initiateAuth(email, password);
      session = AuthSession.fromTokens(email, tokens);
      await AuthSessionStore.instance.write(session!);
      status = AuthStatus.authenticated;
      _scheduleRefresh();
      notifyListeners();
      unawaited(_notifySessionEstablished());
    } on CognitoAuthException catch (e) {
      // Generic message for both "no such user" and "wrong password" — anti-enumeration.
      // UserNotConfirmedException is the one case that gets its own copy (the user needs to go
      // finish sign-up, not retry the password).
      lastError = e.code == 'UserNotConfirmedException'
          ? 'Please confirm your email before signing in.'
          : 'Incorrect email or password.';
      rethrow;
    }
  }

  /// Lazily fetches/caches real, per-user AWS credentials via the Identity Pool, re-fetching
  /// once the cached ones are close to expiry. Throws `StateError` if called while
  /// unauthenticated — every WAN caller is only ever reachable from an authenticated screen, so
  /// this is a programming-error guard, not a user-facing error path.
  Future<AwsCredentials> awsCredentials() async {
    final current = session;
    if (current == null) {
      throw StateError('awsCredentials() called while unauthenticated');
    }
    final cached = _awsCredentials;
    if (cached != null && !cached.needsRefreshSoon) {
      return cached;
    }
    final fetched = await _requireIdentityClient.getCredentials(current.idToken);
    _awsCredentials = fetched;
    return fetched;
  }

  Future<void> forgotPassword(String email) => _requireClient.forgotPassword(email);

  Future<void> confirmForgotPassword(String email, String code, String newPassword) =>
      _requireClient.confirmForgotPassword(email, code, newPassword);

  /// Changes the signed-in user's own account password. Requires [session] to be non-null
  /// (throws `StateError` otherwise, same reasoning as [awsCredentials]).
  Future<void> changePassword(String previousPassword, String newPassword) async {
    final current = session;
    if (current == null) {
      throw StateError('changePassword() called while unauthenticated');
    }
    lastError = null;
    try {
      await _requireClient.changePassword(current.accessToken, previousPassword, newPassword);
    } on CognitoAuthException catch (e) {
      lastError = e.message;
      rethrow;
    }
  }

  /// Invalidates the session server-side, then runs every [onSignOut] hook registered via
  /// [configure] (in order) before flipping [status] to [AuthStatus.unauthenticated].
  Future<void> signOut() async {
    final current = session;
    if (current != null) {
      try {
        await _requireClient.globalSignOut(current.accessToken);
      } on CognitoAuthException {
        // Best-effort — if the access token is already invalid/expired server-side, there's
        // nothing left to revoke; still proceed to clear local state below.
      }
    }
    for (final hook in _onSignOut) {
      await hook();
    }
    await _clearLocalSession();
    status = AuthStatus.unauthenticated;
    sessionExpiredMessage = null; // explicit sign-out, not an expiry
    notifyListeners();
  }

  Future<AuthSession?> _tryRefresh(AuthSession stale) async {
    try {
      final tokens = await _requireClient.refresh(stale.refreshToken);
      final refreshed = AuthSession.fromTokens(stale.email, tokens);
      await AuthSessionStore.instance.write(refreshed);
      return refreshed;
    } on CognitoAuthException {
      return null;
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final current = session;
      if (current == null || !current.needsRefreshSoon) return;
      final refreshed = await _tryRefresh(current);
      if (refreshed == null) {
        // Genuine expiry discovered mid-session — force back to Log In.
        await _clearLocalSession();
        status = AuthStatus.unauthenticated;
        sessionExpiredMessage = 'Your session has expired. Please sign in again.';
        notifyListeners();
        return;
      }
      session = refreshed;
      unawaited(_notifySessionEstablished());
    });
  }

  Future<void> _clearLocalSession() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    session = null;
    _awsCredentials = null;
    await AuthSessionStore.instance.clear();
  }
}
