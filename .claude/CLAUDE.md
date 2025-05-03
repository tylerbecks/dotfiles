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

## Git Commits

Use conventional commits with these prefixes:

- 🚀 feat: New features
- 🐛 fix: Bug fixes
- 📚 docs: Documentation changes
- 🛠️ refactor: Code refactoring
- ⚡ perf: Performance improvements
- 🧪 test: Adding or updating tests
- 🧹 chore: Maintenance tasks
