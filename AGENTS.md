# dotfiles

Setup scripts and config for my Macs, both personal and Meta work laptops, plus Linux dev boxes.

- `fresh.sh` sets up a new machine (`bash ~/dotfiles/fresh.sh`, never `source`); it calls `brew.sh`, `setup-mise.sh` and `.macos`. `refresh.sh` updates everything.
- `linux.sh` is the Linux counterpart: config only (no package installs, no system settings), safe to re-run, and it appends include lines to the box's own `~/.zshrc`, `~/.bashrc` and `~/.gitconfig` instead of replacing them. Linux-only git settings live in `config/git/linux`. Zsh config must tolerate missing tools on Linux (guard with `command -v`).
- Every config file the repo puts in `~` is a row in `CONFIG_FILES` (`lib/config-files.sh`). `fresh.sh`, `linux.sh` and `refresh.sh` apply it and `doctor.sh` checks it, so a new config file is one row there, not `ln` lines in the scripts.
- zsh plugins are listed once, in `lib/zsh-plugins.sh`, used by both setup scripts and `doctor.sh`.
- Apps and CLI tools go in `Brewfile` (personal-only ones inside `unless work`); language runtimes and npm CLIs go in `config/mise/config.toml`.
- `lib/profile.sh` decides work vs personal (`/var/facebook` exists on work laptops, `--work`/`--personal` override). Anything new must decide which machines it belongs on; gate it with `is_work`/`is_personal`.
- Machine-specific settings stay in local files that include the shared ones (`~/.gitconfig` includes `.gitconfig`, `~/.claude/CLAUDE.md` imports `claude/CLAUDE.md`). Don't symlink over those files.
- `zsh/.zshrc` loads `zsh/config/*.zsh`, then `functions/` and `aliases/`.
- Keep `README.md` in sync when adding or removing scripts, apps, or manual steps.

## Rules

- **This repo is public.** Never commit secrets or Meta-internal details (internal hostnames, credential paths, internal tool names). Those belong in the machine's local files.
- Commits use my personal email; the repo's git config already sets it.
- Don't run `fresh.sh`, `brew.sh` or `.macos` to test: they use sudo, change system settings and quit apps. Check syntax with `bash -n` / `zsh -n` and `shellcheck -x -S warning` (CI runs both, plus the tests and `linux.sh` on Ubuntu; see `.github/workflows/ci.yml`). Test file changes against a throwaway `HOME` with `~/dotfiles` linked to your checkout (`T=$(mktemp -d); ln -s "$PWD" "$T/dotfiles"; HOME=$T ...`): the config scripts refuse to run from any copy that isn't `~/dotfiles`.
- If `git push` fails with "Operation not permitted", the agent sandbox is blocking SSH; ask me to run `! git -C ~/dotfiles push`.
