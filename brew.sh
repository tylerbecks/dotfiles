#!/usr/bin/env bash

# Install Xcode Command Line Tools if not already installed
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode Command Line Tools installation and re-run this script."
    exit 1
fi

# Accept Xcode license if not already accepted
if ! sudo xcodebuild -license check &> /dev/null; then
    echo "Accepting Xcode license..."
    sudo xcodebuild -license accept
fi

# Check for Homebrew and install if we don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH for this script session
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

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
brew install N
brew install difftastic # A fantastic diff tool
brew install jq
brew install eza # A modern replacement for ls
brew install fzf
yes | $(brew --prefix)/opt/fzf/install # Install fzf key bindings and fuzzy completion
brew install ripgrep # rg is faster than alternatives
brew install zoxide # a smarter cd command, It remembers which directories you use most frequently, so you can "jump" to them in just a few keystrokes.
brew install zsh-autopair
brew install btop # Resource monitor with TUI (better than htop)

# Development
brew install mise # Version manager for multiple languages
brew install pnpm

# Install mackup to backup app preferences
brew install mackup

# Download Apps
brew install --cask cleanshot # Screenshot tool
brew install --cask flux
brew install --cask wezterm # Terminal
brew install --cask 1password
brew install 1password-cli
brew install --cask raycast
brew install --cask dropbox
brew install --cask arc
brew install --cask raindropio
brew install --cask rectangle
brew install --cask slack
brew install --cask spotify
brew install --cask whatsapp
brew install --cask zoom

brew install zsh-syntax-highlighting
brew install delta
brew install starship # Cross-shell prompt

# Note: npm packages are now installed in setup-mise.sh after Node.js is installed

# Fonts
brew install font-meslo-lg-nerd-font

# Install Mac App Store apps
brew install mas
mas install 904280696 # Things

brew cleanup
