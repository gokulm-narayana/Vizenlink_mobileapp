# LoginScreen

- **Dart file:** `lib/screens/login/login_screen.dart`
- **Route:** `/login`
- **Purpose:** Let an existing user log in via email + password, or via Google. Email sign-in calls `auth_api`'s `AuthController.signIn` (AWS Cognito). **Phone sign-in removed from the UI 2026-09-07** (was a tab that looked functional but always failed with "not available yet" on submit — `auth_api` never supported it) — re-add once phone auth is actually implemented rather than showing a tab that can't work.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| LOGIN-001 | "Welcome back" heading | Text | headlineSmall, top of the form |
| LOGIN-003 | Email field | TextFormField | validates email format |
| LOGIN-005 | Password field | `PasswordFormField` (`lib/widgets/password_form_field.dart`) | min 6 chars, shared show/hide toggle widget |
| LOGIN-006 | Log in button | GradientButton | calls `AuthController.instance.signIn(email, password)`; on `UserNotConfirmedException` pushes to [confirm_signup_screen.md](../signup/confirm_signup_screen.md); other failures show `lastError` in a snackbar |
| LOGIN-007 | "or" divider | Divider/Text | |
| LOGIN-008 | Sign in with Google button | OutlinedButton | stubbed, UI-only, no google_sign_in package wired up yet. Icon is a generic `Icons.account_circle_outlined`, not a real Google "G" mark — there's no Google brand asset in `assets/branding/` and no svg package installed; revisit once a real asset is available or Google sign-in is actually implemented |
| LOGIN-009 | "Don't have an account? Sign up" link | TextButton | navigates to `/signup` |
| LOGIN-010 | Theme mode toggle | IconButton (AppBar action) | cycles System → Light → Dark; persisted via shared_preferences |
| LOGIN-011 | "Forgot password?" link | TextButton | right-aligned below the password field; pushes [forgot_password_screen.md](forgot_password_screen.md) |

**Removed design IDs**: `LOGIN-002` (Email/Phone TabBar) and `LOGIN-004` (Phone number field) — deleted along with phone sign-in, not reused, per this repo's design-ID convention of never renumbering/reassigning existing IDs. `LOGIN-012` (wordmark image, above the heading) — removed 2026-09-09 per explicit request; it was resized twice (200px fixed → then screen-height-proportional) to stop pushing LOGIN-009 below the fold, but the request was to remove it outright rather than keep shrinking it.

## Notes

- On `initState`, if `AuthController.instance.sessionExpiredMessage` is set (a background token refresh genuinely failed, forcing a sign-out — see `packages/auth_api/API_REFERENCE.md`), it's shown as a one-time snackbar and cleared.
