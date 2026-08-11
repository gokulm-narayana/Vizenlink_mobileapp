# LoginScreen

- **Dart file:** `lib/screens/login/login_screen.dart`
- **Route:** `/login`
- **Purpose:** Let an existing user log in via email or phone number + password, or via Google.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| LOGIN-001 | App bar title ("Log in") | AppBar | |
| LOGIN-002 | Email/Phone tab selector | TabBar | switches identifier field below |
| LOGIN-003 | Email field | TextFormField | shown when "Email" tab selected; validates email format |
| LOGIN-004 | Phone number field | TextFormField | shown when "Phone" tab selected; validates phone format |
| LOGIN-005 | Password field | TextFormField | min 6 chars, show/hide toggle |
| LOGIN-006 | Log in button | ElevatedButton | stubbed submit, no backend yet |
| LOGIN-007 | "or" divider | Divider/Text | |
| LOGIN-008 | Sign in with Google button | OutlinedButton | stubbed, UI-only, no google_sign_in package wired up yet |
| LOGIN-009 | "Don't have an account? Sign up" link | TextButton | navigates to `/signup` |
| LOGIN-010 | Theme mode toggle | IconButton (AppBar action) | cycles System → Light → Dark; persisted via shared_preferences |
