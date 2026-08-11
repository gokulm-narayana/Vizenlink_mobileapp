# SignupScreen

- **Dart file:** `lib/screens/signup/signup_screen.dart`
- **Route:** `/signup`
- **Purpose:** Let a new user create an account via email or phone number + password, or via Google.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SIGNUP-001 | App bar title ("Sign up") | AppBar | |
| SIGNUP-002 | Name field | TextFormField | non-empty |
| SIGNUP-003 | Email/Phone tab selector | TabBar | switches identifier field below |
| SIGNUP-004 | Email field | TextFormField | shown when "Email" tab selected |
| SIGNUP-005 | Phone number field | TextFormField | shown when "Phone" tab selected |
| SIGNUP-006 | Password field | TextFormField | min 6 chars, show/hide toggle |
| SIGNUP-007 | Confirm password field | TextFormField | must match password |
| SIGNUP-008 | Sign up button | ElevatedButton | stubbed submit, no backend yet |
| SIGNUP-009 | "or" divider | Divider/Text | |
| SIGNUP-010 | Sign up with Google button | OutlinedButton | stubbed, UI-only, no google_sign_in package wired up yet |
| SIGNUP-011 | "Already have an account? Log in" link | TextButton | navigates to `/login` |
| SIGNUP-012 | Theme mode toggle | IconButton (AppBar action) | cycles System → Light → Dark; persisted via shared_preferences |
