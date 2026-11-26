#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/profile.sh"
source "${SCRIPT_DIR}/lib/config-files.sh"

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

info "Setting up a ${BOLD}${DOTFILES_PROFILE}${NC} machine (override with --work or --personal)"

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
# Unused Apps
###############################################################################

header "Unused Apps"

# Apple's preinstalled apps I don't use. Removing them also stops refresh.sh's
# `mas upgrade` from downloading their updates; all are free in the App Store.
for unused in "/Applications/GarageBand.app" "/Library/Application Support/GarageBand" \
    "/Library/Audio/Apple Loops" "/Applications/iMovie.app" "/Applications/Keynote.app" \
    "/Applications/Numbers.app" "/Applications/Pages.app"; do
    if [ -e "$unused" ]; then
        step "Removing ${unused}..."
        sudo rm -rf "$unused"
    fi
done
success "Unused apps removed"

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

###############################################################################
# Config Files
###############################################################################

header "Config Files"

# zsh, git, bat, btop, WezTerm, mise, VS Code/Cursor and Claude Code, from the
# CONFIG_FILES list in lib/config-files.sh (refresh.sh re-applies it).
# ~/.gitconfig and ~/.claude/CLAUDE.md stay real per-machine files (work
# laptops ship them with corp settings) that include the shared ones.
setup_shared_config

###############################################################################
# App Helpers
###############################################################################

header "App Helpers"

# rtk (installed from the Brewfile) compresses command output before it
# reaches Claude, via a hook it adds to ~/.claude/settings.json. init asks
# about telemetry (default no).
if is_personal; then
    step "Setting up rtk..."
    if command -v rtk &> /dev/null && rtk init --global; then
        success "rtk installed (restart Claude Code to pick up the hook)"
    else
        warning "rtk setup failed (run rtk init --global manually)"
    fi
fi

# Things Helper enables Quick Entry with Autofill. It only has to be launched
# once, and its download URL is versioned, so read it from the help page.
if [ -d "/Applications/Things3.app" ]; then
    step "Installing Things Helper..."
    THINGS_HELPER_DIR=$(mktemp -d)
    THINGS_HELPER_URL=$(curl -fsSL https://culturedcode.com/things/mac/help/things-sandboxing-helper-things3/ \
        | grep -oE 'https://[^"]*ThingsHelper\.zip' | head -1)
    if [ -n "$THINGS_HELPER_URL" ] \
        && curl -fsSL "$THINGS_HELPER_URL" -o "${THINGS_HELPER_DIR}/ThingsHelper.zip" \
        && unzip -q "${THINGS_HELPER_DIR}/ThingsHelper.zip" -d "$THINGS_HELPER_DIR" \
        && open "${THINGS_HELPER_DIR}"/*.app; then
        success "Things Helper launched"
    else
        warning "Things Helper install failed; get it from culturedcode.com/things/mac/help/things-sandboxing-helper-things3"
    fi
fi

###############################################################################
# GitHub CLI
###############################################################################

header "GitHub CLI"

if is_personal; then
    step "Authenticating with GitHub..."
    info "Please complete the authentication flow:"
    gh auth login
else
    # Work laptops reach personal GitHub with an SSH key that can only push and
    # pull, instead of an account-wide gh token. Match (not a Host block) keeps
    # it from clashing with the work-managed GitHub org access.
    step "Setting up personal GitHub SSH access..."
    GITHUB_KEY="${HOME}/.ssh/github_personal"
    mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
    [ -f "$GITHUB_KEY" ] || ssh-keygen -q -t ed25519 -N "" -C "work laptop" -f "$GITHUB_KEY"
    if ! grep -qF "IdentityFile ~/.ssh/github_personal" "${HOME}/.ssh/config" 2> /dev/null; then
        (umask 077 && cat >> "${HOME}/.ssh/config" << 'EOF'

# Personal GitHub (non-work repos)
Match host "github.com" user git
  IdentityFile ~/.ssh/github_personal
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
EOF
        )
    fi

    # Pin GitHub's published host key so the first connection doesn't prompt
    GITHUB_HOST_KEY="github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    grep -qxF "$GITHUB_HOST_KEY" "${HOME}/.ssh/known_hosts" 2> /dev/null \
        || echo "$GITHUB_HOST_KEY" >> "${HOME}/.ssh/known_hosts"

    github_ssh_works() {
        ssh -T -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1 | grep -q "successfully authenticated"
    }
    if ! github_ssh_works; then
        pbcopy < "${GITHUB_KEY}.pub"
        info "Public key copied to the clipboard. Paste it into the GitHub page that just opened."
        open "https://github.com/settings/ssh/new"
        read -r -p "  Press Enter once the key is added on GitHub..."
    fi
    if github_ssh_works; then
        # New machines clone this public repo over HTTPS; pushing needs SSH
        git -C "$DOTFILES" remote set-url origin git@github.com:tylerbecks/dotfiles.git
        success "Personal GitHub SSH access works"
    else
        warning "GitHub SSH test failed; add ${GITHUB_KEY}.pub at github.com/settings/keys and re-run"
    fi
fi

###############################################################################
# Zsh Plugins
###############################################################################

header "Zsh Plugins"

source "${DOTFILES}/lib/zsh-plugins.sh"
install_zsh_plugins

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
# Dock Configuration
###############################################################################

header "Dock Configuration"

# Runs last and restarts the Dock right away: a running Dock saves its own app
# list whenever apps open, which would overwrite this.
step "Setting Dock apps..."
defaults write com.apple.dock persistent-apps -array
for app in "Things3" "Spotify" "1Password" "Slack" "zoom.us" "WezTerm"; do
    app_path="/Applications/${app}.app"
    if [ ! -d "$app_path" ]; then
        warning "${app} is not installed, leaving it out of the Dock"
        continue
    fi
    defaults write com.apple.dock persistent-apps -array-add \
        "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>${app_path}</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
done
killall Dock
success "Dock configured"

###############################################################################
# Summary
###############################################################################

summary "Fresh setup complete!"

header "Health Check"
bash "${DOTFILES}/doctor.sh"

echo ""
warning "Manual steps required:"
list_item "Some changes require a logout/restart to take effect"
list_item "Use WezTerm instead of Terminal from now on"
list_item "Enable Location Services for System Services so Night Shift's sunset schedule works"
list_item "Set up uBlock Origin Lite and Stylebot in Chrome (see browser/README.md)"
if is_work; then
    list_item "In VS Code, run \"Shell Command: Install 'code' command in PATH\" (git and \$EDITOR use it)."
    list_item "  If it installs under another name, link it: ln -s \"\$(command -v <name>)\" ~/.local/bin/code"
fi

echo ""
info "Next steps:"
list_item "Restart your Mac to apply all changes"
list_item "Sign in to applications (1Password, Raycast, etc.)"
list_item "Configure any app-specific preferences"

echo ""
