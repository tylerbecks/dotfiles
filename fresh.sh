echo "Setting up your Mac..."

source $DOTFILES/brew.sh

# Wipe all (default) app icons from the Dock
# I don't want to do this every time I source .macos settings, only on installing a fresh computer
defaults write com.apple.dock persistent-apps -array

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc

ln -s "${HOME}/dotfiles/.zshrc" "${HOME}/.zshrc"

mkdir -p "${HOME}/.config/bat/themes"
ln -s "${HOME}/.config/bat/config" "${DOTFILES}/.config/bat/config"
git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
bat cache --build

# Install github copilot cli
npm install -g @githubnext/github-copilot-cli
github-copilot-cli auth

# Run this last because it will reload the shell
# Set macOS preferences
source $DOTFILES/.macos