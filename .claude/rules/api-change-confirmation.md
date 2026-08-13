---
paths:
  - "packages/camera_api/**"
---

# API change confirmation rule

`packages/camera_api` is the sole network-access layer for talking to a camera (see root
`CLAUDE.md` Architecture section). Because every screen in the app ultimately depends on this
package being correct, no change to it may be made silently.

**Before editing, adding, or removing anything under `packages/camera_api/**`** (client classes,
request/response models, generated `rest_*.dart` files, ONVIF/nuraeye/WAN transport code, its
`API_REFERENCE.md`/`SETTINGS_API_GUIDE.md`, or its `pubspec.yaml`/dependencies), stop and ask the
user first. Do not proceed with the change until the user explicitly accepts it — if they decline
or don't respond, leave the change pending (describe it, don't apply it) and continue with
whatever else was asked.

The ask must include, in plain terms:

- **What** needs to change — the specific file(s)/method(s)/field(s) affected.
- **Why** it needs to change — the concrete reason (e.g. a screen needs a capability that doesn't
  exist yet, a bug in the existing client, a camera firmware behavior the current code doesn't
  handle).
- **Impact** — what else in the app calls this code today (if anything) and could be affected.

This applies regardless of how the change was triggered — a screen-integration task, a bug fix, a
gap-audit follow-up, or a direct request that only *implies* an API change without spelling it
out. If a task turns out to require touching `camera_api` partway through, pause at that point,
ask, and only continue into the package once accepted.

This rule does not require confirmation for read-only work (running `camera_api`'s existing test
suite, reading/grepping its source, or referencing it in a gap-audit report) — only for actual
edits to the package.
