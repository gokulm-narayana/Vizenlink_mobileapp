# LoginScreen

- **Dart file:** `lib/screens/login/login_screen.dart`
- **Route:** `/login`
- **Purpose:** Let an existing user log in via email or phone number + password, or via Google. Email sign-in calls `auth_api`'s `AuthController.signIn` (AWS Cognito); phone sign-in isn't supported by `auth_api` and shows a snackbar instead of submitting.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| LOGIN-001 | App bar title ("Log in") | AppBar | |
| LOGIN-002 | Email/Phone tab selector | TabBar | switches identifier field below |
| LOGIN-003 | Email field | TextFormField | shown when "Email" tab selected; validates email format |
| LOGIN-004 | Phone number field | TextFormField | shown when "Phone" tab selected; validates phone format |
| LOGIN-005 | Password field | `PasswordFormField` (`lib/widgets/password_form_field.dart`) | min 6 chars, shared show/hide toggle widget |
| LOGIN-006 | Log in button | GradientButton | calls `AuthController.instance.signIn(email, password)`; on `UserNotConfirmedException` pushes to [confirm_signup_screen.md](../signup/confirm_signup_screen.md); other failures show `lastError` in a snackbar |
| LOGIN-007 | "or" divider | Divider/Text | |
| LOGIN-008 | Sign in with Google button | OutlinedButton | stubbed, UI-only, no google_sign_in package wired up yet |
| LOGIN-009 | "Don't have an account? Sign up" link | TextButton | navigates to `/signup` |
| LOGIN-010 | Theme mode toggle | IconButton (AppBar action) | cycles System → Light → Dark; persisted via shared_preferences |
| LOGIN-011 | "Forgot password?" link | TextButton | right-aligned below the password field; pushes [forgot_password_screen.md](forgot_password_screen.md) |

## Notes

- On `initState`, if `AuthController.instance.sessionExpiredMessage` is set (a background token refresh genuinely failed, forcing a sign-out — see `packages/auth_api/API_REFERENCE.md`), it's shown as a one-time snackbar and cleared.
