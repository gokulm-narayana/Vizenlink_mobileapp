---
name: scenario-gap-audit
description: Cross-reference the seed doc + scenario/feature specs in this workspace against what's actually built in lib/screens/, and write a gap report of what's implemented, partial, or missing. Use when asked to audit mobilecctvapp against its scenarios/features, or to check what UI features are still missing.
---

# scenario-gap-audit

This workspace holds its own product spec as structured markdown, three layers deep:

1. **Seed** — `VizenLink_Home_Community_CCTV_Feature_Seed_v0.1.md` at the repo root. The original raw product vision every feature/scenario derives from. Context only — not itself a source of gap-report rows.
2. **Features** — `features/` (one file per compiled feature, `FEAT-NNN-*.md`, indexed in `features/INDEX.md`).
3. **Scenarios** — `scenarios/` (one file per user-facing capability/flow, `mobile-app-*.md` / `vms-*.md`, indexed in `scenarios/INDEX.md`). Only `Component = mobile-app` rows apply here — `vms-*` covers a separate component (e.g. NVR/VMS-side) that this app doesn't implement; skip those.

These are dropped in manually and are the requirements reference for what the app should do. This skill compares layers 2-3 (with layer 1 as background context) against `lib/screens/` (cross-checked with `docs/screens/*.md`) and reports what's covered, partially covered, or missing.

## Process

1. **Check the research cache first** — `knowledgebase/_research_cache/` (owned by this skill; see its `README.md`) may already hold a condensed extraction of the seed/features/scenarios layers from a prior run:
   - If `manifest.json` / `research_digest.md` don't exist yet, this is a cold start — skip to step 2 and read everything fresh.
   - If they exist, stat the live source files (the seed doc, `scenarios/INDEX.md` + every `mobile-app-*.md` file listed in it, `features/INDEX.md` + every file listed in it) and compare `mtime`+`size` against each `manifest.json` entry.
     - Matches → trust `research_digest.md`'s entry, don't re-read that raw file.
     - Differs, new, or removed → note it as needing a fresh read (or removal from the digest).
2. Read `scenarios/INDEX.md` and `features/INDEX.md` fresh every run (small, change often) to get the live file lists — never hardcode a count. Filter scenario rows to `Component = mobile-app` only.
3. Read the seed doc once for background context if not already covered by a fresh digest entry (it rarely changes — treat it as low priority to re-read).
4. Read every mobile-app scenario/feature file flagged as needing a fresh read in step 1 (all of them on a cold start). If this set is large, delegate the read-and-extract pass to one or more `Explore`/`general-purpose` subagents, batching files (e.g. 20-30 per call) rather than reading them all inline. Files already covered by a fresh digest entry don't need re-reading or subagent delegation.
5. After reading, rewrite `knowledgebase/_research_cache/manifest.json` (path/mtime/size per source file) and `research_digest.md` (condensed per-file extraction: capability described, roles, states, edge cases) so the next audit run can skip unchanged files. This is the one skill allowed to write that cache.
6. Build the current-state picture of mobilecctvapp: list `lib/screens/**/*.dart` and their matching `docs/screens/**/*.md` (element inventories describe what each screen actually does; `docs/screens/` is organized into subfolders mirroring `lib/screens/`, so use a recursive glob).
7. Classify each mobile-app scenario against the current implementation:
   - ✅ **Implemented** — an existing screen/widget clearly covers the scenario's behavior
   - ⚠️ **Partial** — a related screen exists but doesn't cover the full scenario (note what's missing)
   - ❌ **Missing** — no existing screen/widget addresses it at all
8. Compile results into `docs/scenario_audit/gap_report.md`:
   - Group by feature area (matching `features/INDEX.md` groupings where possible)
   - Table columns: Scenario file, Feature ID, Status, Covered by (screen/file or "—"), Notes
   - A summary count at the top: total mobile-app scenarios considered, ✅ / ⚠️ / ❌ counts
9. This is a read-only, analysis-only pass over `lib/`/`docs/screens/` — do not create or modify any screen, widget, or client-code file as part of running this skill. Implementation is a separate follow-up the user decides on after reviewing the report.
10. Report the path to the written gap report, the summary counts, and the cache status (cold start / N of M files re-read / full cache hit) to the user.

## Notes

- Re-run anytime scenario/feature files are added to this workspace, or new screens are added, to get a fresh gap report — the previous report is simply overwritten (git history preserves prior versions if the user wants to diff).
- This complements, not replaces, `client-code-docs`/`integrate-client-code` — this skill tells you *what's missing*; those two are for wiring in code the senior actually sends for what does get built.
