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

### Linux dev boxes

```bash
bash ~/dotfiles/linux.sh
```

This links the zsh, git, bat, btop and Claude config without replacing the
box's own `~/.zshrc`, `~/.bashrc` or `~/.gitconfig` (it appends include lines),
and switches interactive bash terminals to zsh. It needs network access to
clone oh-my-zsh, the zsh plugins and Starship; re-run it if those steps warn.
CLI tools (fzf, fd, eza, bat, zoxide, difftastic, delta, btop) come from the
box's package manager; the script lists any that are missing. For Node, put
[fnm](https://github.com/Schniz/fnm) in `~/.local/bin`; zsh loads it when present.

## Directory Structure

- `Brewfile`: Homebrew packages and apps, split into work and personal
- `brew.sh`: Installs Homebrew and everything in the `Brewfile`
- `fresh.sh`: Main installation script
- `linux.sh`: Config-only setup for Linux dev boxes
- `refresh.sh`: Script to update packages
- `setup-mise.sh`: Language runtimes and global CLIs via mise
- `.macos`: macOS system preferences
- `bin/`: Personal scripts on the `PATH`, including `wt` (see [Worktree slots](#worktree-slots-for-parallel-agents))
- `lib/`: Shared helpers for the setup scripts (logging, work/personal detection, zsh plugins, Claude Code settings merge)
- `zsh/`: Modular ZSH configuration
  - `aliases/`: Command aliases organized by category
  - `config/`: ZSH configuration modules (history, path, plugins, etc.)
  - `functions/`: Custom ZSH functions
- `wezterm/`: Terminal configuration
- `config/`: Various application configurations
- `claude/`: Global Claude Code instructions (imported from `~/.claude/CLAUDE.md`) the status line script and the worktree-slot hook (both merged into `~/.claude/settings.json` by the setup scripts)
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
3. If setup printed "Couldn't enable Control+scroll zoom", turn on System
   Settings → Accessibility → Zoom → "Use scroll gesture with modifier keys to
   zoom" with Control as the modifier.
