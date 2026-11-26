#!/usr/bin/env bash

# Signs every commit and tag on this Mac with an SSH key kept in 1Password.
# Opt-in for each Mac: it writes only to this Mac's own ~/.gitconfig and
# ~/.config/git/allowed_signers, and no other setup script runs it.
#
# First, in 1Password: turn on Settings → Developer → "Use the SSH agent", and
# add an SSH key (New Item → SSH Key → Add Private Key → Generate a New Key).
# The script prints the GitHub step at the end.
#
# Usage: bash ~/dotfiles/setup-git-signing.sh [key name]
#        (the name of the 1Password item, needed when 1Password has several
#        SSH keys)
#        bash ~/dotfiles/setup-git-signing.sh --off

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config-files.sh"
source "${SCRIPT_DIR}/lib/git-signing.sh"

# Lets `git log --show-signature` check this machine's own signatures
ALLOWED_SIGNERS="${HOME}/.config/git/allowed_signers"
SIGNING_SETTINGS=(user.signingkey gpg.format gpg.ssh.program gpg.ssh.allowedSignersFile commit.gpgsign tag.gpgsign)

if [[ "$(uname -s)" != Darwin ]]; then
    error "Signing with 1Password is set up for Macs only"
    exit 1
fi
# git config --global would write into the repo's shared .gitconfig
if is_link_into_repo "${HOME}/.gitconfig"; then
    error "~/.gitconfig links into ~/dotfiles (an older setup); run bash ~/dotfiles/refresh.sh first"
    exit 1
fi

if [[ "${1:-}" == --off ]]; then
    if ! git_signing_on; then
        info "Commit signing with 1Password isn't on here; nothing to turn off"
        exit 0
    fi
    for setting in "${SIGNING_SETTINGS[@]}"; do
        git config --global --unset-all "$setting"
    done
    success "Commits and tags on this Mac are no longer signed"
    exit 0
fi

if [[ ! -x "$OP_SSH_SIGN" ]]; then
    error "1Password isn't installed (${OP_SSH_SIGN} is missing)"
    exit 1
fi
if [[ ! -S "$OP_AGENT_SOCK" ]]; then
    error "1Password's SSH agent is off: turn on 1Password → Settings → Developer → Use the SSH agent, then run this again"
    exit 1
fi
EMAIL="$(git config --global user.email)"
if [[ -z "$EMAIL" ]]; then
    error "No global git email; set one first: git config --global user.email <email>"
    exit 1
fi

KEYS="$(op_agent_keys)"
if [[ -n "${1:-}" ]]; then
    # Exact item name, ignoring case
    KEYS="$(awk -v name="$1" '{ c = $0; sub(/^[^ ]+ [^ ]+ /, "", c) } tolower(c) == tolower(name)' <<< "$KEYS")"
fi
if [[ -z "$KEYS" ]]; then
    if [[ -n "${1:-}" ]]; then
        error "1Password has no SSH key named '$1'"
    else
        error "1Password's SSH agent has no keys (unlock 1Password, or add one: New Item → SSH Key → Add Private Key → Generate a New Key)"
    fi
    exit 1
fi
if [[ "$(wc -l <<< "$KEYS")" -gt 1 ]]; then
    error "1Password has several SSH keys; pass the name of the one to sign with:"
    cut -d' ' -f3- <<< "$KEYS" | while read -r name; do
        list_item "bash ~/dotfiles/setup-git-signing.sh \"${name}\""
    done
    exit 1
fi
KEY="$(cut -d' ' -f1,2 <<< "$KEYS")"
NAME="$(cut -d' ' -f3- <<< "$KEYS")"

git config --global gpg.format ssh
git config --global gpg.ssh.program "$OP_SSH_SIGN"
git config --global user.signingkey "key::${KEY}"
git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS"
git config --global commit.gpgsign true
git config --global tag.gpgsign true
SIGNER="${EMAIL} namespaces=\"git\" ${KEY}"
mkdir -p "$(dirname "$ALLOWED_SIGNERS")"
grep -qxF -- "$SIGNER" "$ALLOWED_SIGNERS" 2> /dev/null || printf '%s\n' "$SIGNER" >> "$ALLOWED_SIGNERS"

success "Commits and tags on this Mac are now signed with \"${NAME}\" from 1Password"
info "So GitHub shows them as Verified, add the key there once (any Mac using it counts):"
list_item "https://github.com/settings/ssh/new, with Key type: Signing Key and this key:"
echo "      ${KEY}"
info "The first commit after 1Password unlocks asks for Touch ID, and waits until you approve."
info "To stop signing: bash ~/dotfiles/setup-git-signing.sh --off"
