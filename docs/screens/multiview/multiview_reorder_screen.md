# MultiviewReorderScreen

- **Dart file:** `lib/screens/multiview/multiview_reorder_screen.dart`
- **Route:** none — a plain `Navigator.push` (`MaterialPageRoute`) from MULTIVIEW-009 on [multiview_screen.md](multiview_screen.md), not a go_router route. Since `MultiviewScreen` itself already lives on the root `Navigator` (see multiview_screen.md's own Route note), pushing here via the nearest-ancestor `Navigator.of(context)` lands on that same root Navigator — there's no separate nested Navigator in between. Unlike Multiview's own landscape-only lock, MULTIVIEW-009's handler temporarily allows both orientations for as long as this screen is open (a plain reorder list reads fine in portrait), then restores the landscape-only lock once the user pops back to Multiview.
- **Purpose:** Dedicated full-page camera reorder list for one home, opened from Multiview's reorder button. Long-press-drag a row to change that camera's position; `HomesController.reorderCameras(homeId, oldIndex, newIndex)` persists the new order into shared `HomesState` immediately per drag, so it's reflected everywhere cameras are listed (Dashboard, Multiview), not just on this screen.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| MVSORT-001 | Back button (AppBar) | IconButton | pops back to Multiview |
| MVSORT-002 | App bar title | Text | reads "Reorder Cameras" |
| MVSORT-003 | Camera list | `ReorderableListView.builder` | one MVSORT-004 row per camera in the home, in current order |
| MVSORT-004 | Camera row (repeated per camera, key suffixed `-<cameraId>`) | ListTile | camera icon (leading), camera name (title), drag handle (trailing); long-press-drag reorders |

If the home no longer exists by the time this screen is showing (e.g. deleted while the sheet was open), the body renders empty rather than crashing — no design ID, since nothing is shown.
