# ActiveSessionsScreen

- **Dart file:** `lib/screens/account/active_sessions_screen.dart`
- **Route:** `/account/settings/sessions`
- **Purpose:** Lists devices signed into the account, reached from the "Active sessions" row on [account_settings_screen.md](account_settings_screen.md). No auth backend is wired up yet (see CLAUDE.md), so the session list is static mock data held in local widget state; "sign out" actions just remove the row locally.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SESS-001 | App bar title ("Active Sessions") | AppBar | |
| SESS-002 | Session list | ListView of GlassCards | one card per mock session |
| SESS-003 | Device/session row — device icon | Icon | phone/tablet/desktop icon based on mock device type |
| SESS-004 | Device/session row — device name & OS | Text | e.g. "iPhone 17 Pro · iOS 26" |
| SESS-005 | Device/session row — location (approx.) | Text | mock value, e.g. "San Francisco, CA" |
| SESS-006 | Device/session row — last active time | Text | mock value, e.g. "Active now" / "2 hours ago" |
| SESS-007 | Device/session row — "This device" badge | Chip | shown only on the current session (first mock entry) |
| SESS-008 | Device/session row — "Sign out" button | TextButton | removes that session from the local list; hidden on "This device" |
| SESS-009 | "Sign out all other sessions" button | ElevatedButton | removes every session except "This device"; disabled when there are no other sessions |
