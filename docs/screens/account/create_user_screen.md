# CreateUserScreen

- **Dart file:** `lib/screens/account/create_user_screen.dart`
- **Route:** `/account/users-invites/create-user`
- **Purpose:** Full-screen "Create user" flow, reached from the "Create user" option on [users_invites_screen.md](users_invites_screen.md)'s add-user choice dialog (USRINV-015) — replaces an earlier popup `AlertDialog`. Camera access is edited inline on this screen (via the shared `CameraAccessChecklist` widget, `lib/widgets/camera_access_checklist.dart`) rather than as a separate destination, since it's one field of this form, not its own screen. Pops with a `CreateUserResult` (name, role, expiry, camera access), or `null` if the user backs out; `UsersInvitesScreen` appends the result directly to its Members list (no Pending step, unlike Invite). Email and password are validated on this screen but not carried in the result or stored anywhere — there's no auth backend yet (see CLAUDE.md).

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| CRUSR-001 | App bar title | AppBar | "Create user" |
| CRUSR-002 | Name field | TextFormField | validated non-empty |
| CRUSR-003 | Email field | TextFormField | validated to contain "@" |
| CRUSR-004 | Password field | TextFormField | obscured; validated min 6 characters |
| CRUSR-005 | Confirm password field | TextFormField | obscured; validated to match CRUSR-004 |
| CRUSR-006 | Role selector | RadioGroup of RadioListTile (`RoleSelectorField`, `lib/widgets/member_access_fields.dart`) | same as [invite_user_screen.md](invite_user_screen.md)'s INVUSR-003; defaults to Family Viewer |
| CRUSR-007 | Expiry date row | ListTile (opens `showDatePicker`, `ExpiryDateRow`) | shown only when Temporary Guest is selected; required |
| CRUSR-009 | "Create" button | FilledButton, bottom of screen | validates the form, then pops with a `CreateUserResult` |
| CRUSR-010 | "Camera access" section label | Text | shown when the selected role ≠ Owner |
| CRUSR-011 | "All cameras" toggle | SwitchListTile (`CameraAccessChecklist`) | same behavior as [invite_user_screen.md](invite_user_screen.md)'s INVUSR-008 |
| CRUSR-012 | Home section | ExpansionTile per home (`CameraAccessChecklist`) | same as INVUSR-009 |
| CRUSR-013 | Home-level checkbox | Checkbox (tristate), in CRUSR-012's `leading` | same as INVUSR-010 |
| CRUSR-014 | Camera row checkbox | CheckboxListTile, nested under its home's CRUSR-012 | same as INVUSR-011 |
| CRUSR-015 | Camera-access empty state | Text | same as INVUSR-012 |

CRUSR-008 (an earlier "Camera access" tap-through row that pushed a separate `CameraAccessScreen`) is retired — replaced by the inline CRUSR-010–015 section above.
