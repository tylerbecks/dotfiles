## Available CLI Tools

When suggesting command-line solutions, use these modern tools:

- **rg**: Use instead of grep (faster, respects .gitignore)
  Example: `rg "pattern" ./src`

- **fd**: Use instead of find (better syntax, colored output)
  Example: `fd "\.js$" ./project`

- **ack**: Code-optimized search
  Example: `ack --python "function"`

- **jq**: JSON processor
  Example: `cat data.json | jq '.items[]'`

- **gsed**: GNU sed for text processing
  Example: `gsed -i 's/old/new/g' file.txt`

- **fzf**: Fuzzy finder for interactive selection
  Example: `history | fzf`

Prefer these tools over older alternatives when applicable.

## Tests

Repository testing guides (`TESTING.md`, `AGENTS.md`, `CONTRIBUTING.md`) take precedence over these defaults. Load the `writing-tests` skill before writing or changing a test.

- Test behavior, not declarations. A test earns its place by failing when caller-visible behavior breaks and staying green through a refactor. Re-asserting a constant, declaration, or mock's own setup tests nothing.
- While working, run only the tests your change affects. Run full suites only when asked or when shared test infrastructure changed, and then through the `test-runner` agent.
- Never make a run pass by weakening, skipping, or deleting an existing assertion, adding a retry, raising a timeout, or adding a sleep (replacing a short fixed wait with a condition wait is fine). If an existing test is wrong, fix it and say why.
- No sleeps or short fixed waits in tests: wait on a condition or advance an injected clock.
- If a failure looks unrelated to your change, rerun that test once before touching code. Stop after three failed fix attempts on one test and report what you found.
