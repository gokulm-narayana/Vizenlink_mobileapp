---
name: client-pipeline
description: Full pipeline for a client Dart file from client_code_inbox/ — document it, integrate it into the existing UI, sync screen docs, lint, and run.
aliases: ["/client-pipeline"]
---

# /client-pipeline

## Usage
`/client-pipeline <filename.dart>` — filename only assumes `client_code_inbox/<filename.dart>`; an explicit path overrides that.

## Action Steps
1. Run `client-code-docs` on the file (skip if `docs/client_code/<name>.md` already exists and the source file hasn't changed since).
2. Run `integrate-client-code` on the file, using the doc from step 1 as reference.
3. If step 2 changed UI elements on any screen, run `screen-docs` to keep the relevant `docs/screens/**/*.md` files and design IDs in sync.
4. Run `flutter-lint` and fix any reported issues.
5. Run `flutter-run` (or offer to) so the user can verify the integrated screen(s) visually.
6. Report a summary: file processed, screens touched, doc updated, lint status, and anything flagged back to the user (e.g. an unavoidable client-file change) rather than acted on automatically.
