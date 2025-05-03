echo "Setting up your Mac..."

DOTFILES=$HOME/dotfiles
source $DOTFILES/brew.sh

# Wipe all (default) app icons from the Dock
# I don't want to do this every time I source .macos settings, only on installing a fresh computer
defaults write com.apple.dock persistent-apps -array

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc

# Symlink the new modular zsh configuration
ln -sf "${DOTFILES}/zsh/.zshrc" "${HOME}/.zshrc"
ln -sf "${DOTFILES}/.gitconfig" "${HOME}/.gitconfig"
ln -sf "${DOTFILES}/.asdfrc" "${HOME}/.asdfrc"
ln -sf "${DOTFILES}/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json

# Create Starship config directory and symlink config
mkdir -p "${HOME}/.config"
# Use copy instead of symlink for Starship config to avoid permission issues
cp "${DOTFILES}/starship/starship.toml" "${HOME}/.config/starship.toml"

mkdir -p "${HOME}/.config/bat/themes"
ln -sf "${DOTFILES}/config/bat/config" "${HOME}/.config/bat/config"
git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
bat cache --build

# Install github copilot cli
gh auth login
gh extension install github/gh-copilot

# Create the WezTerm config directory if it doesn't exist
mkdir -p ~/.config/wezterm

# Symlink the WezTerm config files from the dotfiles
ln -sf ~/dotfiles/wezterm/appearance.lua ~/.config/wezterm/appearance.lua
ln -sf ~/dotfiles/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua

# Create Claude config directory and symlink config file
mkdir -p ~/.claude
ln -sf ~/dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md

source $DOTFILES/setup.zsh

# Run this last because it will reload the shell
# Set macOS preferences
source $DOTFILES/.macos