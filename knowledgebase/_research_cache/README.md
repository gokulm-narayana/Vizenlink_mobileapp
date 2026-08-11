# Research Cache

Written and read by `scenario-gap-audit` only (see `.claude/skills/scenario-gap-audit/SKILL.md`, Step 1). Do not hand-edit.

- `manifest.json` — path + mtime + size for every source file (the seed doc, `scenarios/INDEX.md`, `scenarios/mobile-app-*.md`, `features/INDEX.md`, `features/FEAT-*.md`) as of its last full read.
- `research_digest.md` — condensed per-file extraction of the scenarios/features layers, built from full reads only. Loaded in place of re-reading unchanged files on the next audit.

Deleting this directory is always safe — it just forces the next `scenario-gap-audit` run to do a full cold-start read and rebuild it.
