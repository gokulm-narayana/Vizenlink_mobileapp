---
name: screen-docs
description: Create or update the per-screen markdown doc and design IDs for a mobilecctvapp screen. Use whenever a new Flutter screen/page widget is added, or when elements on an existing screen are added/changed/removed.
---

# screen-docs

Every screen in this app must have a companion markdown file in `docs/screens/` documenting its elements, and every documented element must carry a stable design ID that's also referenced in the widget code.

`docs/screens/` is organized into subfolders that mirror `lib/screens/` (`splash/`, `login/`, `signup/`, `shell/`, `dashboard/`, `homes/`, `scan/`, `camera_live/`, `alerts/`, `events/`, `account/`, `camera_settings/`), with `camera_settings/` further split into `detections/`, `video_display/`, and `recording_and_storage/` subfolders for readability (mirroring how `CameraSettingsScreen`'s own sub-tree branches; a screen doesn't need Dart code in a matching `lib/` subfolder to warrant its own docs subfolder — `recording_and_storage/` exists purely for doc organization, ahead of a Storage screen that's expected to join `recording_screen.md` there). `_TEMPLATE.md` and `navigation_flow.md` stay at the `docs/screens/` root — they aren't per-screen docs. Cross-references between docs use relative markdown links (e.g. `[camera_live_screen.md](../../camera_live/camera_live_screen.md)`) — get the relative path right when linking across folders, and update any doc that links to a file you move.

## When adding a new screen

**Do this before writing any Dart code — do not skip to implementation.**

1. Copy `docs/screens/_TEMPLATE.md` to `docs/screens/<matching-subfolder>/<screen_name>.md` (snake_case, matching the screen's file name without `_screen.dart`), in the subfolder matching its `lib/screens/` location (see structure above).
2. Pick a short screen prefix (2-6 uppercase letters, unique across `docs/screens/` — grep existing files first: `grep -rh '| [A-Z]' docs/screens/**/*.md` to check for collisions).
3. Draft the element inventory: list every interactive or visually distinct element (buttons, text fields, labels, images, list items, icons, app bar, etc.) in the table with sequential IDs: `<PREFIX>-001`, `<PREFIX>-002`, ... Fill in `Dart file`, `Route`, and `Purpose` at the top of the doc.
4. **Present this draft table to the user and get explicit confirmation before writing the screen's widget code.** Only proceed to implementation once they've confirmed or edited the element list.
5. In the widget code, attach the ID to each element so it's traceable, e.g.:
   ```dart
   ElevatedButton(
     key: const Key('LOGIN-002'),
     onPressed: ...,
     child: const Text('Sign in'),
   )
   ```

## When editing an existing screen

1. Open the matching `docs/screens/<subfolder>/<screen_name>.md` (if you're not sure which subfolder, `find docs/screens -name '<screen_name>.md'`).
2. If you added elements: append new rows with new sequential IDs (don't renumber existing ones).
3. If you removed elements: delete their row (do not reuse a retired ID for something else).
4. Keep the `key: const Key('<ID>')` in code in sync with the table.

## Notes

- IDs are stable identifiers, not display order — never renumber existing IDs when the layout changes, only add/retire.
- One markdown file per screen, filename matching the screen's Dart file, in the `docs/screens/` subfolder matching its `lib/screens/` folder (e.g. `lib/screens/login/login_screen.dart` → `docs/screens/login/login_screen.md`).
- This applies to full-page/route-level widgets (things reachable via navigation), not every small reusable component.
