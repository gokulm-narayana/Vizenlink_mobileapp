---
name: ui-api-gap-audit
description: Cross-reference already-built UI screens against documented client/API code (docs/client_code/) to find screens that are visually done but still running on mock/placeholder data, or have no real client-code integration at all — and the reverse direction too, real client/API capabilities that have no UI surfacing them anywhere yet. Complements scenario-gap-audit — checks UI-vs-API coverage, not spec-vs-UI coverage. Use when asked what's missing on the API/backend-wiring side, whether a screen is "really" hooked up, or whether a capability the API supports has a UI for it yet.
---

# ui-api-gap-audit

`scenario-gap-audit` answers "what UI is missing against the spec." This skill answers two related but distinct questions:

1. **UI → API direction:** for UI that already exists, is it actually wired to real client/API code, or is it still mocked? Your senior sends client Dart files (API/business logic, documented via `client-code-docs`) separately from — and often behind — your UI work, so screens can look finished while quietly running on hardcoded/dummy data.
2. **API → UI direction:** for client/API capabilities that already exist and are documented, is there *any* screen that surfaces them at all? A real, working API method with zero UI calling it anywhere is easy to miss — nothing looks broken, there's just nothing to look at. This direction is what catches "the camera API can already do X, why isn't there a setting for it?"

## Process

### Part A — UI → API (existing UI, is it wired?)

1. Build the screen inventory: list `lib/screens/**/*.dart` and their matching `docs/screens/**/*.md` (element tables describe what each screen's interactive elements are supposed to do).
2. Build the known-client-code inventory: list every `docs/client_code/*.md` file (written by `client-code-docs`) — this is the set of API/logic methods that actually exist and are documented, whether or not they've been wired in yet.
3. For each screen file, scan its Dart source for signs of the data/action source behind each interactive element (buttons, forms, lists, toggles):
   - Does it call a method/class documented in `docs/client_code/`? → real client code is present.
   - Does it use hardcoded literals, `TODO`/`FIXME`/`mock`/`dummy`/`placeholder` markers, `Future.delayed` returning inline fake data, or no data call at all? → mocked/placeholder.
4. Classify each screen/element:
   - ✅ **Wired** — calls a documented client-code method that's actually imported and used
   - ⚠️ **Client code exists, not wired** — a `docs/client_code/*.md` entry covers this screen's need, but the screen doesn't call it yet (this is an `integrate-client-code` job, not a "waiting on senior" job)
   - ❌ **No client code available** — nothing in `docs/client_code/` covers this screen's need at all; the UI is ahead of what's been shared

### Part B — API → UI (existing capabilities, do they have UI?)

5. Build the capability inventory: walk every documented client class/method in `docs/client_code/*.md`, and — since `docs/client_code/camera_api.md` wraps `packages/camera_api` rather than re-describing every call — also check `packages/camera_api/API_REFERENCE.md` and `SETTINGS_API_GUIDE.md` for setter/getter pairs (a `Set*`/`Get*Options`-style capability, e.g. `EventPreferencesClient.setEventPreferences`) that represent one user-facing capability each. Skip pure transport/plumbing methods (connection setup, `close()`, low-level discovery) that were never going to have their own UI.
6. For each capability, grep `lib/screens/**/*.dart` for any reference to its class or method name (imported and called, not just mentioned in a comment).
   - If at least one screen calls it → already covered by Part A's ✅/⚠️ classification, skip it here.
   - If **no screen references it at all** → 🆕 **API available, no UI yet** — note which screen area it would logically belong to (e.g. a per-camera event-type toggle belongs under Camera Settings, not Alerts) based on `SETTINGS_API_GUIDE.md`'s own screen-mapping guidance where it has one.
7. This pass is necessarily best-effort — a large capability surface (e.g. every ONVIF imaging parameter) can be summarized by client class rather than exhaustively enumerated per method if that keeps the report readable; call out when you've done this.

### Compiling the report

8. Compile results into `docs/api_coverage_audit/gap_report.md`, in this order:
   - Summary counts at top: total screens/elements checked (Part A), total capabilities checked (Part B), ✅ / ⚠️ / ❌ / 🆕 counts.
   - **Quick Wins** section, immediately after the summary: every ⚠️ screen, one row each — Screen (file), Client code covering it (doc file), What's missing (the specific call/import not yet made), Est. effort (S/M/L, judged from how many elements on the screen are ⚠️ vs already ✅). Sort screens with the most already-wired elements (smallest remaining gap) first, since those are closest to done. This section exists so quick wins surface before scrolling through the full table.
   - **Blocked (needs new client code)** section: every ❌ screen grouped together, noting there's nothing in `docs/client_code/` to integrate yet — these need a new file from the senior first, not integration work.
   - **Available APIs With No UI Yet** section (Part B's 🆕 results): one row each — Capability (class/method), Documented in (doc file/line), Likely screen area, Notes. This is the "the backend already supports this, nobody's built the toggle" list — flag it as net-new screen/element work (subject to the project's plan-before-code rule — present the element inventory and get confirmation before writing code), not an integration job.
   - Full detail table (as before): Screen (file), Element/action, Status, Client code covering it (doc file or "—"), Notes.
9. This is read-only/analysis-only — do not wire anything in, write client-code docs, build new screens, or modify any screen as part of running this skill.
10. Report the path to the report and the summary counts, leading with the Quick Wins list (screen + what's missing) since that's the actionable part, then the Available-APIs-With-No-UI list. For ⚠️ items, mention that `/integrate-client-code` can close them now; for ❌ items, mention they need a new file from the senior first; for 🆕 items, mention they're new-screen/new-element work subject to the plan-before-code rule, not an integration job.

## Notes

- Complements `scenario-gap-audit` (spec vs. built UI) and `client-code-docs`/`integrate-client-code` (wiring known client code in) — this is the audit that catches UI that *looks* done but isn't actually hooked up, plus (Part B) API capability that's real but has no UI at all yet.
- Re-run anytime new client files are documented or new screens are built, to get a fresh picture.
- A screen showing entirely static/placeholder content because no client code has been shared for it yet is expected, not a bug — this skill's job is to surface that clearly, not to fix it.
- A 🆕 result is not itself a bug either — plenty of API surface (e.g. rarely-used ONVIF options) may never need a screen. Use judgment on which 🆕 findings are actually worth flagging as product gaps vs. capability that's fine to leave unsurfaced; when in doubt, list it and let the reader decide.
