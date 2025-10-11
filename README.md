# dotfiles

A collection of configuration files for setting up a new macOS machine.

## Installation

Run the setup script to install all dependencies and configurations:

```bash
source fresh.sh
```

## Directory Structure

- `brew.sh`: Homebrew package installation
- `fresh.sh`: Main installation script
- `refresh.sh`: Script to update packages
- `setup.zsh`: Additional setup after core installation
- `.macos`: macOS system preferences
- `zsh/`: Modular ZSH configuration
  - `aliases/`: Command aliases organized by category
  - `config/`: ZSH configuration modules (history, path, plugins, etc.)
  - `functions/`: Custom ZSH functions
  - `plugins/`: Plugin configurations
  - `themes/`: Theme configurations
- `wezterm/`: Terminal configuration
- `config/`: Various application configurations
- `.claude/`: Claude AI configuration settings
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

1. Install [Logi Options+](https://www.logitech.com/en-us/software/logi-options-plus.html#customization-app-download)
2. Install [Things Helper](https://culturedcode.com/things/mac/help/things-sandboxing-helper-things3/)
3. Download [Dank Mono](https://app.gumroad.com/d/3e20027692193b28190488bbd8cf0f1f)
   - Open each of the `*.otf` files
4. Open and configure Rectangle
