---
name: integrate-client-code
description: Integrate a senior engineer's client-side Dart code (business logic/data/state) into the existing mobilecctvapp UI without altering that code unless unavoidable. Use whenever new client/business-logic Dart files are shared to be wired into an existing screen.
---

# integrate-client-code

The senior engineer builds the app's client code (business logic, API/data layer, state) but doesn't focus on navigation flow or UI polish. This skill wires their Dart files into the existing UI (`lib/screens/`, `lib/widgets/`) — the client code is treated as source of truth for logic/data/state; the existing UI is treated as source of truth for navigation, layout, screen boundaries, and design IDs.

The client file's overall navigation flow is expected to be broadly similar to the existing UI's, but its screen *boundaries* often aren't identical — e.g. the client code may bundle two features (like night mode + imaging settings) into one screen/widget where the existing UI already splits them into two. Screen grouping in `lib/screens/` always wins; the client code's grouping is not a signal to merge or restructure existing screens.

## Process

0. Look in `client_code_inbox/` for the file(s) to integrate — that's where shared client Dart files are placed. If the user names a file without a path, assume it's there. If its functions/classes aren't already documented in `docs/client_code/`, run `client-code-docs` on it first to build a reference table before integrating.
1. Read the shared client Dart file(s) in full before touching anything.
2. Identify which existing screen(s)/widget(s) in `lib/screens/` or `lib/widgets/` the client code corresponds to (by feature area, naming, or explicit mapping from the user). A single client file/class may map to more than one existing screen — split its logic across the matching screens rather than forcing a 1:1 file-to-screen match, or creating/merging screens to fit the client file's shape.
3. Determine what the client code exposes (methods, streams, models, state) that the UI needs to call or bind to, and which subset each target screen actually needs.
4. Modify only the UI-side file(s) to wire in the client code — update calls, bindings, imports, and state consumption so each screen reflects the client code's actual behavior, pulling in only the slice relevant to that screen when one client class/file serves multiple existing screens.
5. If a change to the client file is unavoidable (e.g. a signature mismatch that can't be worked around from the UI side), stop and flag it to the user with the specific reason before making the change — do not silently edit client code.
6. After wiring, keep the relevant `docs/screens/**/*.md` files and design IDs in sync (`screen-docs` skill) if the integration adds/removes/changes UI elements.
7. Run `flutter-lint` before considering the change done.
8. Report which screens were touched and what was wired, plus any client-side changes made or flagged.

## Notes

- Only the UI layer changes by default (screens/widgets) — never the client file, unless flagged and confirmed first.
- Don't redesign navigation flow or screen structure beyond what's needed to wire in the client code.
- If the client code's shape (state management approach, data layer pattern) is ambiguous or introduces a new dependency not already used in the project, confirm with the user before assuming — per this project's convention of not introducing a state/networking layer without confirmation.
