---
name: diagnosing-bugs
description:
  A step-by-step method for hard bugs and performance regressions, starting with a reliable repro.
  Use when the user says diagnose or debug this, or reports something broken, throwing, failing,
  flaky, or slow.
argument-hint: '[symptom, error, or failing command]'
---

# Diagnosing bugs

If the repository has its own debugging skill or guide, follow that one instead. Read the
repository's docs for the area first (`AGENTS.md`, `CLAUDE.md`, architecture notes, ADRs).

Bug: **$ARGUMENTS**

Work through the phases in order. Skip one only when you can say why it doesn't apply.

## Redact as you go

This method has you show commands and their output. Replace every secret with `<REDACTED>` before
showing it, keep credentials in environment variables rather than in commands, and quote only the
lines of a log or captured request that carry the signal. If the redacted output isn't enough to go
on, say so and ask the user.

## 1. Build a feedback loop

This is most of the work. With a fast check that fails on this bug, the rest is mechanical; without
one, reading code produces guesses. Put the most effort here, and try more options before giving up.

Ways to get one, cheapest first:

1. A failing test at the layer where the bug shows up.
2. A curl or HTTP script against a running dev server.
3. The CLI run on a fixture input, with its output compared to a known-good copy.
4. A headless browser script (Playwright) that drives the UI and checks the page, console or
   network.
5. A recorded request, payload or event log saved to disk and replayed through the code path.
6. A throwaway harness that runs just the broken code path, with its dependencies faked.
7. Many random inputs, when the bug is "sometimes wrong", to find which inputs fail.
8. `git bisect run` with a check script, when the bug appeared between two known commits or
   versions.
9. The same input through the old and new version (or two configs), with the outputs compared.
10. A human following [scripts/hitl.sh](scripts/hitl.sh), only when a person has to click or look.

Then make the loop better: faster (skip unrelated setup, narrow the scope), sharper (check the
exact symptom, not "didn't crash"), and steadier (pin the clock, seed randomness, isolate files and
network).

For a bug that only happens sometimes, aim for a higher failure rate rather than a clean repro: run
the trigger many times, in parallel, under load, or with the timing window widened. A loop that
fails half the time is workable; one that fails 1% of the time is not yet.

If you can't build a loop, stop and say so, with what you tried. Ask the user for access to an
environment that reproduces it, a redacted capture (a HAR file, logs, a screen recording with
times), or permission to add temporary instrumentation where it happens. Don't move on to theories.

**Done when** you can name one command, already run with its output shown, that:

- runs the real code path and checks the user's exact symptom, so it fails now and will pass once
  fixed
- gives the same result every run (or a steady, high failure rate for an intermittent bug)
- takes seconds
- runs without a person, except through `scripts/hitl.sh`

If you notice yourself reading code to form a theory before that command exists, stop and go back
to building it.

## 2. Reproduce and shrink

Run the loop and confirm the failure is the one the user described, not a nearby one, and that it
fails on repeated runs. Record the exact symptom (the message, the wrong value, the timing) to
check the fix against.

Then cut the scenario down: remove inputs, callers, config, data and steps one at a time, re-running
after each cut, until removing anything else makes it pass. The smaller the repro, the fewer
suspects in the next phase, and it becomes the regression test later.

## 3. Hypothesize

Write down three to five ranked causes before testing any. Stopping at one anchors you on the first
plausible idea.

Each needs a prediction you can check: "If X is the cause, changing Y makes the bug go away (or
changing Z makes it worse)." A cause without a prediction is a hunch; sharpen it or drop it.

Show the ranked list to the user. They often know something that reorders it ("we changed number 3
last week"). Keep going with your order if they don't answer.

## 4. Test the hypotheses

Each probe checks one prediction, and changes one thing at a time.

- Prefer a debugger or REPL; one breakpoint beats ten log lines.
- Otherwise add logs only at the points that tell your hypotheses apart. Never log everything and
  search afterwards.
- Tag every debug log with one unique prefix, such as `[DEBUG-a4f2]`, so cleanup is a single search.

For a performance regression, measure instead of logging: take a baseline (a timing harness, a
profiler, a query plan), then bisect or profile to where the time goes. Measure before fixing.

## 5. Fix it, with a test that would have caught it

Load the `writing-tests` skill first. Write the regression test before the fix, at a place where it
exercises the bug the way it really happens. A test at a shallower layer (one caller, when the bug
needs two) passes without proving anything. If there's no such place, say so: the code's structure
keeps this bug from being tested, which is worth reporting on its own.

1. Turn the shrunken repro into that test, and watch it fail for the right reason.
2. Apply the fix and watch the test pass.
3. Run the phase 1 loop on the original, unshrunk scenario.

If three fixes in a row don't work, stop patching. Go back to phase 3 with what you learned, and
tell the user.

## 6. Clean up

Before calling it done:

- The phase 1 loop passes on the original scenario.
- The regression test passes, or the missing test is explained.
- No debug logs are left (search for the prefix) and throwaway harnesses are deleted.
- The tests the change affects pass, run through the `test-runner` agent.
- The commit or PR message states the cause that turned out to be right, so the next person
  debugging nearby learns from it.
