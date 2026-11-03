# dotfiles

Setup scripts and config for my Macs, both personal and Meta work laptops.

- `fresh.sh` sets up a new machine (`bash ~/dotfiles/fresh.sh`, never `source`); it calls `brew.sh`, `setup-mise.sh` and `.macos`. `refresh.sh` updates everything.
- `lib/profile.sh` decides work vs personal (`/var/facebook` exists on work laptops, `--work`/`--personal` override). Anything new must decide which machines it belongs on; gate it with `is_work`/`is_personal`.
- Machine-specific settings stay in local files that include the shared ones (`~/.gitconfig` includes `.gitconfig`, `~/.claude/CLAUDE.md` imports `claude/CLAUDE.md`). Don't symlink over those files.
- `zsh/.zshrc` loads `zsh/config/*.zsh`, then `functions/` and `aliases/`.
- Keep `README.md` in sync when adding or removing scripts, apps, or manual steps.

## Rules

- **This repo is public.** Never commit secrets or Meta-internal details (internal hostnames, credential paths, internal tool names). Those belong in the machine's local files.
- Commits use my personal email; the repo's git config already sets it.
- Don't run `fresh.sh`, `brew.sh` or `.macos` to test: they use sudo, change system settings and quit apps. Check syntax with `bash -n` / `zsh -n`, and test file changes against a throwaway `HOME` (`HOME=$(mktemp -d) ...`).
- If `git push` fails with "Operation not permitted", the agent sandbox is blocking SSH; ask me to run `! git -C ~/dotfiles push`.
