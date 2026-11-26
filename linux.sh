#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/profile.sh"
source "${SCRIPT_DIR}/lib/zsh-plugins.sh"
source "${SCRIPT_DIR}/lib/config-files.sh"

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

# Clone instead of running the oh-my-zsh installer, which replaces ~/.zshrc.
# Check for oh-my-zsh.sh, not the directory: install_zsh_plugins creates
# ~/.oh-my-zsh/custom even when this clone fails, which would otherwise look
# installed on the next run. Plugins already in custom/ are carried over.
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    step "Installing oh-my-zsh..."
    OMZ_TMP="$(mktemp -d)"
    if git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_TMP/ohmyzsh" &> /dev/null &&
        { [ ! -d "$HOME/.oh-my-zsh/custom" ] || cp -R "$HOME/.oh-my-zsh/custom/." "$OMZ_TMP/ohmyzsh/custom/"; } &&
        rm -rf "$HOME/.oh-my-zsh" && mv "$OMZ_TMP/ohmyzsh" "$HOME/.oh-my-zsh"; then
        success "oh-my-zsh installed"
    else
        warning "Failed to clone oh-my-zsh (re-run with network access)"
    fi
    rm -rf "$OMZ_TMP"
else
    success "oh-my-zsh already installed"
fi

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
# Config Files
###############################################################################

header "Config Files"

# The same CONFIG_FILES list as fresh.sh (lib/config-files.sh). The box keeps
# its own ~/.zshrc and ~/.gitconfig with their site settings: ~/.zshrc sources
# the shared config last, and ~/.gitconfig includes the shared config, then
# the Linux overrides in config/git/linux, which must come after it to win.
setup_shared_config

###############################################################################
# Summary
###############################################################################

summary "Linux setup complete!"

# Tools the config expects, and anything the steps above missed
header "Health Check"
bash "${SCRIPT_DIR}/doctor.sh"

info "Next steps:"
list_item "Open a new terminal (or run: exec zsh) to load the config"
echo ""
