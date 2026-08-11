---
name: scenario-gap-audit
description: Cross-reference this workspace's scenarios/ and features/ specs against mobilecctvapp's built screens and write a gap report of what's implemented, partial, or missing.
aliases: ["/scenario-gap-audit", "/audit-scenarios"]
---

# /scenario-gap-audit

## Usage
`/scenario-gap-audit` — no arguments needed; reads from `scenarios/` and `features/` in this workspace, compares against `lib/screens/`.

## Action
Invoke the `scenario-gap-audit` skill. Report the resulting `docs/scenario_audit/gap_report.md` path, summary counts (✅ / ⚠️ / ❌), and cache status when done.
