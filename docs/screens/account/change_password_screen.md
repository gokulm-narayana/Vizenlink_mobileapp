# ChangePasswordScreen

- **Dart file:** `lib/screens/account/change_password_screen.dart`
- **Route:** `/account/settings/change-password`
- **Purpose:** Full-screen change-password flow, calling real `auth_api` `AuthController.changePassword` (AWS Cognito — no OTP step, Cognito verifies the current password itself). Replaces a previous `AlertDialog`-based popup that looked inconsistent with the rest of the app's screens.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CHPW-001 | App bar title ("Change password") | AppBar | |
| CHPW-002 | Current password field | `PasswordFormField` (`lib/widgets/password_form_field.dart`) | required |
| CHPW-003 | New password field | `PasswordFormField` | validated min 6 characters |
| CHPW-004 | Confirm new password field | `PasswordFormField` | validated to match CHPW-003; submitting the keyboard here also triggers CHPW-006 |
| CHPW-005 | Error text | Text | shown on a failed `changePassword` call — Cognito's message, mapped to friendlier copy for `LimitExceededException`/`TooManyRequestsException` ("Too many attempts. Please wait a few minutes and try again."), or a generic network-failure message for any other exception |
| CHPW-006 | "Update" button | `GradientButton` (`lib/widgets/gradient_button.dart`) | validates the form, calls `AuthController.instance.changePassword(currentPassword, newPassword)`; on success shows a "Password updated" snackbar and pops back to Account Settings |

## Notes

- Reached via `context.push` from Account Settings' "Change password" row (ACSET-005) — see [account_settings_screen.md](account_settings_screen.md).
- `packages/auth_api`'s own `API_REFERENCE.md` documents Cognito throttling copy as a known gap in the package itself ("no mapped-to-friendly-copy handling exists for them specifically") — the friendlier message for CHPW-005 is mapped here at the screen layer instead of in the package.
