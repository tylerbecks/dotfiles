---
name: babysit
description: >-
  Babysit a GitHub pull request until it merges. Use when asked to watch, shepherd, or babysit a
  PR: monitor checks and reviews, fix failures and conflicts, push follow-up commits, resolve review
  threads, keep the branch current with its base, and enable auto-merge.
---

# Babysit

Own the PR until GitHub reports `MERGED`. This authorizes fixes, commits, pushes, thread resolution,
base merges, and enabling auto-merge. Ask only when the PR is unknown or a product decision,
permission, or external blocker requires the user.

Never bypass protection, admin-merge, dismiss reviews, close the PR, or change another PR. Never
post a comment or thread reply without the user's approval: it speaks for them in public. Preserve
unrelated work.

## Repository rules come first

If the repository has its own babysit skill (`.claude/skills/babysit/` or `.agents/skills/babysit/`),
follow that one instead and stop reading this file.

Otherwise, before the first write, read the repository's agent and contribution docs (`AGENTS.md`,
`CLAUDE.md`, `CONTRIBUTING.md`, and anything they point to for source control, CI, review, or
release). They decide, over the defaults here:

- commit message format, and whether follow-up fixes are new commits or amends;
- the merge method (squash, merge commit, rebase) and whether a merge queue is used;
- which CI provider runs the checks and how to read or rerun them;
- automated review bots or workflows and how to request or wait for them;
- flaky-test logs, schema/compatibility gates, and post-merge release obligations.

When the docs are silent, use the merge methods the repository allows
(`gh repo view OWNER/REPO --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`),
preferring squash, and match the style of recent commits on the base branch (`git log`).

## History safety

The GitHub remote is `origin` unless the repository docs or `git remote -v` show it under another
name; the commands in this skill use `origin` to mean that remote.

Prefer merging the latest base and ordinary pushes. Rebase/force-push only to repair this branch's
own history, never to remove a leaked secret, and only when all conditions hold:

1. It is a personal branch and every commit unique to it is authored by the current user.
2. Its remote SHA still equals the last observed/pushed SHA; re-read it immediately before pushing.
3. The PR is open with auto-merge disabled. Disable it first (`gh pr merge --disable-auto`) and
   re-enable it only after verifying the rewritten head.
4. No human approval is invalidated, unless that reviewer explicitly consents and it is recorded.
5. No intended content is lost; record the pre-rewrite SHA for recovery.
6. Use `--force-with-lease=<ref>:<expected-sha>`, never bare `--force`.
7. Fetch and verify before, then confirm the remote SHA after:

```bash
git fetch origin <base>
git rev-list --count HEAD..origin/<base>
git diff origin/<base>...HEAD --stat
git log origin/<base>..HEAD --oneline
```

Only condition 4 can be satisfied by asking. If any other condition cannot be proved, stop and name
it. A nonzero commit count or a diff far larger than the intended work signals a stale base; repair
it before enabling auto-merge. Prefer a merge for conflicts because it preserves reviewed history;
rebase only when repository policy requires it or the branch history itself is the problem, under
the rules above. If the repository squash-merges, a merge commit on the branch disappears at merge
time anyway.

## Loop

1. Verify `gh` auth, resolve the PR, ensure the worktree is safe, fetch head/base, and check the
   base with the commands above.

   Do not trust `gh auth status`'s invalid-token wording alone. Inspect
   `gh auth status --json hosts`: DNS, connection, TLS, proxy, and timeout errors are connectivity
   failures, not reasons to re-authenticate. Only HTTP 401 or `Bad credentials` confirms invalid
   credentials; for HTTP 403, inspect the response for scope, SSO, or rate-limit failures. On a
   connectivity failure, prefer any available authenticated API-based GitHub access over interactive
   browser access for supported reads, mutations, and monitoring. If completion still requires
   unavailable Git fetch or push, report the connectivity blocker.

2. Record PR/head/base state, mergeability, merge state, auto-merge state, checks, submitted
   reviews, and all unresolved review threads via thread-aware GraphQL (`id`, comments, path/line,
   `isResolved`, `isOutdated`). Record any review-bot comments, runs, and the head SHA they reviewed.
3. Keep a head-SHA ledger of checks, threads, reviews, review requests, auto-merge changes, base
   merges, and attempted fixes. Re-read remote state before every write; integrate concurrent
   pushes.
4. Watch the PR with the read-only watcher below. It polls GitHub internally and emits JSONL only
   for a baseline, a meaningful transition, or watcher-health failure. Handle emitted transitions,
   in order: review feedback; head checks/conflicts; base drift; merge eligibility and auto-merge
   state; waits.

The watcher exits after emitting `TRANSITION` or `QUIET`, so process exit is the event: run it,
handle the emitted JSON, then run the identical command again. Run it in the background where the
harness notifies you when a background command exits; otherwise run it in the foreground with a
timeout above eleven minutes. `WATCHER_ERROR` reports health but keeps polling; keep waiting on that
same process until it exits before restarting it. Its state file is keyed to the repo and PR, so a
re-run resumes.

```bash
bun ~/.claude/skills/babysit/scripts/watch.ts --repo OWNER/REPO --pr NUMBER
```

Pass nothing else. `--state` defaults per repo and PR, and the ten-minute cap is enforced
internally, so do not wrap the command in `timeout`. The first run returns current state; later runs
block until a transition, or emit `{"type":"QUIET"}` and exit when the cap elapses. `QUIET` means no
change: run the command again.

Use a 30-second interval by default and increase it with `--interval` while waiting on long checks.
It invokes only fixed read operations through `gh`, never accepts an API endpoint, and performs no
mutations. Its state file's `lastSuccessfulPollAt` is the deadman signal. A `WATCHER_ERROR` is a
watcher-health event, not a GitHub state transition; diagnose repeated failures rather than
interpreting missing data as a PR change. If `bun` is not installed, poll the same reads with `gh`
at a similar interval instead.

The watcher fingerprints comment bodies and update timestamps, so a bot that edits one status
comment in place (`in progress` → `completed`) shows up as `COMMENT_CHANGED` on the same comment ID.
Treat that like a newly observed state. Continue to re-read remote state directly immediately before
every write.

Every push invalidates prior checks and mergeability. It does not invalidate a completed review;
re-evaluate its findings against the new head.

## Review

Wait for whatever review the repository requires. Read every submitted review, not just threads:
review bodies may hold actionable feedback with no thread attached. Sweep reviews again immediately
before enabling auto-merge.

For automated reviewers, follow the repository's process for when they run and how to re-request
them. Do not re-request a review merely because the head changed; do it only when fixes materially
reshape the implementation, behavior, or risk model so the earlier review no longer gives adequate
confidence, and then wait for it before enabling auto-merge. If a bot review fails or never starts,
inspect its run, retry a verified transient failure once, and otherwise report the blocker.

If the PR needs a human approval that has not arrived, keep everything else green and report that
it is waiting on review; do not ping reviewers without the user's approval.

## Repair

- Verify each unresolved thread against current code. Fix accurate findings with the smallest
  complete change and regression coverage, batch compatible fixes, validate, commit following the
  repository's conventions, and push. Ask only when evidence cannot settle ambiguous, conflicting,
  or product-level feedback.
- After pushing, re-read the remote threads, then resolve the fixed ones with `resolveReviewThread`
  and confirm `isResolved: true`. Resolve a bot's already-satisfied or inaccurate finding without a
  performative edit. For a human reviewer's finding you believe is inaccurate, leave the thread open
  and give the user the explanation to post. Outdated does not mean resolved; top-level comments and
  reviews are actionable but unresolvable.
- Diagnose current-head failures with `gh pr checks`. For GitHub Actions, read logs with
  `gh run view --log-failed` and rerun with `gh run rerun --failed`. For other CI providers, follow
  the check's details URL and use that provider's CLI if it is installed and authenticated;
  otherwise report the failing check, its URL, and what you could not read. Fix deterministic
  failures; rerun a verified flaky or infrastructure failure once; require all required checks. If
  the repository keeps a flaky-test log, record verified flakes there under its rules. Do not alter
  code to hide infrastructure noise or ignore cancelled/superseded runs without a newer current-head
  run.
- Resolve conflicts by merging the latest base, validating, committing, and pushing. Apply the
  history-safety rules above if a rebase is necessary.
- A failing non-required gate that reports an intended change (a compatibility or schema check, for
  example) is the user's call: confirm the change is intended, leave the gate red, and do not weaken
  or revert the change merely to pass it.

## Merge and finish

Merge only a current head with required checks passing and no actionable review feedback or
unresolved threads.

Unless the branch ruleset requires branches to be up to date, the PR head's own checks are the
final gate: nothing re-tests this change against the latest base before it lands. So before
enabling auto-merge, and on every `BASE_CHANGED`, fetch the base and inspect what moved. If
mergeability is `CONFLICTING`, or the branch is `BEHIND` and the new base commits touch the same
files, contracts, or schema as this PR, merge the latest base, validate, push, and wait for fresh
head checks. Read the ruleset (`gh api repos/OWNER/REPO/rules/branches/BASE`) when you need to know
what it requires.

Enable auto-merge on the verified head with the repository's merge method; GitHub merges once
requirements pass, or adds the PR to the merge queue when the base uses one:

```bash
gh pr merge NUMBER --repo OWNER/REPO --squash --auto --match-head-commit HEAD_SHA
```

(`--merge` or `--rebase` in place of `--squash` as the repository requires.)

Run it only after every required check has a run that started after the head's latest push and its
latest `ready_for_review`. Required jobs often skip on draft runs, and those skipped checks read as
passing on the same head until the ready run replaces them; `--auto` on a PR that already reads
`CLEAN` merges at once. If the repository has auto-merge disabled, wait for the same conditions and
merge directly with `--match-head-commit`. Leave an existing auto-merge request in place. GitHub
disables auto-merge when the PR is retargeted to a different base branch or a user without write
access pushes; on `AUTO_MERGE_CHANGED` to `false` without a merge, find the cause and re-enable once
the head is eligible again.

If auto-merge stays enabled with green required checks but the PR does not merge, read
`mergeStateStatus` (`BLOCKED`, `BEHIND`, `DIRTY`, `UNSTABLE`) and the ruleset requirements to find
the blocker. Fix it only when this PR is responsible; retry a transient failure once. Wait or report
when another PR/service is responsible. Stop retrying an identical failure without new
head/base/evidence.

### Stacked PRs

Merge bottom-up, and only PRs the user authorized; ask before including any other PR. A child that
targets its parent's branch waits until the parent merges. Then retarget it to the default branch
(`gh pr edit NUMBER --base <default>`) if GitHub did not, merge the latest base to drop the parent's
pre-squash commits from its diff, re-read head/base, reviews, and fresh checks, and enable
auto-merge.

If `gh pr merge --auto` rejects a stacked PR with
`Auto-merge is not supported for stacked pull requests`, wait for required checks and merge it
directly with `--match-head-commit`. To repair a PR's stack membership, use the current
[stack API](https://docs.github.com/en/rest/pulls/stacks) and verify its mutation scope first; do
not alter other PRs without explicit authorization.

## Done

Stop only when the PR is merged, closed without merging, or genuinely blocked as defined above. If
the repository docs name a post-merge step (a release, deploy check, or migration), report it; do
not run a production release or bypass yourself.

Report the URL, outcome/blocker, pushed commits, base merges, repaired/rerun checks, resolved
threads, reviews, auto-merge changes, and any post-merge obligation. Green or auto-merge enabled is
not done.
