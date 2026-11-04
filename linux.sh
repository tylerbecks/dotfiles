#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/profile.sh"
source "${SCRIPT_DIR}/lib/zsh-plugins.sh"

DOTFILES=$HOME/dotfiles

###############################################################################
# Linux Setup
###############################################################################

# The Linux counterpart to fresh.sh, for remote dev boxes. It only links config:
# CLI tools come from the box's own package manager (missing ones are listed at
# the end), and the box's login files keep their site settings, with include
# lines added. Safe to re-run; steps that need the network warn and continue.

echo -e "${BOLD}${CYAN}"
cat << "EOF"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃   Linux Setup               ┃
┃   Linking your dotfiles...  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
EOF
echo -e "${NC}"

info "Setting up a ${BOLD}${DOTFILES_PROFILE}${NC} machine (override with --work or --personal)"

###############################################################################
# Shell Configuration
###############################################################################

header "Shell Configuration"

# Clone instead of running the oh-my-zsh installer, which replaces ~/.zshrc
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    step "Installing oh-my-zsh..."
    if git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" &> /dev/null; then
        success "oh-my-zsh installed"
    else
        warning "Failed to clone oh-my-zsh (re-run with network access)"
    fi
else
    success "oh-my-zsh already installed"
fi

# ~/.zshrc stays the box's own file and sources the shared config last, so the
# site settings it ships with keep loading
step "Linking .zshrc..."
ZSHRC_SOURCE='source "$HOME/dotfiles/zsh/.zshrc"'
if ! grep -qxF "$ZSHRC_SOURCE" "$HOME/.zshrc" 2> /dev/null; then
    printf '\n# Shared config from ~/dotfiles\n%s\n' "$ZSHRC_SOURCE" >> "$HOME/.zshrc"
fi
success "Shell config linked"

# Dev boxes often manage the login shell centrally, so hop from interactive
# bash into zsh instead. Skipped for non-terminal shells and for VS Code
# reading the environment or running a `bash -ic` command, so scripts and
# remote tooling still get bash.
if [ "$(basename "${SHELL:-}")" != zsh ]; then
    step "Starting zsh from interactive bash..."
    if ! grep -qF "exec zsh" "$HOME/.bashrc" 2> /dev/null; then
        cat >> "$HOME/.bashrc" << 'EOF'

# Switch to zsh in interactive terminals (from ~/dotfiles/linux.sh)
if [[ $- == *i* && -t 1 && -z "${BASH_EXECUTION_STRING:-}" && -z "${VSCODE_RESOLVING_ENVIRONMENT:-}" ]] \
    && command -v zsh &> /dev/null; then
    exec zsh
fi
EOF
    fi
    success "Interactive bash switches to zsh"
fi

###############################################################################
# Zsh Plugins
###############################################################################

header "Zsh Plugins"

install_zsh_plugins

###############################################################################
# Prompt
###############################################################################

header "Prompt"

if command -v starship &> /dev/null && starship init zsh &> /dev/null; then
    success "Starship already installed"
else
    step "Installing Starship into ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"
    # Download first: piped into sh, a failed download would still "succeed"
    if STARSHIP_INSTALLER=$(curl -fsSL https://starship.rs/install.sh 2> /dev/null) \
        && sh -c "$STARSHIP_INSTALLER" starship-install --yes --bin-dir "$HOME/.local/bin" &> /dev/null; then
        success "Starship installed"
    else
        warning "Failed to install Starship (re-run with network access)"
    fi
fi

###############################################################################
# Git
###############################################################################

header "Git"

# Same layering as fresh.sh: the box's ~/.gitconfig includes the shared config,
# then the Linux overrides, which must come after it to win
step "Configuring git..."
[ -L "${HOME}/.gitconfig" ] && rm "${HOME}/.gitconfig"
for include in "${DOTFILES}/.gitconfig" "${DOTFILES}/config/git/linux"; do
    if ! git config --global --get-all include.path | grep -qxF "$include"; then
        git config --global --add include.path "$include"
    fi
done
if is_personal && ! git config --global user.email &> /dev/null; then
    git config --global user.email "tylerdbecks@gmail.com"
fi
git -C "$DOTFILES" config user.email "tylerdbecks@gmail.com"
mkdir -p "${HOME}/.config/git"
ln -sf "${DOTFILES}/config/git/ignore" "${HOME}/.config/git/ignore"
ln -sf "${DOTFILES}/.better-commits.json" "${HOME}/.better-commits.json"
success "Git configured"
if ! git config --global user.email &> /dev/null; then
    warning "No global git email; set one with: git config --global user.email <email>"
fi

###############################################################################
# Application Configuration
###############################################################################

header "Application Configuration"

step "Configuring btop..."
mkdir -p "${HOME}/.config/btop/themes"
cp "${DOTFILES}/btop/btop.conf" "${HOME}/.config/btop/btop.conf"
cp "${DOTFILES}/btop/night-owl.theme" "${HOME}/.config/btop/themes/night-owl.theme"
success "btop configured"

step "Configuring bat..."
mkdir -p "${HOME}/.config/bat/themes"
ln -sf "${DOTFILES}/config/bat/config" "${HOME}/.config/bat/config"
if [ ! -d "${HOME}/.config/bat/themes/night-owlish" ]; then
    git clone --depth 1 https://github.com/batpigandme/night-owlish "${HOME}/.config/bat/themes/night-owlish" &> /dev/null
fi
if command -v bat &> /dev/null; then
    bat cache --build &> /dev/null
fi
success "bat configured"

# Same import as fresh.sh: ~/.claude/CLAUDE.md stays a real per-machine file
step "Configuring Claude Code..."
mkdir -p "${HOME}/.claude"
CLAUDE_IMPORT="@~/dotfiles/claude/CLAUDE.md"
[ -L "${HOME}/.claude/CLAUDE.md" ] && rm "${HOME}/.claude/CLAUDE.md"
if ! grep -qxF "$CLAUDE_IMPORT" "${HOME}/.claude/CLAUDE.md" 2> /dev/null; then
    echo "$CLAUDE_IMPORT" >> "${HOME}/.claude/CLAUDE.md"
fi
success "Claude Code configured"

###############################################################################
# Summary
###############################################################################

summary "Linux setup complete!"

# Tools the zsh and git config expect; delta is optional (git falls back to less)
MISSING=()
for tool in zsh git fzf fd eza bat zoxide difft delta btop starship; do
    command -v "$tool" &> /dev/null || MISSING+=("$tool")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    warning "Install these with the box's package manager: ${MISSING[*]}"
fi

info "Next steps:"
list_item "Open a new terminal (or run: exec zsh) to load the config"
echo ""
