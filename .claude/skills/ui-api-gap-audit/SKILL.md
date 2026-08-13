---
name: ui-api-gap-audit
description: Cross-reference already-built UI screens against documented client/API code (docs/client_code/) to find screens that are visually done but still running on mock/placeholder data, or have no real client-code integration at all. The reverse of scenario-gap-audit — checks UI-vs-API coverage, not spec-vs-UI coverage. Use when asked what's missing on the API/backend-wiring side, or whether a screen is "really" hooked up.
---

# ui-api-gap-audit

`scenario-gap-audit` answers "what UI is missing against the spec." This skill answers the opposite question: **for UI that already exists, is it actually wired to real client/API code, or is it still mocked?** Your senior sends client Dart files (API/business logic, documented via `client-code-docs`) separately from — and often behind — your UI work, so screens can look finished while quietly running on hardcoded/dummy data.

## Process

1. Build the screen inventory: list `lib/screens/**/*.dart` and their matching `docs/screens/**/*.md` (element tables describe what each screen's interactive elements are supposed to do).
2. Build the known-client-code inventory: list every `docs/client_code/*.md` file (written by `client-code-docs`) — this is the set of API/logic methods that actually exist and are documented, whether or not they've been wired in yet.
3. For each screen file, scan its Dart source for signs of the data/action source behind each interactive element (buttons, forms, lists, toggles):
   - Does it call a method/class documented in `docs/client_code/`? → real client code is present.
   - Does it use hardcoded literals, `TODO`/`FIXME`/`mock`/`dummy`/`placeholder` markers, `Future.delayed` returning inline fake data, or no data call at all? → mocked/placeholder.
4. Classify each screen/element:
   - ✅ **Wired** — calls a documented client-code method that's actually imported and used
   - ⚠️ **Client code exists, not wired** — a `docs/client_code/*.md` entry covers this screen's need, but the screen doesn't call it yet (this is an `integrate-client-code` job, not a "waiting on senior" job)
   - ❌ **No client code available** — nothing in `docs/client_code/` covers this screen's need at all; the UI is ahead of what's been shared
5. Compile results into `docs/api_coverage_audit/gap_report.md`, in this order:
   - Summary counts at top: total screens/elements checked, ✅ / ⚠️ / ❌ counts.
   - **Quick Wins** section, immediately after the summary: every ⚠️ screen, one row each — Screen (file), Client code covering it (doc file), What's missing (the specific call/import not yet made), Est. effort (S/M/L, judged from how many elements on the screen are ⚠️ vs already ✅). Sort screens with the most already-wired elements (smallest remaining gap) first, since those are closest to done. This section exists so quick wins surface before scrolling through the full table.
   - **Blocked (needs new client code)** section: every ❌ screen grouped together, noting there's nothing in `docs/client_code/` to integrate yet — these need a new file from the senior first, not integration work.
   - Full detail table (as before): Screen (file), Element/action, Status, Client code covering it (doc file or "—"), Notes.
6. This is read-only/analysis-only — do not wire anything in, write client-code docs, or modify any screen as part of running this skill.
7. Report the path to the report and the summary counts, leading with the Quick Wins list (screen + what's missing) since that's the actionable part. For ⚠️ items, mention that `/integrate-client-code` can close them now; for ❌ items, mention they need a new file from the senior first.

## Notes

- Complements `scenario-gap-audit` (spec vs. built UI) and `client-code-docs`/`integrate-client-code` (wiring known client code in) — this is the audit that catches UI that *looks* done but isn't actually hooked up.
- Re-run anytime new client files are documented or new screens are built, to get a fresh picture.
- A screen showing entirely static/placeholder content because no client code has been shared for it yet is expected, not a bug — this skill's job is to surface that clearly, not to fix it.
