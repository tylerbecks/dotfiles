#!/usr/bin/env bash

# Checks that this machine matches the repo, without changing anything: every
# config file in lib/config-files.sh, Claude Code's settings, skills and
# agents, the zsh plugins, the CLI tools the config uses, and the Brewfile on
# Macs. ✗ lines are broken setup and make it exit 1; ⚠ lines are worth a look
# but don't fail it. fresh.sh and linux.sh run it at the end, and CI runs it
# after linux.sh.
#
# Usage: bash ~/dotfiles/doctor.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config-files.sh"
source "${SCRIPT_DIR}/lib/zsh-plugins.sh"

FAILED=0

header "Config Files"
check_config_files || FAILED=1

header "Claude Code"
check_claude_config || FAILED=1

header "Zsh"
check_zsh_plugins || FAILED=1

# Missing tools are warnings: on Linux they come from the box's package
# manager, and the zsh config skips what isn't there.
header "Tools"
# zsh/config/env.zsh puts these on PATH, and linux.sh installs Starship into
# ~/.local/bin, so look where the shell will
PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
TOOLS=(zsh git jq fzf fd eza bat zoxide difft delta btop starship gh)
if [[ "$(uname -s)" == Darwin ]]; then
    TOOLS+=(brew mise)
fi
MISSING=()
for tool in "${TOOLS[@]}"; do
    command -v "$tool" &> /dev/null || MISSING+=("$tool")
done
if [[ ${#MISSING[@]} -eq 0 ]]; then
    success "All ${#TOOLS[@]} tools installed"
else
    warning "Not installed: ${MISSING[*]}"
    if [[ "$(uname -s)" == Linux ]]; then
        list_item "Install them with the box's package manager (Debian and Ubuntu name fd and bat fdfind and batcat, which the config doesn't pick up)"
    else
        list_item "Install them with: bash ~/dotfiles/brew.sh"
    fi
fi
if ! command -v bun &> /dev/null; then
    warning "bun not installed: the babysit skill's PR watcher needs it (without it, the skill polls with gh)"
fi

if [[ "$(uname -s)" == Darwin ]] && command -v brew &> /dev/null; then
    header "Homebrew"
    if HOMEBREW_DOTFILES_PROFILE="$DOTFILES_PROFILE" brew bundle check --file="${SCRIPT_DIR}/Brewfile" &> /dev/null; then
        success "Everything in the Brewfile is installed"
    else
        warning "Some Brewfile entries are missing (run: bash ~/dotfiles/brew.sh)"
    fi
fi

# A linked file is the repo's file, so an app or installer that edits its own
# config (VS Code settings, say) changes this repo. Commit what's worth
# keeping and revert the rest.
header "Repo"
CHANGES="$(git -C "$SCRIPT_DIR" status --porcelain 2> /dev/null)"
if [[ -z "$CHANGES" ]]; then
    success "No uncommitted changes in ~/dotfiles"
else
    warning "Uncommitted changes in ~/dotfiles (an app may have edited a linked file):"
    sed 's/^/      /' <<< "$CHANGES"
fi

echo ""
if [[ "$FAILED" -eq 0 ]]; then
    summary "This machine matches the repo"
else
    echo -e "${RED}✗${NC} ${BOLD}Some setup is missing or wrong (see ✗ above).${NC} Re-run fresh.sh, refresh.sh or linux.sh to fix it.\n"
    exit 1
fi
