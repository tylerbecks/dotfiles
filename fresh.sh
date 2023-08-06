echo "Setting up your Mac..."

DOTFILES=$HOME/dotfiles
source $DOTFILES/brew.sh

# Link iterm settings
rm ~/Library/Preferences/com.googlecode.iterm2.plist
ln -s $DOTFILES/config/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist

# Wipe all (default) app icons from the Dock
# I don't want to do this every time I source .macos settings, only on installing a fresh computer
defaults write com.apple.dock persistent-apps -array

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc

ln -s "${DOTFILES}/.zshrc" "${HOME}/.zshrc"
ln -s "${DOTFILES}/.gitconfig" "${HOME}/.gitconfig"

mkdir -p "${HOME}/.config/bat/themes"
ln -s "${DOTFILES}/config/bat/config" "${HOME}/.config/bat/config"
git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
bat cache --build

# Install github copilot cli
npm install -g @githubnext/github-copilot-cli
github-copilot-cli auth

source $DOTFILES/setup.zsh

# Run this last because it will reload the shell
# Set macOS preferences
source $DOTFILES/.macos