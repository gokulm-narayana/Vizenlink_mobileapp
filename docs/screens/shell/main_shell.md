# MainShell

- **Dart file:** `lib/screens/shell/main_shell.dart`
- **Route:** wraps `/dashboard`, `/alerts`, `/events`, `/account` via `StatefulShellRoute.indexedStack`
- **Purpose:** Persistent bottom navigation across the app's four main sections after login. `CameraLiveScreen` and its whole Camera Settings sub-tree are nested inside the Dashboard branch (see [navigation_flow.md](../navigation_flow.md)), so the bottom nav bar also stays visible there.
- Before switching branches, each nav-bar tap awaits `NavigationGuardController.confirmLeave()` (`lib/widgets/navigation_leave_guard.dart`) — a small ambient registry that the currently-visible screen registers a "may I leave?" callback with via the shared `LeaveGuard` widget. This lets screens with an active recording ([camera_live_screen.md](../camera_live/camera_live_screen.md), LIVE-031) or unsaved settings edits (e.g. [video_mode_screen.md](../camera_settings/video_display/video_mode_screen.md), VIDMODE-008) block or confirm a tab switch the same way they already guard the back gesture.

## Elements

| Design ID | Element | Type | Notes |
|-----------|---------|------|-------|
| SHELL-001 | Bottom navigation bar | NavigationBar | 4 destinations, each with its own nav stack (IndexedStack) |
| SHELL-002 | Dashboard destination | NavigationDestination | icon: `dashboard_outlined` / `dashboard` |
| SHELL-003 | Notifications destination | NavigationDestination | icon: `notifications_outlined` / `notifications`; label reads "Notifications" (still routes to `/alerts` → `AlertsScreen`/`AlertsController`, which keep their original internal names) |
| SHELL-006 | Notifications unread badge | Small dot (8x8, error-color, themed border) overlaid on the top-right of SHELL-003's icon | shown only while `AlertsController.unreadCount > 0` (mock data, see `lib/app_state/alerts_controller.dart` — no backend wired up yet); no count shown, just a presence dot |
| SHELL-004 | Events destination | NavigationDestination | icon: `event_note_outlined` / `event_note` |
| SHELL-005 | Profile destination | NavigationDestination | icon: `person_outline` / `person`; label reads "Profile" (routes to `/account` → `AccountScreen`, which keeps its original internal name) |
