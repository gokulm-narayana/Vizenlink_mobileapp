# NotificationPreferencesScreen

- **Dart file:** `lib/screens/account/notification_preferences_screen.dart`
- **Route:** `/account/notifications`
- **Purpose:** Choose which alerts to be notified about and how, reached from the "Notification preferences" row on [account_screen.md](account_screen.md). No notification backend (push/email delivery) is wired up yet (see CLAUDE.md), so every toggle just lives in local widget state — nothing is actually sent or scheduled.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| NOTIF-001 | App bar title ("Notification Preferences") | AppBar | |
| NOTIF-002 | Push notifications toggle | SwitchListTile | master channel switch |
| NOTIF-003 | Email notifications toggle | SwitchListTile | separate channel from push |
| NOTIF-004 | Motion detected toggle | SwitchListTile | disabled (dimmed) when both NOTIF-002 and NOTIF-003 are off — nothing to deliver to |
| NOTIF-005 | Person detected toggle | SwitchListTile | same enable rule as NOTIF-004 |
| NOTIF-006 | Vehicle detected toggle | SwitchListTile | same enable rule as NOTIF-004 |
| NOTIF-007 | Camera offline toggle | SwitchListTile | same enable rule as NOTIF-004 |
| NOTIF-008 | Camera back online toggle | SwitchListTile | same enable rule as NOTIF-004 |
| NOTIF-009 | Quiet hours toggle | SwitchListTile | same enable rule as NOTIF-004; enables NOTIF-010/011 below when on |
| NOTIF-010 | Quiet hours — start time row | ListTile (opens `showTimePicker`) | shown only when NOTIF-009 is on |
| NOTIF-011 | Quiet hours — end time row | ListTile (opens `showTimePicker`) | shown only when NOTIF-009 is on |
| NOTIF-012 | Sound toggle | SwitchListTile | same enable rule as NOTIF-004 |
