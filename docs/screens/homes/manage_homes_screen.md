# ManageHomesScreen

- **Dart file:** `lib/screens/homes/manage_homes_screen.dart`
- **Route:** `/homes/manage`
- **Purpose:** Add, rename, and delete homes (camera locations), and manage each home's rooms. Reached from the home selector dropdown on the Dashboard.
- **Limits:** maximum 10 homes total; maximum 10 rooms per home. "Add home" / "Add room" are disabled once the limit is reached, with a message explaining why.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| HOMES-001 | App bar title ("Manage homes") | AppBar | |
| HOMES-002 | Home list | ListView (ExpansionTile per row) | one row per home: name + camera count + edit/delete actions; expands to reveal that home's rooms |
| HOMES-003 | Edit home button (per row) | IconButton | opens a rename dialog pre-filled with the current name |
| HOMES-004 | Delete home button (per row) | IconButton | opens a confirmation dialog before deleting; disabled if only one home remains |
| HOMES-005 | Add home button | FloatingActionButton | opens a dialog with a name input to create a new home; disabled at 10 homes |
| HOMES-006 | Expand/collapse control (per row) | ExpansionTile trigger | reveals/hides that home's room list |
| HOMES-007 | Room row (per room, in expanded section) | ListTile | room name + edit/delete actions |
| HOMES-008 | Edit room button (per room) | IconButton | opens a rename dialog; renaming updates all cameras in that home referencing the old room name |
| HOMES-009 | Delete room button (per room) | IconButton | confirmation dialog; cameras assigned to the deleted room become unassigned (room: null) |
| HOMES-010 | Add room button (in expanded section) | TextButton / ListTile | opens a dialog with a name input to create a new room in that home; disabled at 10 rooms for that home |
