# AccountScreen

- **Dart file:** `lib/screens/account/account_screen.dart`
- **Route:** `/account`
- **Purpose:** User's profile and app settings menu — the fourth main tab. Most rows are stubs for now since no billing/sharing backend has been chosen yet (see CLAUDE.md); tapping them shows a "Coming soon" snackbar. Manage Homes genuinely navigates to [manage_homes_screen.md](../homes/manage_homes_screen.md). Log out genuinely calls `auth_api`'s `AuthController.instance.signOut()` (invalidates the Cognito session server-side) before navigating to [login_screen.md](../login/login_screen.md). Display name, role, and avatar image are held in the shared `ProfileController` (`lib/app_state/profile_controller.dart`, instantiated once in `main.dart` and passed to both this screen and [account_settings_screen.md](account_settings_screen.md)) — no profile backend wired up yet, so it only lives for the session, but edits made in Account Settings now reflect here immediately. Uses the `image_picker` package to pick a photo from the device's gallery (requires `NSPhotoLibraryUsageDescription` on iOS, already added to `Info.plist`).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| ACCT-001 | App bar title ("Profile") | AppBar | |
| ACCT-002 | Theme mode toggle | IconButton (AppBar action) | reuses shared ThemeToggleButton |
| ACCT-004 | Profile avatar | CircleAvatar, inside a `GlassCard` | large (radius 56), centered at top of the profile card; shows the picked gallery image if one has been chosen, otherwise initials derived from display name; tapping it opens a full-screen popup (`Dialog`) showing the avatar large plus name and role, dismissed by tapping anywhere |
| ACCT-007 | Edit profile button | Small circular badge (InkWell), surface-colored with a soft shadow | overlaid near the bottom edge of the avatar; opens the device photo gallery via `image_picker`, and the picked image becomes the avatar |
| ACCT-005 | Display name | Text | bold, centered below avatar; local state, initial value "Alex Morgan" |
| ACCT-016 | Role / bio line | Text | centered below display name; local state, initial value "Owner" |
| ACCT-008 | Account settings row | ListTile (in GlassCard) | navigates to `/account/settings` ([account_settings_screen.md](account_settings_screen.md)) |
| ACCT-009 | Manage Homes row | ListTile (in GlassCard) | navigates to `/dashboard/homes/manage` ([manage_homes_screen.md](../homes/manage_homes_screen.md)) |
| ACCT-010 | Notification preferences row | ListTile (in GlassCard) | navigates to `/account/notifications` ([notification_preferences_screen.md](notification_preferences_screen.md)) |
| ACCT-014 | Subscription / Plan row | ListTile (in GlassCard) | stub — shows "Coming soon" snackbar; no billing backend chosen yet |
| ACCT-015 | Users & Invites row | ListTile (in GlassCard) | navigates to `/account/users-invites` ([users_invites_screen.md](users_invites_screen.md)) |
| ACCT-012 | Help & Support row | ListTile (in GlassCard) | navigates to `/account/help` ([help_support_screen.md](help_support_screen.md)) |
| ACCT-011 | About / app version row | ListTile (in GlassCard) | shows static version string |
| ACCT-013 | Log out button | ElevatedButton | calls `AuthController.instance.signOut()` (shows an inline spinner while in flight), then navigates to `/login` ([login_screen.md](../login/login_screen.md)) |

ACCT-003 (previous "coming soon" placeholder body) is retired — replaced by real content above.
ACCT-006 (previously an @handle/login-identifier line) is retired — dropped from the profile card per updated design.
ACCT-017 (previously a "Profile" section label inside the card) is retired — duplicated the app bar title, so removed.
