---
name: test-audit
description:
  Audit an existing test directory file by file and keep, rewrite, move, or delete each test by
  fixed rules, then report a verdict table. Use when trimming or hardening a test suite, or when
  asked to audit tests in a directory.
argument-hint: '<directory or test files>'
---

# Test audit

If the repository has its own test-audit skill (`.claude/skills/test-audit/` or
`.agents/skills/test-audit/`), follow that one instead.

Audit the tests under **$ARGUMENTS**. If the repository has a testing guide (`TESTING.md`, or a
testing section in `AGENTS.md` / `CONTRIBUTING.md`), read it first: it decides layers, commands,
and any areas it marks as protected. The goal is fewer, stronger tests: every deletion must name
what still covers the behavior, and no caller-visible behavior may lose its only test.

## Per file

1. Read the test file and the production code it covers. Identify each test's behavior in one
   sentence.
2. Decide each test (or parameterized case, or assertion) in this order:
   - If a **Keep** rule holds, the test is never deleted or moved, but it is still rewritten when a
     **Rewrite** rule holds.
   - Otherwise apply **Delete**, then **Move**, then **Merge**, the first that holds.
   - Then apply **Rewrite** to anything that remains and has a problem it lists.
3. Make the change. Rewrites follow the `writing-tests` skill.
4. Run the file's tests once, plus ten iterations of anything rewritten. Never run a full suite, and
   never run a suite the repository says not to run by default (tests that write to shared or
   production systems) unless that suite is the audit scope.

## Verdicts

| Verdict     | When                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Keep**    | A regression test from a real bug fix (`git log -S '<test name>'` finds the fix); pins an outside contract (released API field, wire enum value, analytics event, feature-flag key, persisted format, cross-platform fixture); checks caller-visible behavior through a public surface and would fail if it broke; or guards a production-safety mechanism (test-user guards, cleanup sweeps, leases).                                                       |
| **Rewrite** | Uses a sleep, a short fixed wait, or real time; asserts `toBe(true)`/`toBeDefined()`/`assert!(a == b)` where a value comparison exists; asserts mock calls on a read, or mocks one of the repository's own modules; depends on order or leaked shared state.                                                                                                                                                                                                  |
| **Move**    | An integration test that calls internal functions or the database instead of the public interface, or whose behavior a hermetic test can check: rewrite it at the unit layer. A UI-automation flow whose assertion a component test already covers.                                                                                                                                                                                                          |
| **Merge**   | Several tests of one behavior that differ only in inputs: fold into one parameterized test.                                                                                                                                                                                                                                                                                                                                                                  |
| **Delete**  | Restates a constant, default, metric, token, or schema declaration with no outside consumer; tests its own mock wiring, the type system, or framework behavior the app does not shape (a view rendering a static string unconditionally; text that depends on state, permissions, errors, or formatting is behavior); duplicates a test at the same or a cheaper layer (keep the faster one); covers removed code; covers local-only dev tooling that writes no production data; quarantined past expiry with no fix. |

If the repository's docs or the user name areas as core or protected, do not delete, move, or merge
their behavior tests; rewrite them only to strengthen them. Only pure constant or mock-wiring
restatements may go.

Never delete a test only because it has never failed or because it is slow. When unsure between Keep
and Delete, Keep and note it in the report.

## Guardrails

- Do not change production code, except to inject a clock or dispatcher a rewrite needs; keep such a
  change minimal and behavior-preserving.
- Do not weaken a kept test. A rewrite asserts at least what the original did.
- Stay inside the assigned directory. If a fix needs shared test support (a wait helper, a fake),
  use what exists; report anything bigger instead of building it.
- If a test fails before you touch it, leave it alone and report it with its error.

## Report

Report the verdict table, one row per changed test, followed by totals per verdict:

| File | Test | Verdict | Rule | Still covered by |
| ---- | ---- | ------- | ---- | ---------------- |

If the user asks for a PR, follow the repository's PR conventions and include the table in the PR
(or as a PR comment if the description has a length limit).
