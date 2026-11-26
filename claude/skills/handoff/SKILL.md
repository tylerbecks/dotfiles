---
name: handoff
description:
  Write a handoff note so a fresh session can pick up this work without the conversation. Use when
  asked for a handoff, or before clearing context or moving the work to another session or machine.
argument-hint: '[what the next session will do]'
---

# Handoff

Write a note that a new agent, with nothing but the note and the repository, can start from cold.

Next session: **$ARGUMENTS**

If that is filled in, shape the note around it and leave out what that work won't need. If it is
empty, hand off the whole task.

## Gather, don't recall

Read the current state instead of reconstructing it from memory:

- `git status`, `git log --oneline` for this branch's commits, `git worktree list` if it matters
- `gh pr view --json url,state,statusCheckRollup,reviewDecision` when the branch has a PR
- The task list or plan file, if this session kept one

## What goes in

1. **Goal**: what the user asked for, and what done looks like. Quote the user where the exact
   words matter.
2. **State**: repository, branch, worktree path, commits so far, uncommitted changes, PR link with
   its CI and review state.
3. **Decisions**: what the user decided and why, including the options they turned down, so the
   next session doesn't reopen them.
4. **Verified**: what was checked and how (the command or test). Then what is _not_ verified yet.
5. **Next steps**, in order. Make the first one concrete enough to start without asking anything.
6. **Traps**: what cost time here, such as commands that hang, denied permissions, flaky tests, or
   wrong assumptions that were corrected.
7. **Skills**: which skills the next session should load, and for what.

## What stays out

- Anything an artifact already holds. Link the spec, plan, issue, PR, commit or file instead of
  restating it; the diff lives in git.
- The story of how you got here. Write the state, not the history.
- Secrets: keys, tokens, passwords, cookies, and private hostnames. Write `<REDACTED>` in their
  place. Leave out personal details the work doesn't need.

Aim for a page. A longer note usually means something belongs in an artifact instead.

## Write it

Save it as `${TMPDIR:-/tmp}/handoff-<repo>-<YYYYMMDD-HHMM>.md`, outside the repository so it is
never committed. Then give the user its full path and a line to paste into the new session:

```
Read <path> and continue from its next steps.
```

Stop there. The next session does the work.
