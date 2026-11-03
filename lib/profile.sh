#!/usr/bin/env bash

# Decides whether this is a work or personal machine so setup scripts can skip
# what doesn't belong there. Work laptops are detected automatically; pass
# --work or --personal to override.
#
# Usage: source lib/profile.sh, then `if is_work; then ...`

if [[ -z "${DOTFILES_PROFILE:-}" ]]; then
    for arg in "$@"; do
        case "$arg" in
            --work) DOTFILES_PROFILE=work ;;
            --personal) DOTFILES_PROFILE=personal ;;
        esac
    done
fi

if [[ -z "${DOTFILES_PROFILE:-}" ]]; then
    if [[ -d /var/facebook ]]; then
        DOTFILES_PROFILE=work
    else
        DOTFILES_PROFILE=personal
    fi
fi

export DOTFILES_PROFILE

is_work() { [[ "$DOTFILES_PROFILE" == work ]]; }
is_personal() { [[ "$DOTFILES_PROFILE" == personal ]]; }
