#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

###############################################################################
# Setup
###############################################################################

START_TIME=$SECONDS
ERRORS=()
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
trap 'echo ""; warning "Interrupted by user"; exit 130' INT TERM

###############################################################################
# Homebrew
###############################################################################

header "Homebrew"

step "Updating Homebrew..."
if brew update 2>"$TMPFILE" >/dev/null; then
    success "Homebrew updated"
else
    error "Failed to update Homebrew"
    [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
    ERRORS+=("brew update")
fi

step "Upgrading packages..."
OUTDATED=$(brew outdated | wc -l | tr -d ' ')
if [ "$OUTDATED" -gt 0 ]; then
    info "Upgrading $OUTDATED package(s)..."
    brew upgrade
    BREW_EXIT=$?
    if [ $BREW_EXIT -eq 0 ]; then
        success "Packages upgraded"
    else
        error "Some packages failed to upgrade"
        ERRORS+=("brew upgrade")
    fi
else
    success "All packages are up to date"
fi

###############################################################################
# Mac App Store
###############################################################################

header "Mac App Store"

if ! command -v mas &>/dev/null; then
    skipped "mas (Mac App Store CLI not installed)"
else
    step "Checking for App Store updates..."
    MAS_OUTDATED=$(mas outdated | wc -l | tr -d ' ')
    if [ "$MAS_OUTDATED" -gt 0 ]; then
        info "Upgrading $MAS_OUTDATED app(s)..."
        if mas upgrade 2>"$TMPFILE"; then
            success "App Store apps upgraded"
        else
            error "Some App Store apps failed to upgrade"
            [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
            ERRORS+=("mas upgrade")
        fi
    else
        success "All App Store apps are up to date"
    fi
fi

###############################################################################
# npm
###############################################################################

header "npm"

if ! command -v npm &>/dev/null; then
    skipped "npm (not installed)"
else
    step "Updating npm itself..."
    NPM_CURRENT=$(npm -v 2>/dev/null)
    if npm install -g npm@latest 2>"$TMPFILE" >/dev/null; then
        NPM_NEW=$(npm -v 2>/dev/null)
        if [ "$NPM_CURRENT" != "$NPM_NEW" ]; then
            success "npm updated: $NPM_CURRENT → $NPM_NEW"
        else
            success "npm already up to date ($NPM_CURRENT)"
        fi
    else
        error "Failed to update npm"
        [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
        ERRORS+=("npm update")
    fi
fi

###############################################################################
# GitHub CLI Extensions
###############################################################################

header "GitHub CLI Extensions"

if ! command -v gh &>/dev/null; then
    skipped "gh (GitHub CLI not installed)"
else
    step "Updating all gh extensions..."
    if gh extension upgrade --all 2>"$TMPFILE" >/dev/null; then
        success "gh extensions updated"
    else
        error "Some gh extensions failed to update"
        [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
        ERRORS+=("gh extension upgrade")
    fi
fi

###############################################################################
# mise
###############################################################################

header "mise"

if ! command -v mise &>/dev/null; then
    skipped "mise (not installed)"
else
    if brew list mise &>/dev/null 2>&1; then
        skipped "mise self-update (managed by Homebrew, updated above)"
    else
        step "Updating mise..."
        if mise self-update --yes 2>"$TMPFILE" >/dev/null; then
            success "mise updated"
        else
            error "Failed to update mise"
            [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
            ERRORS+=("mise self-update")
        fi
    fi

    step "Upgrading mise-managed tools..."
    if mise upgrade 2>"$TMPFILE" >/dev/null; then
        success "mise tools upgraded"
    else
        error "Some mise tools failed to upgrade"
        [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
        ERRORS+=("mise upgrade")
    fi
fi

###############################################################################
# Zsh
###############################################################################

header "Zsh"

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -d "$ZSH_DIR" ]; then
    skipped "oh-my-zsh (not installed)"
else
    step "Updating oh-my-zsh..."
    if ZSH="$ZSH_DIR" zsh "$ZSH_DIR/tools/upgrade.sh" 2>"$TMPFILE" >/dev/null; then
        success "oh-my-zsh updated"
    else
        error "Failed to update oh-my-zsh"
        [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
        ERRORS+=("oh-my-zsh upgrade")
    fi

    # Plugins cloned by fresh.sh, plus fzf-git.sh
    step "Updating zsh plugins..."
    for repo in "${ZSH_CUSTOM:-$ZSH_DIR/custom}"/plugins/*/ "$HOME/fzf-git.sh/"; do
        [ -d "${repo}.git" ] || continue
        if ! git -C "$repo" pull --ff-only --quiet 2>"$TMPFILE"; then
            error "Failed to update $(basename "$repo")"
            [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
            ERRORS+=("$(basename "$repo") pull")
        fi
    done
    success "zsh plugins updated"
fi

###############################################################################
# Cleanup
###############################################################################

header "Cleanup"

step "Cleaning up Homebrew..."
if brew cleanup 2>"$TMPFILE" >/dev/null; then
    success "Cleanup complete"
else
    warning "Cleanup had issues (non-critical)"
    [[ -s "$TMPFILE" ]] && sed 's/^/    /' "$TMPFILE" >&2
fi

###############################################################################
# Summary
###############################################################################

ELAPSED=$((SECONDS - START_TIME))
ERROR_COUNT=${#ERRORS[@]}

echo ""
if [ "$ERROR_COUNT" -eq 0 ]; then
    summary "All systems updated!"
else
    echo -e "\n${YELLOW}⚠${NC} ${BOLD}Completed with $ERROR_COUNT error(s)${NC}\n"
    for err in "${ERRORS[@]}"; do
        echo -e "  ${RED}✗${NC} $err"
    done
    echo ""
fi

info "Current versions:"
list_item "Homebrew: $(brew --version | head -n1)"
command -v node &>/dev/null && list_item "Node.js: $(node -v)"
command -v npm &>/dev/null && list_item "npm: $(npm -v)"
command -v bun &>/dev/null && list_item "bun: $(bun -v)"
command -v mise &>/dev/null && list_item "mise: $(mise --version)"
info "Completed in ${ELAPSED}s"

echo ""
