echo "Setting up your Mac..."

source $DOTFILES/brew.sh
source $DOTFILES/fish.sh

# Wipe all (default) app icons from the Dock
# I don't want to do this every time I source .macos settings, only on installing a fresh computer
defaults write com.apple.dock persistent-apps -array

# Set macOS preferences - run this last because it will reload the shell
source $DOTFILES/.macos

if test ! $(which omz); then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -s .zshrc $HOME/.zshrc

rm -rf $HOME/.p10k.zsh
ln -s .p10k.zsh $HOME/.p10k.zsh

mkdir -p "${HOME}/.config/bat/themes"
ln -s "${HOME}/dotfiles/.config/bat/config" "${HOME}/.config/bat/config"
git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish"
bat cache --build