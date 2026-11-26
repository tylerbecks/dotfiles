#!/usr/bin/env bash

# Opt-in commit signing with an SSH key kept in 1Password. setup-git-signing.sh
# turns it on for one Mac by writing to that Mac's own ~/.gitconfig; nothing
# shared or run by the other setup scripts sets it, so a fork, or a friend's
# Mac set up from this repo, signs nothing until its owner opts in with their
# own key.
#
# Usage: source lib/logger.sh and lib/git-signing.sh, then
# `if git_signing_on; then check_git_signing; fi`

# 1Password's signing helper, and its SSH agent, which is there while
# 1Password → Settings → Developer → "Use the SSH agent" is on
OP_SSH_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
OP_AGENT_SOCK="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Whether setup-git-signing.sh turned signing on here
git_signing_on() {
    [[ "$(git config --global gpg.ssh.program 2> /dev/null)" == "$OP_SSH_SIGN" ]]
}

# The SSH public keys 1Password's agent offers, one "type key comment" per
# line. 1Password uses the item's name as the comment. Prints nothing when the
# agent is off, empty, or 1Password is locked.
op_agent_keys() {
    [[ -S "$OP_AGENT_SOCK" ]] || return 0
    SSH_AUTH_SOCK="$OP_AGENT_SOCK" ssh-add -L 2> /dev/null | grep '^ssh-' || true
}

# Checks that commits can still be signed where signing is on. Returns 1 when
# they would fail. A key the agent doesn't list is only a warning: a locked
# 1Password lists none, and asks to unlock when a commit signs.
check_git_signing() {
    local key
    key="$(git config --global user.signingkey)"
    key="${key#key::}"
    if [[ ! -x "$OP_SSH_SIGN" ]]; then
        error "Commits are set to sign with 1Password, but ${OP_SSH_SIGN} is missing (reinstall 1Password, or: bash ~/dotfiles/setup-git-signing.sh --off)"
        return 1
    fi
    if [[ ! -S "$OP_AGENT_SOCK" ]]; then
        error "Commits are set to sign with 1Password, but its SSH agent is off: turn on 1Password → Settings → Developer → Use the SSH agent"
        return 1
    fi
    if ! op_agent_keys | grep -qF -- "$key"; then
        warning "1Password's SSH agent doesn't list the signing key (1Password may be locked, or the key was deleted; run setup-git-signing.sh again to pick another)"
        return 0
    fi
    success "Commits and tags are signed with an SSH key in 1Password"
}
