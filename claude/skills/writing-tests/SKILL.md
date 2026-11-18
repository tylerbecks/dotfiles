---
name: writing-tests
description:
  How to write or change a test so it catches real regressions and never flakes. Use before adding,
  rewriting, or fixing any test, in any language or framework.
---

# Writing tests

If the repository has its own writing-tests skill (`.claude/skills/writing-tests/` or
`.agents/skills/writing-tests/`), follow that one instead. If it has a testing guide (`TESTING.md`,
or a testing section in `AGENTS.md` / `CONTRIBUTING.md`), that guide decides layers, commands, and
shared helpers; this skill is the working checklist around it.

## Before writing

1. **Name the regression.** Write down, in one sentence, the bug this test would catch. If you
   cannot, or the bug is "someone changes the constant," do not write the test.
2. **Check what exists.** Search the sibling test file and its neighbors. Extend an existing test or
   parameterized case before adding a new one; a duplicate at the same layer is a deletion candidate
   later.
3. **Pick the cheapest layer that can see the bug.** Do not add an end-to-end or UI-automation test
   for something a unit or component test can observe.
4. **Count.** One test per behavior. A change usually needs a few tests, not one per branch of the
   implementation. Agent-written suites fail more often from volume than from gaps.

## Writing

- **Assert through the public surface:** an API caller's response, a view model's published state,
  a reducer's output, a function's return value or rows written. Do not assert private fields, call
  order on reads, or which helper ran.
- **Assert values with diffs:** `toEqual`, `toContain`, `toHaveLength`, `assert_eq!`,
  `XCTAssertEqual`, `assertEquals`, plain `assert a == b`. Never `expect(x).toBe(true)`,
  `assert!(a == b)`, or a bare `toBeDefined()` when a value comparison exists.
- **Write the expected value from the requirement, not from running the code.** An expected value
  copied from current output encodes whatever bug the code has.
- **Do not restate declarations:** constants, defaults, design tokens, schema columns, registry
  entries, or what a mock returns. Exact literals are for outside contracts only: released API
  fields, wire enum values, analytics event names, feature-flag keys, persisted formats, shared
  cross-platform fixtures.
- **Mock only what you do not own:** third-party APIs, LLM providers, payments, email/SMS/push, the
  network, the clock. Use real code for the repository's own modules and stores. Mocking one of
  your own modules is a smell.
- **No logic in tests:** no loops or conditionals computing the expected value. Use a table of cases
  instead.

## Never flaky by construction

Most flaky tests are flaky from the day they are written, and the top cause is waiting on async work
by wall-clock time.

| Instead of                                                    | Do                                                                                                   |
| ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `sleep`, `Thread.sleep`, `Task.sleep`, `time.sleep`           | Await the owned task or job, or wait on a condition                                                  |
| `setTimeout` promises, real timers (JS/TS)                    | Fake timers (`vi.useFakeTimers()`, `jest.useFakeTimers()`) and advance time; restore in teardown     |
| `tokio::time::sleep` on a real clock (Rust)                   | `#[tokio::test(start_paused = true)]` or `tokio::time::pause()`, then `advance`; or await the task   |
| XCTest `timeout: 1` or `2`                                    | A condition wait with a bound of at least 5 s; a loaded CI runner is slow, not broken                |
| `Date()`, `Date.now()`, `SystemTime::now()`, `datetime.now()` | An injected clock the test controls                                                                  |
| `Dispatchers.Main`/`IO` inside the code under test (Kotlin)   | An injected dispatcher; `runTest` with a `StandardTestDispatcher` and `advanceUntilIdle()`           |
| Compose `Thread.sleep` or latches                             | `composeTestRule.waitUntil { … }` for work outside Compose; let the rule's clock sync the rest       |
| Random IDs, shuffled order, unseeded randomness               | Fixed seeds and fixed fixtures                                                                       |
| State another test created; shared singletons; fixed ports    | Fresh state per test; reset in teardown even when an assertion fails; ephemeral ports and temp dirs |
| Real network or production in a unit test                     | A fake at the boundary                                                                               |

Do not add another private `waitUntil` helper if the repository already has one; use the shared one
or extend the closest shared support file. Cancel owned tasks, release gates, clear callbacks, and
close servers in teardown.

Evals of non-deterministic output (LLM responses, ranking quality) judge with thresholds over
several samples; a single live draw is not a pass/fail fact.

## Before you finish

1. **See it fail.** For a bug fix, run the test against the old behavior (or break the code briefly
   in your working tree, never in a commit) and confirm it fails for the right reason. A test that
   passed on its first run against your own new code is weak evidence.
2. **Run it repeatedly.** Ten iterations of the new or rewritten test: a shell loop over the scoped
   command, or the runner's repeat option (`-test-iterations 10 -run-tests-until-failure` for
   XCTest, `pytest --count 10` with pytest-repeat, `vitest --repeat`).
3. **Run only the affected tests**, not the full suite.
4. **Never weaken an existing test to get green.** No loosened or deleted assertions, skips,
   retries, longer fixed timeouts, or sleeps. If an existing test is wrong, fix it and say why in
   the PR.
