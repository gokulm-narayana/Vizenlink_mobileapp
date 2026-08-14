# ConfirmSignupScreen

- **Dart file:** `lib/screens/signup/confirm_signup_screen.dart`
- **Route:** `/confirm-signup`
- **Purpose:** Complete AWS Cognito account confirmation with the code emailed after sign-up, then sign the user straight in — Cognito's `SignUp`/`InitiateAuth` flow requires this as a separate step for a new account. Also reached from Login when a sign-in attempt hits Cognito's `UserNotConfirmedException`. Takes `ConfirmSignupArgs` (`email`, `password`) via `state.extra`.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CONFIRM-001 | Title ("Confirm your email") | Text | |
| CONFIRM-002 | Subtitle ("Enter the code sent to {email}") | Text | |
| CONFIRM-003 | Confirmation code field | TextFormField | numeric, 6 digits |
| CONFIRM-004 | Error text | Text | shown on a failed confirm attempt (`CognitoAuthException.message`) |
| CONFIRM-005 | Confirm button | GradientButton | calls `AuthController.instance.confirmSignUp(email, code)` then `signIn(email, password)`, navigates to `/dashboard` on success |
| CONFIRM-006 | Resend code link | TextButton | calls `AuthController.instance.resendConfirmationCode(email)` |
| CONFIRM-007 | "Back to log in" link | TextButton | navigates to `/login` |

## Notes

- No AppBar back button (`automaticallyImplyLeading: false`) — this screen is reached mid-flow (after a real signup submission, or from a not-yet-confirmed login attempt), not somewhere to casually back out of.
