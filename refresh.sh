#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

###############################################################################
# System Update
###############################################################################

header "System Update"

###############################################################################
# Homebrew
###############################################################################

header "Homebrew"

step "Updating Homebrew..."
if brew update &> /dev/null; then
    success "Homebrew updated"
else
    error "Failed to update Homebrew"
fi

step "Upgrading packages..."
OUTDATED=$(brew outdated | wc -l | tr -d ' ')
if [ "$OUTDATED" -gt 0 ]; then
    info "Upgrading $OUTDATED package(s)..."
    if brew upgrade; then
        success "Packages upgraded"
    else
        error "Some packages failed to upgrade"
    fi
else
    success "All packages are up to date"
fi

###############################################################################
# Mac App Store
###############################################################################

header "Mac App Store"

step "Checking for App Store updates..."
MAS_OUTDATED=$(mas outdated | wc -l | tr -d ' ')
if [ "$MAS_OUTDATED" -gt 0 ]; then
    info "Upgrading $MAS_OUTDATED app(s)..."
    if mas upgrade; then
        success "App Store apps upgraded"
    else
        warning "Some apps failed to upgrade"
    fi
else
    success "All App Store apps are up to date"
fi

###############################################################################
# npm
###############################################################################

header "npm"

step "Updating npm itself..."
NPM_CURRENT=$(npm -v 2>/dev/null)
if npm install -g npm@latest &> /dev/null; then
    NPM_NEW=$(npm -v 2>/dev/null)
    if [ "$NPM_CURRENT" != "$NPM_NEW" ]; then
        success "npm updated: $NPM_CURRENT → $NPM_NEW"
    else
        success "npm already up to date ($NPM_CURRENT)"
    fi
else
    error "Failed to update npm"
fi

step "Updating global npm packages..."
if npm update -g &> /dev/null; then
    success "Global npm packages updated"
else
    warning "Some npm packages failed to update"
fi

###############################################################################
# pnpm
###############################################################################

header "pnpm"

step "Updating pnpm..."
PNPM_CURRENT=$(pnpm -v 2>/dev/null)
if pnpm self-update &> /dev/null; then
    PNPM_NEW=$(pnpm -v 2>/dev/null)
    if [ "$PNPM_CURRENT" != "$PNPM_NEW" ]; then
        success "pnpm updated: $PNPM_CURRENT → $PNPM_NEW"
    else
        success "pnpm already up to date ($PNPM_CURRENT)"
    fi
else
    warning "Failed to update pnpm"
fi

###############################################################################
# GitHub Copilot CLI
###############################################################################

header "GitHub CLI Extensions"

step "Updating gh-copilot extension..."
if gh extension upgrade gh-copilot &> /dev/null; then
    success "gh-copilot updated"
else
    warning "gh-copilot update failed (may already be up to date)"
fi

###############################################################################
# Cleanup
###############################################################################

header "Cleanup"

step "Cleaning up Homebrew..."
if brew cleanup &> /dev/null; then
    success "Cleanup complete"
else
    warning "Cleanup had issues (non-critical)"
fi

###############################################################################
# Summary
###############################################################################

summary "All systems updated!"

info "Current versions:"
list_item "Homebrew: $(brew --version | head -n1)"
list_item "Node.js: $(node -v 2>/dev/null || echo 'not installed')"
list_item "npm: $(npm -v 2>/dev/null || echo 'not installed')"
list_item "pnpm: $(pnpm -v 2>/dev/null || echo 'not installed')"

echo ""
