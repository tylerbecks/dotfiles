#!/usr/bin/env bash

# Professional logging utilities for dotfiles setup scripts
# Source this file to get clean, colored output for CLI operations

# Only use colors if stdout is a terminal
if [[ -t 1 ]]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m'  # No Color
else
    BOLD=''
    DIM=''
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    NC=''
fi

# Display a major section header
# Usage: header "Installing Homebrew"
header() {
    echo -e "\n${BOLD}${CYAN}▸${NC} ${BOLD}$1${NC}"
}

# Display a step in progress
# Usage: step "Installing Node.js..."
step() {
    echo -e "  ${DIM}→${NC} $1"
}

# Display a success message
# Usage: success "Node.js installed"
success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

# Display an error message (to stderr)
# Usage: error "Failed to install package"
error() {
    echo -e "  ${RED}✗${NC} $1" >&2
}

# Display a warning message
# Usage: warning "This may take a while"
warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

# Display an info message
# Usage: info "Skipping optional step"
info() {
    echo -e "  ${BLUE}ℹ${NC} $1"
}

# Display a final summary with checkmark
# Usage: summary "Setup complete! Installed 42 packages"
summary() {
    echo -e "\n${GREEN}✓${NC} ${BOLD}$1${NC}\n"
}

# Display a list item (for manual steps, etc.)
# Usage: list_item "Grant Terminal Full Disk Access"
list_item() {
    echo -e "  ${DIM}•${NC} $1"
}
