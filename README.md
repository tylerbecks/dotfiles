# dotfiles

A collection of configuration files for setting up a new macOS machine, plus
the shell and git config for remote Linux dev boxes.

## Installation

Run the setup script to install all dependencies and configurations:

```bash
bash ~/dotfiles/fresh.sh
```

The script detects work laptops and skips personal-only apps and settings
there. Override the detection with `--work` or `--personal`.

Later, `bash ~/dotfiles/refresh.sh` updates packages and re-links config, so
config added to the repo since a machine was set up reaches it too.
`bash ~/dotfiles/doctor.sh` checks a machine against the repo without changing
anything (config links, Claude Code hooks, zsh plugins, tools, Brewfile); the
setup scripts run it at the end.

### Linux dev boxes

```bash
bash ~/dotfiles/linux.sh
```

This links the zsh, git, bat, btop and Claude config without replacing the
box's own `~/.zshrc`, `~/.bashrc` or `~/.gitconfig` (it appends include lines),
and switches interactive bash terminals to zsh. It needs network access to
clone oh-my-zsh, the zsh plugins and Starship; re-run it if those steps warn.
CLI tools (fzf, fd, eza, bat, zoxide, difftastic, delta, btop, gh) come from the
box's package manager; the script lists any that are missing, and notes when
`bun` is missing (the babysit skill's PR watcher uses it). For Node, put
[fnm](https://github.com/Schniz/fnm) in `~/.local/bin`; zsh loads it when present.

## Directory Structure

- `Brewfile`: Homebrew packages and apps, split into work and personal
- `brew.sh`: Installs Homebrew and everything in the `Brewfile`
- `fresh.sh`: Main installation script
- `linux.sh`: Config-only setup for Linux dev boxes
- `refresh.sh`: Updates packages and re-applies the config files
- `doctor.sh`: Read-only check that a machine matches the repo
- `setup-mise.sh`: Language runtimes and global CLIs via mise
- `setup-git-signing.sh`: Opt-in commit and tag signing with an SSH key in 1Password, for one Mac at a time (see [Manual Setup Steps](#manual-setup-steps))
- `.macos`: macOS system preferences
- `bin/`: Personal scripts on the `PATH`, including `wt` (see [Worktree slots](#worktree-slots-for-parallel-agents)) and `browser-rules`
- `browser/`: Chrome rules: a uBlock Origin Lite filter list and per-site Stylebot CSS, synced with `browser-rules` (setup in [browser/README.md](browser/README.md))
- `lib/`: Shared helpers for the setup scripts (logging, work/personal detection, zsh plugins, Claude Code settings merge). `lib/config-files.sh` lists every config file the repo puts in `~` (see [Adding a config file](#adding-a-config-file))
- `.github/workflows/ci.yml`: On every push, runs shellcheck, the zsh syntax check and the tests, and runs `linux.sh` twice and then `doctor.sh` on a clean Ubuntu box. `.github/dependabot.yml` opens a monthly PR when the actions it uses have new versions
- `zsh/`: Modular ZSH configuration
  - `aliases/`: Command aliases organized by category
  - `config/`: ZSH configuration modules (history, path, plugins, etc.)
  - `functions/`: Custom ZSH functions
- `wezterm/`: Terminal configuration
- `config/`: Various application configurations
- `claude/`: Global Claude Code instructions (imported from `~/.claude/CLAUDE.md`) the status line script and the worktree-slot hook (both merged into `~/.claude/settings.json` by the setup scripts)
  - `skills/` and `agents/`: Personal Claude Code skills and subagents, each linked into `~/.claude/skills/` or `~/.claude/agents/` by the setup scripts. They follow a repo's own docs and conventions where it has them. Skills: `babysit` (shepherds a GitHub PR to merge; its watcher needs `bun`, installed by mise on Macs), `clean-code` (runs the `code-reviewer`, `test-reviewer` and `comment-reviewer` agents over a change), `writing-tests`, `test-audit`, `simplify` and `visual-parity`. The `test-runner` agent runs the tests a change affects.
  - `guard.sh`: Hook that stops Claude from running recursive force deletes, force pushes and hard resets, skipping git hooks (`--no-verify`, `git commit -n`), or editing `.env` files and `.git/` (merged into `~/.claude/settings.json`; tests in `guard.test.sh`)
  - The same merge sets `GIT_EDITOR`, `GIT_SEQUENCE_EDITOR` and `GIT_MERGE_AUTOEDIT` in `settings.json`'s `env`, so git commands Claude runs never wait on an editor (`code --wait` would hang them). Your own terminal keeps VS Code
- `vscode/`: VS Code and Cursor settings, keybindings, and snippets (linked into whichever is installed)
- `btop/`: System monitoring configuration with Night Owl theme
- `starship/`: Shell prompt configuration

## ZSH Configuration

The ZSH configuration is organized into modules:

- `history.zsh`: Command history settings
- `path.zsh`: PATH environment variable configuration
- `fzf.zsh`: Fuzzy finder configuration
- `plugins.zsh`: Oh-My-ZSH plugins
- `misc.zsh`: Other settings and tools

## Adding a config file

Add a row to `CONFIG_FILES` in `lib/config-files.sh`; the setup scripts,
`refresh.sh` and `doctor.sh` all read that list. Each row says how the file gets
into `~` (`link`, `copy` for files an app rewrites itself, `line` to add an
include line to a file that stays the machine's own, or `git-include`) and which
machines want it (`all`, `mac`, `linux`, `vscode`, `cursor`). A real file in the
way of a link is moved aside to `<name>.pre-dotfiles`, not deleted.

## Worktree slots for parallel agents

`bin/wt` keeps a fixed pool of linked worktrees ("slots") per repo so several
agent sessions can work at once without sharing a checkout or filling the disk.
A session claims a slot, works there and releases it. Warm slots keep their
build output so the next session builds incrementally; burst slots, created only
when every warm slot is busy, are deleted on release. Works with git and
Sapling (`sl worktree`), including EdenFS checkouts.

It does nothing until a machine has `~/.config/wt/config`, which stays local
(never in this repo):

```bash
WT_IDLE_HOURS=72                      # release a claim after this long idle
WT_ROOT=~/.local/share/wt/worktrees   # where slots live (this is the default)
wt_repo ~/Code/app warm=3 max=8 base=origin/main
```

`wt help` lists the options and the hook functions the config can define for
per-repo setup (installing dependencies in a new slot, extra cleanup). The
Claude Code hook (`claude/wt-hook.sh`) tells each session how to claim a slot,
keeps its claim alive while it's active, and runs `wt gc` at most once a day.
`wt status` shows every slot.

## Manual Setup Steps

1. Download [Dank Mono](https://app.gumroad.com/d/3e20027692193b28190488bbd8cf0f1f)
   (paid, so it can't live in this public repo)
   - Open each of the `*.otf` files
2. Set up Raycast: Settings → Keyboard → Hyper Key → Caps Lock, with
   Include Shift on (Raycast window management uses Hyper + Arrow). Raycast
   settings only sync between Macs with Raycast Pro.
3. Set up uBlock Origin Lite and Stylebot in Chrome as described in
   [browser/README.md](browser/README.md).
4. If setup printed "Couldn't enable Control+scroll zoom", turn on System
   Settings → Accessibility → Zoom → "Use scroll gesture with modifier keys to
   zoom" with Control as the modifier.
5. Optional: to sign commits with an SSH key kept in 1Password, so GitHub
   shows them as Verified, turn on 1Password → Settings → Developer → "Use the
   SSH agent" and add an SSH key item (New Item → SSH Key → Add Private Key →
   Generate a New Key). Then run `bash ~/dotfiles/setup-git-signing.sh` and
   follow the GitHub step it prints. It changes only that Mac's own
   `~/.gitconfig`, so forks and other people's Macs never sign with your key.
   Each commit then waits for Touch ID the first time after 1Password unlocks.
   `--off` turns it off again.
