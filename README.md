# dotfiles

A collection of configuration files for setting up a new macOS machine.

## Installation

Run the setup script to install all dependencies and configurations:

```bash
bash ~/dotfiles/fresh.sh
```

The script detects work laptops and skips personal-only apps and settings
there. Override the detection with `--work` or `--personal`.

## Directory Structure

- `Brewfile`: Homebrew packages and apps, split into work and personal
- `brew.sh`: Installs Homebrew and everything in the `Brewfile`
- `fresh.sh`: Main installation script
- `refresh.sh`: Script to update packages
- `setup-mise.sh`: Language runtimes and global CLIs via mise
- `.macos`: macOS system preferences
- `lib/`: Shared helpers for the setup scripts (logging, work/personal detection)
- `zsh/`: Modular ZSH configuration
  - `aliases/`: Command aliases organized by category
  - `config/`: ZSH configuration modules (history, path, plugins, etc.)
  - `functions/`: Custom ZSH functions
- `wezterm/`: Terminal configuration
- `config/`: Various application configurations
- `claude/`: Global Claude Code instructions (imported from `~/.claude/CLAUDE.md`)
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
