#!/usr/bin/env bash

# Check for Homebrew and install if we don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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

# Install GNU `sed`
brew install gnu-sed

# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Install more recent versions of some macOS tools.
brew install grep
brew install php

brew install ack
brew install bat # A cat(1) clone with syntax highlighting and Git integration.
brew install fd
brew install gh
brew install git
brew install difftastic # A fantastic diff tool
brew install jq
brew install eza # A modern replacement for ls
brew install fzf
yes | $(brew --prefix)/opt/fzf/install # Install fzf key bindings and fuzzy completion
brew install ripgrep # rg is faster than alternatives
brew install thefuck # Magnificent app which corrects your previous console command.
brew install zoxide # a smarter cd command, It remembers which directories you use most frequently, so you can "jump" to them in just a few keystrokes.
brew install zsh-autopair
brew install btop # Resource monitor with TUI (better than htop)

# Development
brew install git
brew install asdf # Version manager for multiple languages
brew install pnpm
brew install yarn

# Install mackup to backup app preferences
brew install mackup

# Download Apps
brew install --cask cleanshot # Screenshot tool
brew install --cask flux
brew install --cask wezterm # Terminal
brew install 1password
brew install 1password-cli
brew install --cask raycast
brew install dropbox
brew install --cask arc
brew install raindropio
brew install rectangle
brew install slack
brew install spotify
brew install visual-studio-code
brew install whatsApp
brew install zoom

brew install zsh-syntax-highlighting
brew install delta
brew install starship # Cross-shell prompt

# Note: npm packages are now installed in setup-asdf.sh after Node.js is installed

# Fonts
brew install font-meslo-lg-nerd-font

# Install Mac App Store apps
brew install mas
mas install 904280696 # Things

brew cleanup
