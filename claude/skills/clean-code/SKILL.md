---
name: clean-code
description:
  Review the current change set for correctness, structure, naming, tests, and comments. Use before
  opening a PR, or when asked to review a branch, PR, or files.
argument-hint: '[git ref | file paths | PR number]'
---

# Clean Code Review

If the repository has its own clean-code skill (`.claude/skills/clean-code/` or
`.agents/skills/clean-code/`), follow that one instead.

Spawn `code-reviewer`, `test-reviewer`, and `comment-reviewer` in one turn, each with the argument
and scope below. Merge their findings into one severity-grouped report.

Argument: **$ARGUMENTS**

## Context

- Branch: !`git branch --show-current`
- Base: !`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main`
- Diff stat vs base: !`git diff --stat "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)"...HEAD 2>/dev/null | tail -8`
- Working tree: !`git status --porcelain | head -30`

## Scope

`BASE` is the base above. If the GitHub remote is not named `origin`, use that remote's default
branch instead.

| Argument                 | Review                                                                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| empty                    | `git diff $(git merge-base BASE HEAD)` plus untracked source (`git ls-files --others --exclude-standard`). On the base branch: `git diff HEAD` + untracked. |
| PR number or URL         | `gh pr diff "$ARGUMENTS"`                                                                                                                                    |
| `A..B` / `A...B` / a rev | that range, or `git show <rev>`                                                                                                                              |
| paths                    | those files, whole                                                                                                                                           |

Drop lockfiles, generated files, generated migrations, binaries, and `.env*`.

## Report

Report confirmed findings only — zero is fine. Deduplicate the same root cause; keep file, lines,
and worker tag. Do not demand refactors of untouched legacy.
