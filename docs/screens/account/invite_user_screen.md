# InviteUserScreen

- **Dart file:** `lib/screens/account/invite_user_screen.dart`
- **Route:** `/account/users-invites/invite`
- **Purpose:** Full-screen "Invite" flow, reached from the "Send invite" option on [users_invites_screen.md](users_invites_screen.md)'s add-user choice dialog (USRINV-014) — replaces an earlier popup `AlertDialog`. Camera access is edited inline on this screen (via the shared `CameraAccessChecklist` widget, `lib/widgets/camera_access_checklist.dart`) rather than as a separate destination, since it's one field of this form, not its own screen. Pops with an `InviteUserResult` (contact, role, expiry, camera access), or `null` if the user backs out; `UsersInvitesScreen` appends the result to its local pending-invites list. No sharing/permissions backend is wired up yet (see CLAUDE.md) — nothing is actually emailed/texted.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| INVUSR-001 | App bar title | AppBar | "Invite" |
| INVUSR-002 | Email/phone field | TextFormField | validated non-empty |
| INVUSR-003 | Role selector | RadioGroup of RadioListTile (`RoleSelectorField`, `lib/widgets/member_access_fields.dart`) | one per `MemberRole`, each with its label and full permission description; defaults to Family Viewer |
| INVUSR-004 | Expiry date row | ListTile (opens `showDatePicker`, `ExpiryDateRow`) | shown only when Temporary Guest is selected; required — "Send invite" is a no-op until a date is picked |
| INVUSR-006 | "Send invite" button | FilledButton, bottom of screen | validates the form, then pops with an `InviteUserResult` |
| INVUSR-007 | "Camera access" section label | Text | shown when the selected role ≠ Owner |
| INVUSR-008 | "All cameras" toggle | SwitchListTile (`CameraAccessChecklist`) | ON (default): every home/camera checkbox below shows selected and is disabled, and access includes cameras added to any home later. OFF: reveals granular per-home/camera selection |
| INVUSR-009 | Home section | ExpansionTile per home (`CameraAccessChecklist`) | header shows home name + camera count |
| INVUSR-010 | Home-level checkbox | Checkbox (tristate), in INVUSR-009's `leading` | selects/deselects every camera in that home at once; disabled while INVUSR-008 is on |
| INVUSR-011 | Camera row checkbox | CheckboxListTile, nested under its home's INVUSR-009 | one per camera in that home; disabled while INVUSR-008 is on |
| INVUSR-012 | Camera-access empty state | Text | shown instead of the checklist if the account has no homes/cameras yet |

INVUSR-005 (an earlier "Camera access" tap-through row that pushed a separate `CameraAccessScreen`) is retired — replaced by the inline INVUSR-007–012 section above.
