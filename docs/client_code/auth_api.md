# auth_api (`packages/auth_api/`)

AWS Cognito account/session layer — sign-up, sign-in, session persistence with silent refresh,
password management, and AWS credential federation. Separate pure-Dart-except-secure-storage
package (path dependency in root `pubspec.yaml`), analogous in role to `camera_api` but for "who
is signed in" rather than "how do I talk to a camera". See `packages/auth_api/API_REFERENCE.md`
for the canonical narrative doc (configuration block, live Cognito pool IDs); this file is the
per-symbol table reference.

## AuthController (`lib/src/auth_controller.dart`)

`ChangeNotifier` singleton (`AuthController.instance`) — owns session state, persistence, silent
refresh scheduling, and sign-out orchestration. Must call `configure()` once at app startup
before any other member is used.

### Methods

| Name | Signature | Purpose | Used for |
|------|-----------|---------|----------|
| configure | `static void configure(AuthApiConfig config, {List<Future<void> Function()> onSignOut = const [], Future<void> Function(AuthSession session)? onSessionEstablished})` | One-time setup: builds the internal `CognitoAuthClient`/`CognitoIdentityClient`, registers app-supplied sign-out cleanup hooks and a fire-and-forget "session established" hook. | Call once in `main.dart` before `restore()`. |
| restore | `Future<void> restore()` | Reads a persisted session from secure storage; if stale, refreshes it first. Sets `status` to `authenticated`/`unauthenticated` and schedules background refresh. | Call once at startup (e.g. during the splash screen's `appReady` future) to decide initial route (Login vs. Dashboard). |
| signUp | `Future<void> signUp(String email, String password)` | Creates a Cognito account (`UNCONFIRMED` until `confirmSignUp`). Sets `lastError` on failure. | Signup screen submit. |
| confirmSignUp | `Future<void> confirmSignUp(String email, String code)` | Completes sign-up with the emailed confirmation code. | Confirm-sign-up-code screen submit. |
| resendConfirmationCode | `Future<void> resendConfirmationCode(String email)` | Re-sends the confirmation code. | "Resend code" action on the confirm-sign-up-code screen. |
| signIn | `Future<void> signIn(String email, String password)` | Logs in, establishes and persists a session, schedules refresh. Sets `lastError` on failure (generic "incorrect email or password" for anti-enumeration, distinct copy for `UserNotConfirmedException`). | Login screen submit. |
| awsCredentials | `Future<AwsCredentials> awsCredentials()` | Lazily fetches/caches temporary AWS credentials via Identity Pool federation, re-fetching when near expiry. Throws `StateError` if unauthenticated. | Feeding `alerts_api`'s (or any other AWS-signing) credential-provider hook — not used by `camera_api`. |
| forgotPassword | `Future<void> forgotPassword(String email)` | Starts the forgot-password flow. Always appears to succeed, even for an unregistered email (anti-enumeration). | Forgot-password screen, step 1 (request code). |
| confirmForgotPassword | `Future<void> confirmForgotPassword(String email, String code, String newPassword)` | Completes the forgot-password flow with the emailed code and a new password. | Forgot-password screen, step 2 (reset). |
| changePassword | `Future<void> changePassword(String previousPassword, String newPassword)` | Changes the signed-in user's own password. Throws `StateError` if unauthenticated. Sets `lastError` on failure. | Account settings "change password" action. |
| signOut | `Future<void> signOut()` | Invalidates the session server-side (best-effort), runs every `onSignOut` hook in order, clears local session, flips `status` to `unauthenticated`. | Account screen "Sign out" action. |

### Fields / getters

| Name | Type | Purpose |
|------|------|---------|
| status | `AuthStatus` (`unknown`/`unauthenticated`/`authenticated`) | Current auth state; `unknown` until first `restore()` completes — show a loading state, not the sign-in screen, during that window. |
| session | `AuthSession?` | Current session, or `null` if unauthenticated. |
| lastError | `String?` | Set on a failed `signUp`/`signIn`/`forgotPassword`/`confirmForgotPassword`/`changePassword` call; read-once, screen should clear after showing. |
| sessionExpiredMessage | `String?` | Set only when a *forced* logout happens (background refresh found the refresh token itself invalid) — `null` on a normal user-initiated `signOut()`. Read-once. |

**Not implemented (documented limitation, not a gap to fill in integration):** no local-only
sign-out variant (`signOut()` always invalidates globally); no friendlier copy for Cognito
throttling errors (`LimitExceededException`/`TooManyRequestsException` surface with Cognito's raw
message).

## AuthSession / AwsCredentials / AuthSessionStore (`lib/src/auth_session.dart`)

### Models

| Class | Fields | Used by |
|-------|--------|---------|
| AuthSession | email: String, accessToken: String, idToken: String, refreshToken: String, expiresAt: DateTime; getters `needsRefreshSoon`, `isExpired`; `fromTokens(email, CognitoTokens)`, `toJson`/`fromJson` | `AuthController.session`, `AuthSessionStore` persistence |
| AwsCredentials | accessKeyId: String, secretKey: String, sessionToken: String, expiresAt: DateTime; getter `needsRefreshSoon` | `AuthController.awsCredentials()` return type |

### AuthSessionStore

Singleton (`AuthSessionStore.instance`) wrapping `flutter_secure_storage` (Android
Keystore/iOS Keychain) — real bearer tokens, not settings, so it's secure storage rather than
plain preferences.

| Name | Signature | Purpose | Used for |
|------|-----------|---------|----------|
| read | `Future<AuthSession?> read()` | Reads and decodes the persisted session, or `null`. | Internal to `AuthController.restore()` — not normally called directly by UI. |
| write | `Future<void> write(AuthSession session)` | Encodes and persists a session. | Internal to `AuthController.signIn()`/refresh. |
| clear | `Future<void> clear()` | Deletes the persisted session. | Internal to `AuthController.signOut()`/forced-expiry paths. |

## AuthApiConfig (`lib/src/auth_api_config.dart`)

Plain config value object — deployment-specific Cognito identifiers, supplied by the app (this
package never reads a dart-define or environment itself).

| Class | Fields | Used by |
|-------|--------|---------|
| AuthApiConfig | region: String, userPoolId: String, appClientId: String, identityPoolId: String; getters `cognitoIdpEndpoint`, `cognitoIdentityEndpoint`, `loginsKey` | `AuthController.configure()`, `CognitoAuthClient`, `CognitoIdentityClient` |

Live values for this project's `vizenlink-mobile` Cognito pool are documented in
`packages/auth_api/API_REFERENCE.md` § Configuration.

## CognitoAuthClient (`lib/src/cognito_auth_client.dart`)

Direct HTTP client for the Cognito Identity Provider JSON API — no AWS SDK dependency. Used
internally by `AuthController`; not normally called directly by screens.

### API calls

| Name | HTTP method | Endpoint | Request model | Response model | Auth/headers | Errors |
|------|-------------|----------|----------------|-----------------|--------------|--------|
| signUp | POST | `{cognitoIdpEndpoint}` (`X-Amz-Target: AWSCognitoIdentityProviderService.SignUp`) | `{ClientId, Username, Password, UserAttributes}` | — (void) | none (public API) | throws `CognitoAuthException(code, message)`, e.g. `UsernameExistsException` |
| confirmSignUp | POST | same endpoint, target `ConfirmSignUp` | `{ClientId, Username, ConfirmationCode}` | — (void) | none | `CognitoAuthException` |
| resendConfirmationCode | POST | same endpoint, target `ResendConfirmationCode` | `{ClientId, Username}` | — (void) | none | `CognitoAuthException` |
| initiateAuth | POST | same endpoint, target `InitiateAuth`, `AuthFlow: USER_PASSWORD_AUTH` | `{ClientId, AuthFlow, AuthParameters: {USERNAME, PASSWORD}}` | `CognitoTokens` (parsed from `AuthenticationResult`) | none | `CognitoAuthException`, e.g. `NotAuthorizedException`, `UserNotConfirmedException` |
| refresh | POST | same endpoint, target `InitiateAuth`, `AuthFlow: REFRESH_TOKEN_AUTH` | `{ClientId, AuthFlow, AuthParameters: {REFRESH_TOKEN}}` | `CognitoTokens` (`RefreshToken` falls back to the input token since Cognito doesn't reissue it) | none | `CognitoAuthException` |
| globalSignOut | POST | same endpoint, target `GlobalSignOut` | `{AccessToken}` | — (void) | bearer access token in body | `CognitoAuthException` |
| forgotPassword | POST | same endpoint, target `ForgotPassword` | `{ClientId, Username}` | — (void) | none | `CognitoAuthException`; always appears to succeed for unregistered emails (anti-enumeration) |
| confirmForgotPassword | POST | same endpoint, target `ConfirmForgotPassword` | `{ClientId, Username, ConfirmationCode, Password}` | — (void) | none | `CognitoAuthException`, e.g. `CodeMismatchException`, `InvalidPasswordException` |
| changePassword | POST | same endpoint, target `ChangePassword` | `{AccessToken, PreviousPassword, ProposedPassword}` | — (void) | bearer access token in body | `CognitoAuthException` |

### Models

| Class | Fields | Used by |
|-------|--------|---------|
| CognitoAuthException | code: String, message: String | thrown by every `CognitoAuthClient`/`CognitoIdentityClient` call on non-200 |
| CognitoTokens | accessToken: String, idToken: String, refreshToken: String, expiresIn: int (seconds); `fromAuthenticationResult(result, {fallbackRefreshToken})` | `initiateAuth`, `refresh` responses; consumed by `AuthSession.fromTokens` |

## CognitoIdentityClient (`lib/src/cognito_identity_client.dart`)

Identity Pool federation — exchanges a signed-in User Pool ID token for temporary, per-user AWS
credentials. Used internally by `AuthController.awsCredentials()`.

### API calls

| Name | HTTP method | Endpoint | Request model | Response model | Auth/headers | Errors |
|------|-------------|----------|----------------|-----------------|--------------|--------|
| getCredentials | POST (two calls: `GetId` then `GetCredentialsForIdentity`) | `{cognitoIdentityEndpoint}` (`X-Amz-Target: AWSCognitoIdentityService.GetId` / `...GetCredentialsForIdentity`) | `{IdentityPoolId, Logins}` then `{IdentityId, Logins}` (`Logins` keyed by `AuthApiConfig.loginsKey`, valued by the caller's ID token) | `AwsCredentials` | none (public APIs) | `CognitoAuthException` |

## auth_api.dart (`lib/auth_api.dart`)

Barrel export — re-exports `AuthApiConfig`, `AuthController`, `AuthSession`/`AwsCredentials`
(not `AuthSessionStore` — internal), `CognitoAuthException`/`CognitoTokens` (not the raw HTTP
clients — internal).
