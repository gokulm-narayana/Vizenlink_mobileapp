---
name: git-push
description: Push the current branch to its remote, after checking status and getting confirmation for anything risky (force-push, no upstream, diverged history).
aliases: ["/git-push"]
---

# /git-push

## Usage
`/git-push` — push the current branch. `/git-push --force` — force-push (only if the user explicitly asks; still confirm first).

## Action
1. `git status` — confirm there are no uncommitted changes that the user likely meant to include; if there are, surface them and ask before proceeding (don't auto-commit).
2. `git branch --show-current` — identify the branch being pushed; refuse to force-push `main`/`master` without explicit, separate confirmation.
3. `git status -sb` / `git rev-parse --abbrev-ref --symbolic-full-name @{u}` (may error if no upstream) — determine whether the branch already tracks a remote:
   - If no upstream exists, push with `-u origin <branch>` to set tracking, but confirm the remote/branch name with the user first if ambiguous.
   - If an upstream exists, `git fetch` and compare `@{u}`...`HEAD` to check for diverged history before pushing, since a plain push will fail (and a force-push would overwrite remote commits).
4. Run the push:
   - Normal: `git push` (or `git push -u origin <branch>` if no upstream).
   - Force (only when explicitly requested): prefer `git push --force-with-lease` over `--force` since it fails safely if the remote has commits the local repo hasn't seen, instead of silently overwriting them.
5. Never push to `main`/`master`, and never force-push anything, without first stating exactly what will happen and getting explicit confirmation — this is a shared-state, hard-to-reverse action per the project's execution-care rules.
6. Report the result: branch pushed, remote, and whether a new upstream was set.
