# AccountSettingsScreen

- **Dart file:** `lib/screens/account/account_settings_screen.dart`
- **Route:** `/account/settings`
- **Purpose:** Edit profile/security details reached from the "Account settings" row on [account_screen.md](account_screen.md). Display name, email, and phone write through the shared `ProfileController` (`lib/app_state/profile_controller.dart`) so [account_screen.md](account_screen.md) reflects changes immediately. Everything else here is a UI-only stub — no auth backend has been chosen yet (see CLAUDE.md) — so "verification" (OTP, password checks) always succeeds; there's nothing real to validate against yet.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| ACSET-001 | App bar title ("Account Settings") | AppBar | |
| ACSET-002 | Display name field | TextFormField | pre-filled with current display name, editable; saved via ACSET-009 |
| ACSET-003 | Email row | ListTile (Text + "Change" TextButton) | shows current email; "Change" opens the change-email/phone dialog (ACSET-010–014) |
| ACSET-004 | Phone number row | ListTile (Text + "Change" TextButton) | shows current phone number; "Change" opens the same dialog flow as email |
| ACSET-010 | Change value dialog — new value field | TextFormField | step 1 of 2; label adapts to "New email" or "New phone number" depending on which row opened it |
| ACSET-011 | Change value dialog — "Send code" button | ElevatedButton | step 1 → step 2; stub, no real SMS/email provider |
| ACSET-012 | OTP entry field | TextFormField (6-digit, numeric) | step 2 of 2 |
| ACSET-013 | OTP — "Verify" button | ElevatedButton | stub — any 6-digit code is accepted; on success updates the email/phone in local state and closes the dialog |
| ACSET-014 | OTP — "Resend code" link | TextButton | stub — shows a "Code resent" snackbar |
| ACSET-005 | Change password row | ListTile | pushes [change_password_screen.md](change_password_screen.md) (`/account/settings/change-password`) — a full screen, not a dialog (moved off a popup 2026-08-14 for visual consistency with the rest of the app) |
| ACSET-006 | Two-factor authentication toggle | Switch (in ListTile) | turning ON opens the QR setup dialog (ACSET-021–023) then the confirm-code dialog (ACSET-019–020); turning OFF opens only the confirm-code dialog (already-enrolled authenticator, no re-scan needed); canceling either leaves the switch unchanged |
| ACSET-021 | 2FA setup dialog — QR code placeholder | Container with a QR-style icon | static placeholder graphic — no real secret is encoded, since there's no auth backend to tie it to |
| ACSET-022 | 2FA setup dialog — manual secret key | SelectableText | static mock key shown as a manual-entry fallback to the QR code |
| ACSET-023 | 2FA setup dialog — "Continue" button | ElevatedButton | step 1 → step 2 (the confirm-code dialog) |
| ACSET-019 | 2FA confirm-code dialog — 6-digit code field | TextFormField (numeric) | stub — any 6-digit code is accepted |
| ACSET-020 | 2FA confirm-code dialog — "Confirm" button | ElevatedButton | commits the toggle's new state and closes the dialog |
| ACSET-007 | Active sessions row | ListTile | navigates to `/account/settings/sessions` ([active_sessions_screen.md](active_sessions_screen.md)) |
| ACSET-008 | Delete account row | ListTile (destructive styling) | opens a confirmation dialog ("This can't be undone"); confirming shows a stub snackbar only — no account is actually deleted |
| ACSET-009 | Save button | ElevatedButton | saves the display name field (ACSET-002) to local state; shows a "Saved" snackbar |
