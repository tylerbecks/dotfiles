#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/profile.sh"

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
success "Dock configured (applies when .macos restarts the Dock)"

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
success "Claude Code configured"

# rtk compresses command output before it reaches Claude, via a hook it adds
# to ~/.claude/settings.json. init asks about telemetry (default no).
if is_personal; then
    step "Installing rtk..."
    if brew install rtk &> /dev/null && rtk init --global; then
        success "rtk installed (restart Claude Code to pick up the hook)"
    else
        warning "rtk setup failed (run rtk init --global manually)"
    fi
fi

# VS Code config. Work laptops use a managed VS Code build whose settings
# carry corp defaults (proxy etc.), so they are left alone there.
if is_personal; then
    step "Configuring VS Code..."
    VSCODE_USER="${HOME}/Library/Application Support/Code/User"
    mkdir -p "$VSCODE_USER"
    ln -sf "${DOTFILES}/vscode/settings.json" "${VSCODE_USER}/settings.json"
    ln -sf "${DOTFILES}/vscode/keybindings.json" "${VSCODE_USER}/keybindings.json"
    if [ -d "${DOTFILES}/vscode/snippets" ] && [ "$(ls -A "${DOTFILES}/vscode/snippets")" ]; then
        ln -sf "${DOTFILES}/vscode/snippets" "${VSCODE_USER}/snippets"
    fi
    success "VS Code configured"
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

# All plugins live in oh-my-zsh's custom dir and load from the plugins list in
# zsh/.zshrc; refresh.sh keeps them updated. Use $HOME, not ~: tilde does not
# expand inside quotes, which would clone into a literal "~" dir under the cwd.
OMZ_PLUGINS="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$OMZ_PLUGINS"

install_omz_plugin() {
    local name="$1" url="$2"
    step "Installing ${name}..."
    if [ -d "${OMZ_PLUGINS}/${name}" ]; then
        success "${name} already installed"
    elif git clone "$url" "${OMZ_PLUGINS}/${name}" &> /dev/null; then
        success "${name} installed"
    else
        warning "Failed to clone ${name} from ${url}"
    fi
}

install_omz_plugin fzf-tab https://github.com/Aloxaf/fzf-tab
install_omz_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
install_omz_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
install_omz_plugin zsh-autopair https://github.com/hlissner/zsh-autopair
install_omz_plugin you-should-use https://github.com/MichaelAquilina/zsh-you-should-use.git

step "Installing fzf-git.sh..."
git clone https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh" &> /dev/null || true

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
list_item "Enable Location Services for System Services so Night Shift's sunset schedule works"
if is_work; then
    list_item "In VS Code, run \"Shell Command: Install 'code' command in PATH\" (git and \$EDITOR use it)"
fi

echo ""
info "Next steps:"
list_item "Restart your Mac to apply all changes"
list_item "Sign in to applications (1Password, Raycast, etc.)"
list_item "Configure any app-specific preferences"

echo ""
