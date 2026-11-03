#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/profile.sh"

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

# Accept Xcode license if not already accepted. xcodebuild only exists with the
# full Xcode app; the Command Line Tools alone need no license.
if ! xcodebuild -version &> /dev/null; then
    skipped "Xcode license (only Command Line Tools installed)"
elif ! sudo xcodebuild -license check &> /dev/null; then
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

###############################################################################
# Packages and Apps
###############################################################################

header "Packages and Apps"

# Everything lives in the Brewfile (work/personal split included). Output is
# left visible: casks can prompt for a password and mas needs an App Store
# sign-in.
step "Installing from Brewfile..."
if HOMEBREW_DOTFILES_PROFILE="$DOTFILES_PROFILE" brew bundle --file="${SCRIPT_DIR}/Brewfile"; then
    success "Brewfile installed"
else
    warning "Some Brewfile entries failed (see above); fix them and re-run brew.sh"
fi

# GNU sha256sum under its usual name
ln -sf "$(brew --prefix)/bin/gsha256sum" "$(brew --prefix)/bin/sha256sum" 2> /dev/null

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

summary "Homebrew setup complete!"

info "Note: npm packages will be installed by setup-mise.sh"
