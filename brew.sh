#!/usr/bin/env bash

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Extend homebrew with taps
brew tap homebrew/cask
brew tap homebrew/cask-fonts

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names

# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Install more recent versions of some macOS tools.
brew install grep
brew install php

# Install useful cli tools.
brew install ack
brew install bat
brew install fd
brew install gh
brew install git
brew install jq
brew install fzf
yes | $(brew --prefix)/opt/fzf/install # Install fzf key bindings and fuzzy completion
brew install ripgrep

# Development
brew install git
brew install node
brew install pnpm
brew install yarn

# Install mackup to backup app preferences
brew install mackup

# Download Apps
brew install 1password
brew install alfred
brew install dash
brew install dropbox
brew install google-chrome
brew install hyperkey
brew install iterm2
brew install obsidian
brew install raindropio
brew install rectangle
brew install slack
brew install spotify
brew install todoist
brew install visual-studio-code
brew install whatsApp
brew install zoom

# Fonts
brew install --cask font-fira-code

# Install Mac App Store apps
brew install mas
mas install 904280696 # Things

brew cleanup