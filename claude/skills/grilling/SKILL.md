---
name: grilling
description:
  Question the user round by round about a plan, design, or decision until every choice in it is
  settled. Use when the user asks to be grilled, to stress-test a plan, or to poke holes in an idea.
argument-hint: '[plan, file, or idea to grill]'
---

# Grilling

The goal is a plan with no choice left unmade or silently assumed. You ask; the user decides. Build
nothing until the user agrees the grilling is done.

Subject: **$ARGUMENTS** (if empty, the plan or idea under discussion)

## Map the choices

Treat the plan as a tree: each choice opens the choices that depend on it. Picking a storage engine
opens its schema, its migrations and its backups; picking "no auth" closes a whole branch. For a big
plan, keep the tree in a scratch file so nothing falls off.

## Ask in rounds

A round asks every question that can be answered now: the ones whose prerequisites are settled. A
question that depends on an answer you don't have yet waits for a later round, even if you can
guess the answer.

Number the questions and recommend an answer for each:

```
**1. <short title>**
<the question, with the options when there are a few>
→ Recommended: <answer>, because <one line>.
```

Word each question so that "yes" accepts your recommendation, and let the user answer briefly ("1
yes, 2 option b, 3 see below").

After each round, update the tree. Settled choices open new questions; an answer can also close a
branch or reopen an earlier choice. Say so when that happens.

## Facts are yours, choices are theirs

Never ask the user for something you can find out: how the code works now, what config exists,
which tools are installed, what a library supports. Look it up yourself, or send an `Explore` agent
for a wide search. Don't hold up the round for it: ask the questions that don't depend on the lookup
now, and the rest once it reports.

Ask the user only for choices and for what only they know: priorities, constraints, deadlines,
history, taste.

## Push back

Grilling is not a survey. Turn vague answers into specific ones ("fast" means how fast, for whom).
Point out when two answers conflict. Ask what happens when each piece fails, and who notices. When
you think the user is wrong, say why once; then it is their call.

## Finish

The grilling is done when no open questions remain. Write a summary of every settled choice and its
reason, ask the user to confirm it, and offer to save it where they want (a plan file, an issue, a
doc). Act on the plan only after they confirm.
