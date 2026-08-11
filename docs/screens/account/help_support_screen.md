# HelpSupportScreen

- **Dart file:** `lib/screens/account/help_support_screen.dart`
- **Route:** `/account/help`
- **Purpose:** FAQ and support contact options, reached from the "Help & Support" row on [account_screen.md](account_screen.md). FAQ content is static mock data; Contact Support, Report a Bug, and the user guide link are stubs — no support backend/ticketing or external links are wired up yet (see CLAUDE.md).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| HELP-001 | App bar title ("Help & Support") | AppBar | |
| HELP-002 | Search field | TextFormField | filters the FAQ list below by question text (local, case-insensitive substring match) |
| HELP-003 | FAQ item | ExpansionTile (per item, in GlassCard) | static mock question/answer pairs; hidden when filtered out by HELP-002 |
| HELP-004 | Contact Support row | ListTile (in GlassCard) | stub — shows "Coming soon" snackbar |
| HELP-005 | Report a Bug row | ListTile (in GlassCard) | stub — shows "Coming soon" snackbar |
| HELP-006 | User Guide row | ListTile (in GlassCard) | stub — shows "Coming soon" snackbar; no external link wired up yet |
| HELP-007 | App version footer | Text | static version string, centered at the bottom |
