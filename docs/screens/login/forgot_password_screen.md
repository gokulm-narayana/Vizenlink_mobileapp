# ForgotPasswordScreen

- **Dart file:** `lib/screens/login/forgot_password_screen.dart`
- **Route:** `/forgot-password`
- **Purpose:** AWS Cognito forgot-password flow — request a reset code by email, then submit the code with a new password. Both steps live on one screen (not two routes) so the email entered in step 1 carries into step 2 without threading it through navigation `extra`.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| FORGOT-001 | Title ("Reset password") | Text | |
| FORGOT-002 | Email field | TextFormField | step 1; disabled (not editable) once the code has been sent |
| FORGOT-003 | "Send code" button | GradientButton | step 1 only; calls `AuthController.instance.forgotPassword(email)`, advances to step 2 on success |
| FORGOT-004 | Confirmation code field | TextFormField | step 2 only; numeric |
| FORGOT-005 | New password field | `PasswordFormField` (`lib/widgets/password_form_field.dart`) | step 2 only; min 6 chars |
| FORGOT-006 | Confirm new password field | `PasswordFormField` | step 2 only; must match FORGOT-005 |
| FORGOT-007 | Error text | Text | shown on a failed `forgotPassword`/`confirmForgotPassword` call (`CognitoAuthException.message`) |
| FORGOT-008 | "Reset password" button | GradientButton | step 2 only; calls `AuthController.instance.confirmForgotPassword(email, code, newPassword)`, navigates to `/login` on success |
| FORGOT-009 | "Back to log in" link | TextButton | navigates to `/login` |

## Notes

- No AppBar back button (`automaticallyImplyLeading: false`) — use FORGOT-009 to return to Login.
- Per Cognito's anti-enumeration behavior (see `packages/auth_api/API_REFERENCE.md`), `forgotPassword` appears to succeed even for an unregistered email, so step 1 always advances to step 2 on a non-throttled response.
