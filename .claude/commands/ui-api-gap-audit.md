---
name: ui-api-gap-audit
description: Check already-built UI screens against documented client/API code to find what's wired, what has client code available but not yet wired, and what has no client code at all.
aliases: ["/ui-api-gap-audit", "/api-coverage-audit"]
---

# /ui-api-gap-audit

## Usage
`/ui-api-gap-audit` — no arguments needed; reads `lib/screens/`, `docs/screens/`, and `docs/client_code/`.

## Action
Invoke the `ui-api-gap-audit` skill. Report the resulting `docs/api_coverage_audit/gap_report.md` path and summary counts (✅ / ⚠️ / ❌) when done.
