# SignupScreen

- **Dart file:** `lib/screens/signup/signup_screen.dart`
- **Route:** `/signup`
- **Purpose:** Let a new user create an account via email or phone number + password, or via Google. Email sign-up calls `auth_api`'s `AuthController.signUp` (AWS Cognito) then hands off to [confirm_signup_screen.md](confirm_signup_screen.md) for the emailed confirmation code; phone sign-up isn't supported by `auth_api` and shows a snackbar instead of submitting. The Name field is UI-only — `auth_api`'s `signUp` takes only email/password, no profile attributes.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SIGNUP-001 | App bar title ("Sign up") | AppBar | |
| SIGNUP-002 | Name field | TextFormField | non-empty; not sent anywhere yet (no profile API wired up) |
| SIGNUP-003 | Email/Phone tab selector | TabBar | switches identifier field below |
| SIGNUP-004 | Email field | TextFormField | shown when "Email" tab selected |
| SIGNUP-005 | Phone number field | TextFormField | shown when "Phone" tab selected |
| SIGNUP-006 | Password field | `PasswordFormField` (`lib/widgets/password_form_field.dart`) | min 6 chars, shared show/hide toggle widget |
| SIGNUP-007 | Confirm password field | `PasswordFormField` | must match password |
| SIGNUP-008 | Sign up button | GradientButton | calls `AuthController.instance.signUp(email, password)`, then pushes [confirm_signup_screen.md](confirm_signup_screen.md) with the email+password; failures show `lastError` in a snackbar |
| SIGNUP-009 | "or" divider | Divider/Text | |
| SIGNUP-010 | Sign up with Google button | OutlinedButton | stubbed, UI-only, no google_sign_in package wired up yet |
| SIGNUP-011 | "Already have an account? Log in" link | TextButton | navigates to `/login` |
| SIGNUP-012 | Theme mode toggle | IconButton (AppBar action) | cycles System → Light → Dark; persisted via shared_preferences |
