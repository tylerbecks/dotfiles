#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/profile.sh"

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

step "Installing GNU grep..."
brew install grep &> /dev/null && ((FORMULAE_COUNT++))

success "Core utilities installed"

###############################################################################
# Development Tools
###############################################################################

header "Development Tools"

step "Installing mise..."
brew install mise &> /dev/null && ((FORMULAE_COUNT++))

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

step "Installing Night Shift CLI..."
brew install smudge/smudge/nightlight &> /dev/null && ((FORMULAE_COUNT++))

success "CLI tools installed"

###############################################################################
# Shell Enhancements
###############################################################################

header "Shell Enhancements"

# zsh plugins are cloned into oh-my-zsh by fresh.sh, and fzf's key bindings
# are loaded by `fzf --zsh` in zsh/config/plugins.zsh.
step "Installing Starship prompt..."
brew install starship &> /dev/null && ((FORMULAE_COUNT++))

success "Shell enhancements installed"

###############################################################################
# Applications
###############################################################################

header "Applications"

# Installs a cask unless its app is already in /Applications. Work laptops
# ship some of these preinstalled, and `brew install` fails on top of them.
install_cask() {
    local cask="$1" app="$2"
    if [ -d "/Applications/${app}.app" ]; then
        success "${app} already installed"
    elif brew install --cask "$cask" &> /dev/null; then
        ((CASK_COUNT++))
    else
        warning "Failed to install ${cask}"
    fi
}

step "Installing productivity apps..."
install_cask cleanshot "CleanShot X"
install_cask raycast "Raycast"
install_cask logi-options+ "logioptionsplus"

step "Installing browser..."
install_cask thebrowsercompany-dia "Dia"

step "Installing terminal..."
install_cask wezterm "WezTerm"

step "Installing 1Password..."
install_cask 1password "1Password"
brew install 1password-cli &> /dev/null && ((FORMULAE_COUNT++))

step "Installing communication apps..."
install_cask slack "Slack"
install_cask zoom "zoom.us"

step "Installing entertainment..."
install_cask spotify "Spotify"

if is_personal; then
    step "Installing editor..."
    install_cask visual-studio-code "Visual Studio Code"

    step "Installing Claude..."
    install_cask claude "Claude"
    brew install --cask claude-code &> /dev/null && ((CASK_COUNT++))

    step "Installing personal apps..."
    install_cask dropbox "Dropbox"
    install_cask whatsapp "WhatsApp"
fi

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
