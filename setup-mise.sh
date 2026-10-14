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
# Global Config
###############################################################################

header "Global Config"

step "Linking mise config..."
mkdir -p "${HOME}/.config/mise"
ln -sf "${SCRIPT_DIR}/config/mise/config.toml" "${HOME}/.config/mise/config.toml"
success "mise config linked"

###############################################################################
# Tools
###############################################################################

header "Tools"

# Installs everything in config/mise/config.toml: language runtimes and
# global npm CLIs. mise keeps them up to date afterwards (tool_update.global_auto).
step "Installing tools..."
if mise install --yes; then
    success "Tools installed"
else
    error "Failed to install tools"
    exit 1
fi

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
