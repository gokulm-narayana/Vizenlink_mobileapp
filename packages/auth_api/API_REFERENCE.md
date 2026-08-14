# auth_api — API Reference

`auth_api` is the AWS Cognito account/session layer for the VizenLink mobile app — sign-up,
sign-in, session persistence with silent refresh, and password management. It exists so the
UI/business-logic layer has a documented, stable contract for "who is signed in" the same way
`camera_api` documents "how do I talk to a camera" — extracted 2026-08-12 alongside `alerts_api`
(see [design/WORKFLOW_EXCEPTIONS.md](../../../design/WORKFLOW_EXCEPTIONS.md)'s 2026-08-12 entry).

Unlike `camera_api`, this package is **not** pure-Dart — session persistence needs Android
Keystore/iOS Keychain (`flutter_secure_storage`), which is inherently platform-specific.

## Configuration

This package never reads a dart-define or any app-specific store itself. Call
`AuthController.configure(...)` exactly once at app startup, before the first `restore()` call:

```dart
AuthController.configure(
  const AuthApiConfig(
    region: 'ap-south-1',
    userPoolId: 'ap-south-1_RKoTtmxCi',
    appClientId: '28b1gba2nk2oe0v70obu439bu9',
    identityPoolId: 'ap-south-1:5afc6818-10ed-498f-9106-fb190aa44976',
  ),
  onSignOut: [
    () => OnboardingCameraStore.instance.clearAll(),
    () => AlertHistoryStore.instance.clear(),
    // ...any other account-scoped local data your app keeps.
  ],
  onSessionEstablished: (session) async {
    // Optional — fire-and-forget, best-effort. Any app-specific "we now have a token" side
    // effect (e.g. attaching an IoT policy) goes here, not inside this package.
  },
);
```

**The four values above are this project's real, live `vizenlink-mobile` Cognito resources —
confirmed live in the account 2026-08-06/07 and again 2026-08-12** (single AWS account, private
repo; not secrets, the same way a hostname isn't). Use them as-is; there is no separate value to
go request from anyone. If this pool is ever rotated/recreated, the new values can be supplied
without a source change via `--dart-define=COGNITO_USER_POOL_ID=...`/
`COGNITO_APP_CLIENT_ID`/`COGNITO_IDENTITY_POOL_ID` — this package's own `AuthApiConfig`
constructor doesn't care where its caller sourced the values from, but if you're consuming this
package as a standalone deliverable (not this repo's full `mobile_app/` source), the block above
is the actual, current, correct configuration to build with.

## AuthController

`AuthController.instance` — a `ChangeNotifier` singleton. Screens call methods directly and/or
`addListener`/`removeListener` to react to state changes.

| Member | Description |
|---|---|
| `status` (`AuthStatus`: `unknown`/`unauthenticated`/`authenticated`) | Current auth state. `unknown` until the first `restore()` completes — show a loading state, not the sign-in screen, during this window. |
| `session` (`AuthSession?`) | The current session, or `null` if unauthenticated. |
| `lastError` (`String?`) | Set on a failed `signUp`/`signIn`/`forgotPassword`/`confirmForgotPassword`/`changePassword` call, for the screen to read once. |
| `sessionExpiredMessage` (`String?`) | Set only when a *forced* logout happens (a refresh genuinely failed) — `null` on a normal user-initiated `signOut()`. Use to show "your session expired" instead of a silent bounce to the sign-in screen. |
| `restore()` | Call once at startup, after `configure()`. Restores a persisted session, refreshing it first if stale. |
| `signUp(email, password)` | Creates the account (`UNCONFIRMED` until `confirmSignUp`). |
| `confirmSignUp(email, code)` | Completes sign-up with the emailed code. |
| `resendConfirmationCode(email)` | Re-sends the confirmation code. |
| `signIn(email, password)` | Logs in and establishes a session immediately. |
| `forgotPassword(email)` | Starts the forgot-password flow (always appears to succeed, even for an unregistered email — anti-enumeration). |
| `confirmForgotPassword(email, code, newPassword)` | Completes the forgot-password flow. |
| `changePassword(previousPassword, newPassword)` | Changes the signed-in user's password. Throws `StateError` if called while unauthenticated. |
| `signOut()` | Invalidates the session server-side, runs every `onSignOut` hook, then flips to `unauthenticated`. |
| `awsCredentials()` | Lazily fetches/caches temporary AWS credentials via Identity Pool federation. For `alerts_api`'s credential-provider hook — see that package's docs. Throws `StateError` if called while unauthenticated. |

**Not implemented in this package (documented known limitations, not oversights):**
- **Local-only sign-out.** `signOut()` always invalidates the session globally (every device).
  There's no variant that only clears the local session without the server call.
- **Friendly Cognito throttling messages.** `LimitExceededException`/`TooManyRequestsException`
  surface via `CognitoAuthException` with Cognito's raw message text — no mapped-to-friendly-copy
  handling exists for them specifically.

## Result/error shape

Every method either completes normally or throws `CognitoAuthException(code, message)` — `code`
is Cognito's raw exception name (e.g. `UsernameExistsException`, `NotAuthorizedException`,
`UserNotConfirmedException`, `CodeMismatchException`, `InvalidPasswordException`), useful for a
caller that wants to branch on a specific failure beyond what `lastError` already maps.

## Shared types

- **`AuthSession`** — `email`, `accessToken`, `idToken`, `refreshToken`, `expiresAt`, plus
  `needsRefreshSoon`/`isExpired` getters.
- **`AwsCredentials`** — `accessKeyId`, `secretKey`, `sessionToken`, `expiresAt`, plus
  `needsRefreshSoon`. This is what `AuthController.awsCredentials()` returns — feed it into
  `alerts_api`'s credential-provider hook or any other AWS-signing need.
