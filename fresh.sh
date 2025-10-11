#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

DOTFILES=$HOME/dotfiles

###############################################################################
# macOS Fresh Setup
###############################################################################

echo -e "${BOLD}${CYAN}"
cat << "EOF"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃   macOS Fresh Setup         ┃
┃   Setting up your Mac...    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
EOF
echo -e "${NC}"

###############################################################################
# Homebrew & System Tools
###############################################################################

header "Homebrew & System Tools"
step "Running brew.sh..."
if source "${DOTFILES}/brew.sh"; then
    success "Homebrew setup complete"
else
    error "brew.sh failed"
    exit 1
fi

###############################################################################
# Development Environment
###############################################################################

header "Development Environment"

step "Activating mise..."
eval "$(mise activate bash)"

step "Running setup-mise.sh..."
if source "${DOTFILES}/setup-mise.sh"; then
    success "Development environment ready"
else
    error "setup-mise.sh failed"
    exit 1
fi

###############################################################################
# Dock Configuration
###############################################################################

header "Dock Configuration"

step "Clearing default Dock icons..."
if defaults write com.apple.dock persistent-apps -array; then
    success "Dock cleared"
else
    warning "Failed to clear Dock (non-critical)"
fi

###############################################################################
# Shell Configuration
###############################################################################

header "Shell Configuration"

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    step "Installing oh-my-zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended &> /dev/null; then
        success "oh-my-zsh installed"
    else
        error "Failed to install oh-my-zsh"
        exit 1
    fi
else
    success "oh-my-zsh already installed"
fi

# Symlink zsh configuration
step "Symlinking .zshrc..."
rm -rf "$HOME/.zshrc"
ln -sf "${DOTFILES}/zsh/.zshrc" "${HOME}/.zshrc"
success "Shell config linked"

# Symlink git configuration
step "Symlinking .gitconfig..."
ln -sf "${DOTFILES}/.gitconfig" "${HOME}/.gitconfig"
success "Git config linked"

###############################################################################
# Application Configuration
###############################################################################

header "Application Configuration"

# Create config directories
step "Creating config directories..."
mkdir -p "${HOME}/.config"
mkdir -p "${HOME}/.config/btop/themes"
mkdir -p "${HOME}/.config/bat/themes"
mkdir -p "${HOME}/.config/wezterm"
mkdir -p "${HOME}/.claude"
success "Directories created"

# Starship config
step "Configuring Starship prompt..."
cp "${DOTFILES}/starship/starship.toml" "${HOME}/.config/starship.toml"
success "Starship configured"

# btop config
step "Configuring btop..."
cp "${DOTFILES}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
cp "${DOTFILES}/btop/night-owl.theme" "${HOME}/.config/btop/themes/night-owl.theme"
success "btop configured"

# bat config and theme
step "Configuring bat..."
ln -sf "${DOTFILES}/config/bat/config" "${HOME}/.config/bat/config"
if [ ! -d "${HOME}/.config/bat/themes/night-owlish" ]; then
    git clone https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish" &> /dev/null
fi
bat cache --build &> /dev/null
success "bat configured"

# WezTerm config
step "Configuring WezTerm..."
ln -sf "${DOTFILES}/wezterm/appearance.lua" "${HOME}/.config/wezterm/appearance.lua"
ln -sf "${DOTFILES}/wezterm/wezterm.lua" "${HOME}/.config/wezterm/wezterm.lua"
success "WezTerm configured"

# Claude config
step "Configuring Claude Code..."
ln -sf "${DOTFILES}/.claude/CLAUDE.md" "${HOME}/.claude/CLAUDE.md"
success "Claude Code configured"

###############################################################################
# GitHub CLI
###############################################################################

header "GitHub CLI"

step "Authenticating with GitHub..."
info "Please complete the authentication flow:"
gh auth login

step "Installing GitHub Copilot CLI..."
if gh extension install github/gh-copilot &> /dev/null; then
    success "GitHub Copilot CLI installed"
else
    warning "GitHub Copilot CLI installation failed (may already be installed)"
fi

###############################################################################
# Zsh Plugins
###############################################################################

header "Zsh Plugins"

step "Installing fzf-tab..."
git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab" &> /dev/null || true

step "Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" &> /dev/null || true

step "Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" &> /dev/null || true

step "Installing fzf-git.sh..."
git clone https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh" &> /dev/null || true

step "Installing zsh-autopair..."
git clone https://github.com/hlissner/zsh-autopair "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autopair" &> /dev/null || true

step "Installing you-should-use..."
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use" &> /dev/null || true

success "Zsh plugins installed"

###############################################################################
# macOS Preferences
###############################################################################

header "macOS Preferences"

step "Applying macOS system preferences..."
info "This will modify system settings and restart some apps"
if source "${DOTFILES}/.macos"; then
    success "macOS preferences applied"
else
    warning "Some macOS preferences may not have applied correctly"
fi

###############################################################################
# Summary
###############################################################################

summary "Fresh setup complete!"

echo ""
warning "Manual steps required:"
list_item "Grant Terminal Full Disk Access in System Settings > Privacy & Security"
list_item "Some changes require a logout/restart to take effect"
list_item "Open WezTerm and set it as your default terminal"

echo ""
info "Next steps:"
list_item "Restart your Mac to apply all changes"
list_item "Sign in to applications (1Password, Dropbox, etc.)"
list_item "Configure any app-specific preferences"

echo ""
