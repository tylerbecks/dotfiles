#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/profile.sh"
source "${SCRIPT_DIR}/lib/claude-settings.sh"

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

# Symlink zsh configuration
step "Symlinking .zshrc..."
rm -rf "$HOME/.zshrc"
ln -sf "${DOTFILES}/zsh/.zshrc" "${HOME}/.zshrc"
success "Shell config linked"

# ~/.gitconfig stays a real per-machine file (work laptops ship one with corp
# settings) that includes the shared config from this repo.
step "Configuring git..."
[ -L "${HOME}/.gitconfig" ] && rm "${HOME}/.gitconfig"
if ! git config --global --get-all include.path | grep -qxF "${DOTFILES}/.gitconfig"; then
    git config --global --add include.path "${DOTFILES}/.gitconfig"
fi
if is_personal && ! git config --global user.email &> /dev/null; then
    git config --global user.email "tylerdbecks@gmail.com"
fi
# This repo is public and personal, so it always commits with the personal
# email, even on machines whose global email is a work address.
git -C "$DOTFILES" config user.email "tylerdbecks@gmail.com"
mkdir -p "${HOME}/.config/git"
ln -sf "${DOTFILES}/config/git/ignore" "${HOME}/.config/git/ignore"
ln -sf "${DOTFILES}/.better-commits.json" "${HOME}/.better-commits.json"
success "Git configured"

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

# Claude config. ~/.claude/CLAUDE.md stays a real per-machine file that imports
# the shared one, so tools that append to it (rtk, work tooling) don't write
# into this repo.
step "Configuring Claude Code..."
CLAUDE_IMPORT="@~/dotfiles/claude/CLAUDE.md"
[ -L "${HOME}/.claude/CLAUDE.md" ] && rm "${HOME}/.claude/CLAUDE.md"
if ! grep -qxF "$CLAUDE_IMPORT" "${HOME}/.claude/CLAUDE.md" 2> /dev/null; then
    echo "$CLAUDE_IMPORT" >> "${HOME}/.claude/CLAUDE.md"
fi
# settings.json is per-machine too, so merge in only the status line and the
# worktree-slot hook (no-op without ~/.config/wt/config; see bin/wt)
merge_claude_settings
success "Claude Code configured"

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

# Editor config: VS Code and Cursor share vscode/, linked into whichever
# editors are installed. Work laptops use a managed VS Code build whose
# settings carry corp defaults (proxy etc.), so VS Code is left alone there.
link_editor_config() {
    local name="$1" user_dir="$2"
    step "Configuring ${name}..."
    mkdir -p "$user_dir"
    ln -sf "${DOTFILES}/vscode/settings.json" "${user_dir}/settings.json"
    ln -sf "${DOTFILES}/vscode/keybindings.json" "${user_dir}/keybindings.json"
    if [ -d "${DOTFILES}/vscode/snippets" ] && [ "$(ls -A "${DOTFILES}/vscode/snippets")" ]; then
        ln -sfn "${DOTFILES}/vscode/snippets" "${user_dir}/snippets"
    fi
    success "${name} configured"
}
if is_personal && [ -d "/Applications/Visual Studio Code.app" ]; then
    link_editor_config "VS Code" "${HOME}/Library/Application Support/Code/User"
fi
if [ -d "/Applications/Cursor.app" ]; then
    link_editor_config "Cursor" "${HOME}/Library/Application Support/Cursor/User"
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
    mkdir -p -m 700 "${HOME}/.ssh"
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

echo ""
warning "Manual steps required:"
list_item "Some changes require a logout/restart to take effect"
list_item "Use WezTerm instead of Terminal from now on"
list_item "Enable Location Services for System Services so Night Shift's sunset schedule works"
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
