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

## Snowflake (gobi data_pipeline)

`SNOWFLAKE_USER` and `SNOWFLAKE_PASSWORD` are available in the shell env, sourced
from `~/.config/gobi/snowflake.env` via `~/.zshenv`. `snowflake_conn_params()` in
`data_pipeline/common.py` reads them (account `FNCTKLU-KK70869` is hardcoded).

- **Run a pipeline script** from the repo/worktree ROOT (not `data_pipeline/`):
  `data_pipeline/.venv/bin/python -m data_pipeline.<module.path>`
- **Read-only queries and dry-runs are fine to run directly.** Prod-mutating
  backfills are user-run — give the command and review the dry-run output.
- **If creds are missing/expired**, ask the user to refresh (interactive
  `gcloud auth login` first, then re-write the env file from Secret Manager,
  project `pure-spirit-452502-i6`):
  ```sh
  umask 077 && mkdir -p ~/.config/gobi && {
    printf 'export SNOWFLAKE_USER=%q\n'     "$(gcloud secrets versions access latest --secret SNOWFLAKE_USER     --project pure-spirit-452502-i6)"
    printf 'export SNOWFLAKE_PASSWORD=%q\n' "$(gcloud secrets versions access latest --secret SNOWFLAKE_PASSWORD --project pure-spirit-452502-i6)"
  } > ~/.config/gobi/snowflake.env
  ```
