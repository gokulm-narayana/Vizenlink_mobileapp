# CameraAccessScreen

- **Dart file:** `lib/screens/account/camera_access_screen.dart`
- **Route:** `/account/users-invites/camera-access`
- **Purpose:** Lets an Owner pick which cameras an existing Family Viewer / Temporary Guest member can access, reached from the "Camera access" row on [users_invites_screen.md](users_invites_screen.md)'s member list (USRINV-023) — editing an already-added member is its own destination, as opposed to the Invite/Create-user flows, where camera access is instead an inline section of the same form (see [invite_user_screen.md](invite_user_screen.md) INVUSR-007–012 / [create_user_screen.md](create_user_screen.md) CRUSR-010–015). Pushed with a `CameraAccessScreenArgs` (member name + current `CameraAccessScope`) via `extra`; pops with the edited `CameraAccessScope`, or `null` if the user backs out without tapping Save. The switch + checklist body (CAMACC-003–007) is the shared `CameraAccessChecklist` widget (`lib/widgets/camera_access_checklist.dart`), reused by the Invite/Create-user screens' inline section. Reads homes/cameras from the shared `HomesController` (same source Dashboard/Manage Homes use). No sharing/permissions backend is wired up yet (see CLAUDE.md) — the returned scope is only held in the caller's local widget state, and nothing in the app actually gates a camera's screens on it yet.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CAMACC-001 | Screen title (AppBar) | Text, with a subtitle in `AppBar.bottom` | "Camera Access" / "for {member name}" |
| CAMACC-002 | Save button (AppBar action) | TextButton | pops the screen with the currently staged `CameraAccessScope` |
| CAMACC-003 | "All cameras" toggle | SwitchListTile (in GlassCard, via `CameraAccessChecklist`) | ON (default for a new member): every home/camera checkbox below shows selected and is disabled, and access includes cameras added to any home later. OFF: reveals granular per-home/camera selection, defaulting to whatever was last granularly chosen |
| CAMACC-004 | Home section | ExpansionTile per home (in its own GlassCard, via `CameraAccessChecklist`) | header shows home name + camera count |
| CAMACC-005 | Home-level checkbox | Checkbox (tristate), in CAMACC-004's `leading` | checked/unchecked/dash depending on whether all, none, or some of that home's cameras are selected; tapping selects/deselects every camera in that home at once; disabled while CAMACC-003 is on |
| CAMACC-006 | Camera row checkbox | CheckboxListTile, nested under its home's CAMACC-004 | one per camera in that home; disabled while CAMACC-003 is on |
| CAMACC-007 | Empty state | Text | shown instead of the list if the account has no homes/cameras yet |
