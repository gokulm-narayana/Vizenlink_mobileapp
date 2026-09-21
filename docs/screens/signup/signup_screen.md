# SignupScreen

- **Dart file:** `lib/screens/signup/signup_screen.dart`
- **Route:** `/signup`
- **Purpose:** Let a new user create an account via email + password, or via Google. Email sign-up calls `auth_api`'s `AuthController.signUp` (AWS Cognito) then hands off to [confirm_signup_screen.md](confirm_signup_screen.md) for the emailed confirmation code. **Phone sign-up removed from the UI 2026-09-07** (was a tab that looked functional but always failed with "not available yet" on submit — `auth_api` never supported it) — re-add once phone auth is actually implemented, same reasoning as [login_screen.md](../login/login_screen.md). The Name field **is now sent**: `auth_api`'s `signUp` gained an optional `name` parameter (stored as Cognito's standard `name` user attribute) the same day — it used to be UI-only and silently discarded.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SIGNUP-001 | "Create your account" heading | Text | headlineSmall, top of the form |
| SIGNUP-002 | Name field | TextFormField | non-empty; sent as `AuthController.signUp`'s `name` param (Cognito `name` attribute) |
| SIGNUP-004 | Email field | TextFormField | validates email format |
| SIGNUP-006 | Password field | `PasswordFormField` (`lib/widgets/password_form_field.dart`) | min 6 chars, shared show/hide toggle widget. SIGNUP-014's strength bar appears below it once non-empty |
| SIGNUP-007 | Confirm password field | `PasswordFormField` | must match password; shows SIGNUP-015's checkmark via `PasswordFormField.matchIndicator` once it matches |
| SIGNUP-008 | Sign up button | GradientButton | calls `AuthController.instance.signUp(email, password, name: name)`, then pushes [confirm_signup_screen.md](confirm_signup_screen.md) with the email+password; failures show `lastError` in a snackbar |
| SIGNUP-009 | "or" divider | Divider/Text | |
| SIGNUP-010 | Sign up with Google button | OutlinedButton | stubbed, UI-only, no google_sign_in package wired up yet. Icon is a generic `Icons.account_circle_outlined`, not a real Google "G" mark — same reasoning as [login_screen.md](../login/login_screen.md)'s LOGIN-008 |
| SIGNUP-011 | "Already have an account? Log in" link | TextButton | navigates to `/login` |
| SIGNUP-012 | Theme mode toggle | IconButton (AppBar action) | cycles System → Light → Dark; persisted via shared_preferences |
| SIGNUP-014 | Password strength bar | `_PasswordStrengthBar` (private widget, this file) | Live-updates as SIGNUP-006 changes: a thin `LinearProgressIndicator` + Weak/Medium/Strong label, scored from length/case-mix/digit/symbol variety (0-5 points → 0.0-1.0). **Cosmetic only** — does not change `_validatePassword`'s actual minimum (still 6 chars); only hidden entirely while the field is empty |
| SIGNUP-015 | Confirm-password match checkmark | `Icon(Icons.check_circle)`, inside SIGNUP-007 via `PasswordFormField.matchIndicator` | Shown only once SIGNUP-007's text is non-empty and equals SIGNUP-006's — live, not just on submit |

**Removed design IDs**: `SIGNUP-003` (Email/Phone TabBar) and `SIGNUP-005` (Phone number field) — deleted along with phone sign-up, not reused, per this repo's design-ID convention of never renumbering/reassigning existing IDs. `SIGNUP-013` (wordmark image, above the heading) — removed 2026-09-09 per explicit request, same reasoning as [login_screen.md](../login/login_screen.md)'s LOGIN-012.

## Related widget change

`lib/widgets/password_form_field.dart` (shared by Login, Signup, Change Password, Create User, Scanned Devices, Wifi Config — see `.claude/rules/mobile-app-screen-conventions.md`) gained an optional `matchIndicator` param: an extra icon rendered to the left of the existing show/hide toggle inside the field's `suffixIcon`. Only Signup's confirm-password field passes one so far; every other caller is unaffected (defaults to `null`, same rendering as before).
