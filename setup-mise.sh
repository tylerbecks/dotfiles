#!/usr/bin/env bash

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

###############################################################################
# Mise Setup
###############################################################################

header "Mise Setup"

# Check if mise is installed
if ! command -v mise &> /dev/null; then
    error "mise is not installed. Please install it first with: brew install mise"
    exit 1
else
    success "mise found"
fi

###############################################################################
# Language Runtimes
###############################################################################

header "Language Runtimes"

step "Installing Node.js LTS..."
if mise use --global node@lts &> /dev/null; then
    NODE_VERSION=$(mise current node 2>/dev/null | awk '{print $2}')
    success "Node.js ${NODE_VERSION} installed"
else
    error "Failed to install Node.js"
    exit 1
fi

step "Installing Python 3..."
if mise use --global python@3 &> /dev/null; then
    PYTHON_VERSION=$(mise current python 2>/dev/null | awk '{print $2}')
    success "Python ${PYTHON_VERSION} installed"
else
    error "Failed to install Python"
    exit 1
fi

###############################################################################
# Global npm Packages
###############################################################################

header "Global npm Packages"

step "Installing @anthropic-ai/claude-code..."
npm install -g @anthropic-ai/claude-code &> /dev/null

step "Installing better-commits..."
npm install -g better-commits &> /dev/null

step "Installing tldr..."
npm install -g tldr &> /dev/null

step "Installing rimraf..."
npm install -g rimraf &> /dev/null

success "Global npm packages installed"

###############################################################################
# Summary
###############################################################################

summary "mise setup complete!"

info "Installed versions:"
mise ls 2>/dev/null | while read -r line; do
    if [[ -n "$line" ]]; then
        list_item "$line"
    fi
done

echo ""
info "To activate mise in your current shell, run:"
echo -e "  ${DIM}eval \"\$(mise activate \$(basename \$SHELL))\"${NC}"
