---
name: simplify
description: Simplify and reduce complexity in code
argument-hint: '[file path or description of code to simplify]'
---

Simplify the following code: $ARGUMENTS

## Simplification Principles

- **Prefer small, focused units**: small functions, single responsibility, one level of abstraction
  per function
- **Early returns** over nested conditionals
- **Delete dead/unused code** -- don't leave stale paths or commented-out blocks
- **Keep things DRY without sacrificing clarity** -- choose clarity over brevity
- **Composition over inheritance**
- **Make invalid states unrepresentable** when feasible

## Process

1. Read and understand the target code
2. Identify complexity: deep nesting, long functions, unclear abstractions, redundant logic
3. Apply simplifications while preserving exact behavior
4. Run targeted tests or type checks when the simplification changes executable behavior
