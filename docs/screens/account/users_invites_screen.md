# UsersInvitesScreen

- **Dart file:** `lib/screens/account/users_invites_screen.dart`
- **Route:** `/account/users-invites`
- **Purpose:** Manage who has account-wide access to all of the user's homes/cameras, reached from the "Users & Invites" row on [account_screen.md](account_screen.md). One flat member list, not scoped per-home. No sharing/permissions backend has been chosen yet (see CLAUDE.md), so members/invites are static mock data held in local widget state; inviting, role changes, removal, and cancel-invite are all local-only.
- **Roles:** Owner ("Full camera/site control, sharing, settings, retention, export, decommission"), Family Viewer ("Assigned live view, selected playback, selected alerts, optional two-way talk"), Temporary Guest ("Time-limited access to selected camera/live view only") — shared as `MemberRole` (`lib/models/member_role.dart`) with the invite/create-user screens below. Roles are informational only — there's no backend to actually enforce them. Temporary Guest additionally carries an expiry date. Non-Owner members/invites also carry a `CameraAccessScope` (`lib/models/camera_access_scope.dart`) — either "all cameras" or an explicit set of camera IDs, editable via [camera_access_screen.md](camera_access_screen.md) — but this is UI-only bookkeeping; nothing in the app actually gates a camera's screens on it yet.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| USRINV-001 | App bar title ("Users & Invites") | AppBar | |
| USRINV-002 | Members section label | Text | |
| USRINV-003 | Member row | ListTile (per member, in GlassCard) | avatar/initials, name, role subtitle (label, plus "· Expires <date>" for Temporary Guest) |
| USRINV-004 | Member row — role menu | PopupMenuButton | change role between Owner / Family Viewer / Temporary Guest; hidden for the current user's own row; switching to Temporary Guest opens the expiry date picker (role cannot be set without picking a date — canceling the picker leaves the role unchanged) |
| USRINV-005 | Member row — remove button | IconButton | opens a confirmation dialog; hidden for the current user's own row and disabled if they're the only Owner |
| USRINV-006 | Pending invites section label | Text | shown only when there are pending invites |
| USRINV-007 | Pending invite row | ListTile (per invite, in GlassCard) | email/phone invited, "Pending" status, role, and expiry date if Temporary Guest |
| USRINV-008 | Pending invite row — cancel button | IconButton | removes the pending invite from local state |
| USRINV-009 | "Invite" button | FloatingActionButton | opens the add-user choice dialog (USRINV-014/015) |
| USRINV-014 | Choice dialog — "Send invite" option | SimpleDialogOption | pushes [invite_user_screen.md](invite_user_screen.md); on a non-null result, appends a new pending invite |
| USRINV-015 | Choice dialog — "Create user" option | SimpleDialogOption | pushes [create_user_screen.md](create_user_screen.md); on a non-null result, appends a new member directly (no Pending step) |
| USRINV-023 | Member row — camera access row | ListTile (secondary row inside each member's GlassCard, below USRINV-003) | shown only for Family Viewer / Temporary Guest (Owner always has full access, so no row); subtitle summarizes the member's `CameraAccessScope` ("All cameras" / "{n} of {m} cameras" / "No cameras selected"); tapping pushes [camera_access_screen.md](camera_access_screen.md) seeded with the member's current scope, and applies the returned scope on pop |

USRINV-010–013 (Invite dialog fields), USRINV-016–022 (Create-user dialog fields), and USRINV-024/025 (the dialogs' camera-access rows) are retired — the "Send invite" and "Create user" flows moved from popup `AlertDialog`s into their own full screens ([invite_user_screen.md](invite_user_screen.md) / [create_user_screen.md](create_user_screen.md)) so the camera-access picker has room to breathe; USRINV-012/USRINV-022's "Send invite"/"Create" buttons are now INVUSR-006/CRUSR-009 on those screens.
