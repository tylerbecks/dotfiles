#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

# Track package counts
FORMULAE_COUNT=0
CASK_COUNT=0

###############################################################################
# Xcode Setup
###############################################################################

header "Xcode Command Line Tools"

# Install Xcode Command Line Tools if not already installed
if ! xcode-select -p &> /dev/null; then
    step "Installing Xcode Command Line Tools..."
    xcode-select --install
    warning "Please complete the Xcode Command Line Tools installation and re-run this script"
    exit 1
else
    success "Xcode Command Line Tools already installed"
fi

# Accept Xcode license if not already accepted
if ! sudo xcodebuild -license check &> /dev/null; then
    step "Accepting Xcode license..."
    if sudo xcodebuild -license accept 2>/dev/null; then
        success "Xcode license accepted"
    else
        error "Failed to accept Xcode license"
        exit 1
    fi
else
    success "Xcode license already accepted"
fi

###############################################################################
# Homebrew Installation
###############################################################################

header "Homebrew Installation"

# Check if Homebrew is already installed
if command -v brew &> /dev/null; then
    success "Homebrew already installed"
else
    step "Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        success "Homebrew installed"
    else
        error "Failed to install Homebrew"
        exit 1
    fi
fi

# Add Homebrew to PATH for this script session
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

# Make sure we're using the latest Homebrew
step "Updating Homebrew..."
if brew update &> /dev/null; then
    success "Homebrew updated"
else
    warning "Homebrew update had issues (continuing anyway)"
fi

# Upgrade any already-installed formulae
step "Upgrading existing packages..."
if brew upgrade &> /dev/null; then
    success "Existing packages upgraded"
else
    success "No packages to upgrade"
fi

# Save Homebrew's installed location
BREW_PREFIX=$(brew --prefix)

###############################################################################
# Core Utilities
###############################################################################

header "Core Utilities"

step "Installing GNU core utilities..."
brew install coreutils &> /dev/null && ((FORMULAE_COUNT++))
ln -sf "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum" 2>/dev/null

step "Installing GNU sed..."
brew install gnu-sed &> /dev/null && ((FORMULAE_COUNT++))

step "Installing modern Bash..."
brew install bash bash-completion2 &> /dev/null && ((FORMULAE_COUNT+=2))

step "Installing grep and PHP..."
brew install grep php &> /dev/null && ((FORMULAE_COUNT+=2))

success "Core utilities installed"

###############################################################################
# Development Tools
###############################################################################

header "Development Tools"

step "Installing version managers and package managers..."
brew install mise pnpm &> /dev/null && ((FORMULAE_COUNT+=2))

step "Installing Git and GitHub CLI..."
brew install gh &> /dev/null && ((FORMULAE_COUNT++))

step "Installing diff tools..."
brew install difftastic delta &> /dev/null && ((FORMULAE_COUNT+=2))

success "Development tools installed"

###############################################################################
# CLI Tools
###############################################################################

header "CLI Tools"

step "Installing search and navigation tools..."
brew install ack fd ripgrep fzf jq &> /dev/null && ((FORMULAE_COUNT+=5))

step "Installing modern replacements..."
brew install bat eza &> /dev/null && ((FORMULAE_COUNT+=2))

step "Installing system monitoring..."
brew install btop &> /dev/null && ((FORMULAE_COUNT++))

step "Installing backup tool..."
brew install mackup &> /dev/null && ((FORMULAE_COUNT++))

success "CLI tools installed"

###############################################################################
# Shell Enhancements
###############################################################################

header "Shell Enhancements"

step "Installing zsh plugins..."
brew install zsh-syntax-highlighting zsh-autopair &> /dev/null && ((FORMULAE_COUNT+=2))

step "Installing Starship prompt..."
brew install starship &> /dev/null && ((FORMULAE_COUNT++))

step "Configuring fzf key bindings..."
if yes | $(brew --prefix)/opt/fzf/install &> /dev/null; then
    success "Shell enhancements installed"
else
    warning "fzf key bindings may need manual installation"
fi

###############################################################################
# Applications
###############################################################################

header "Applications"

step "Installing productivity apps..."
brew install --cask cleanshot raycast rectangle &> /dev/null && ((CASK_COUNT+=3))

step "Installing browsers and utilities..."
brew install --cask arc flux &> /dev/null && ((CASK_COUNT+=2))

step "Installing terminal..."
brew install --cask wezterm &> /dev/null && ((CASK_COUNT++))

step "Installing 1Password..."
brew install --cask 1password &> /dev/null && ((CASK_COUNT++))
brew install 1password-cli &> /dev/null && ((FORMULAE_COUNT++))

step "Installing cloud storage..."
brew install --cask dropbox raindropio &> /dev/null && ((CASK_COUNT+=2))

step "Installing communication apps..."
brew install --cask slack whatsapp zoom &> /dev/null && ((CASK_COUNT+=3))

step "Installing entertainment..."
brew install --cask spotify &> /dev/null && ((CASK_COUNT++))

success "Applications installed"

###############################################################################
# Fonts
###############################################################################

header "Fonts"

step "Installing Nerd Fonts..."
if brew install font-meslo-lg-nerd-font &> /dev/null; then
    success "Fonts installed"
    ((CASK_COUNT++))
else
    warning "Font installation failed (may need manual install)"
fi

###############################################################################
# Mac App Store
###############################################################################

header "Mac App Store Apps"

step "Installing mas (Mac App Store CLI)..."
brew install mas &> /dev/null && ((FORMULAE_COUNT++))

step "Installing Things..."
if mas install 904280696 &> /dev/null; then
    success "Mac App Store apps installed"
else
    warning "Things installation failed (may need manual install or sign-in)"
fi

###############################################################################
# Cleanup
###############################################################################

header "Cleanup"

step "Removing outdated versions..."
if brew cleanup &> /dev/null; then
    success "Cleanup complete"
else
    warning "Cleanup had issues (non-critical)"
fi

###############################################################################
# Summary
###############################################################################

summary "Homebrew setup complete! Installed ${FORMULAE_COUNT} packages and ${CASK_COUNT} applications"

info "Note: npm packages will be installed by setup-mise.sh"
