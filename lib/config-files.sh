#!/usr/bin/env bash

# Every config file this repo puts in ~, listed once in CONFIG_FILES. fresh.sh
# and linux.sh apply them on a new machine, refresh.sh applies them again so a
# row added here reaches machines that are already set up, and doctor.sh
# checks them. To add a config file, add a row; nothing else needs to change.
#
# Usage: source lib/config-files.sh, then setup_shared_config (everything the
# setup scripts share) or apply_config_files / check_config_files

CONFIG_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CONFIG_LIB_DIR}/logger.sh"
source "${CONFIG_LIB_DIR}/profile.sh"
source "${CONFIG_LIB_DIR}/claude-settings.sh"

# The zsh config, the Claude hooks and the import lines below all point at
# ~/dotfiles, so the repo has to live there. Linking from a clone somewhere
# else (an agent's worktree, say) would point this machine's config at it.
DOTFILES_REPO="${HOME}/dotfiles"

# This repo is public and personal, so it always commits with this email.
PERSONAL_GIT_EMAIL="tylerdbecks@gmail.com"

# One row per file: "kind|source|target|machines". Targets are relative to ~.
#
#   link         ~/<target> becomes a symlink to <source> in this repo. A real
#                file in the way is moved aside to <target>.pre-dotfiles.
#   copy         <source> is copied to ~/<target> when the target is missing.
#                For files the app rewrites itself (btop saves its config on
#                exit), where a link would write into this repo. doctor.sh
#                warns when a copy has drifted from the repo.
#   line         The text <source> is a line in ~/<target>, added at the end
#                when missing. For files that stay the machine's own (work
#                tooling and dev boxes put site settings in them) and only pull
#                in ours.
#   git-include  ~/.gitconfig includes <source>, in row order (later ones win).
#
# machines: all, mac, linux, vscode (personal Macs with VS Code; the managed
# VS Code on work laptops keeps its corp settings) or cursor.
# shellcheck disable=SC2016  # $HOME in the zshrc line is for zsh to expand
CONFIG_FILES=(
    "link|zsh/.zshrc|.zshrc|mac"
    'line|source "$HOME/dotfiles/zsh/.zshrc"|.zshrc|linux'
    "git-include|.gitconfig|.gitconfig|all"
    "git-include|config/git/linux|.gitconfig|linux"
    "link|config/git/ignore|.config/git/ignore|all"
    "link|.better-commits.json|.better-commits.json|all"
    "link|config/bat/config|.config/bat/config|all"
    "copy|btop/btop.conf|.config/btop/btop.conf|all"
    "copy|btop/night-owl.theme|.config/btop/themes/night-owl.theme|all"
    "link|config/mise/config.toml|.config/mise/config.toml|mac"
    "link|wezterm/wezterm.lua|.config/wezterm/wezterm.lua|mac"
    "link|wezterm/appearance.lua|.config/wezterm/appearance.lua|mac"
    "line|@~/dotfiles/claude/CLAUDE.md|.claude/CLAUDE.md|all"
    "link|vscode/settings.json|Library/Application Support/Code/User/settings.json|vscode"
    "link|vscode/keybindings.json|Library/Application Support/Code/User/keybindings.json|vscode"
    "link|vscode/snippets|Library/Application Support/Code/User/snippets|vscode"
    "link|vscode/settings.json|Library/Application Support/Cursor/User/settings.json|cursor"
    "link|vscode/keybindings.json|Library/Application Support/Cursor/User/keybindings.json|cursor"
    "link|vscode/snippets|Library/Application Support/Cursor/User/snippets|cursor"
)

# Whether a row's machines value covers this machine
config_file_wanted() {
    case "$1" in
        all) return 0 ;;
        mac) [[ "$(uname -s)" == Darwin ]] ;;
        linux) [[ "$(uname -s)" == Linux ]] ;;
        vscode) [[ "$(uname -s)" == Darwin ]] && is_personal && [[ -d "/Applications/Visual Studio Code.app" ]] ;;
        cursor) [[ "$(uname -s)" == Darwin ]] && [[ -d "/Applications/Cursor.app" ]] ;;
        *)
            error "Unknown machines value '$1' in CONFIG_FILES"
            return 1
            ;;
    esac
}

# Fails with a message when this copy of the repo isn't the one at ~/dotfiles
require_dotfiles_repo() {
    if [[ "$(cd "${CONFIG_LIB_DIR}/.." && pwd -P)" != "$(cd "$DOTFILES_REPO" 2> /dev/null && pwd -P)" ]]; then
        error "This copy of the repo isn't ~/dotfiles; run the script from ~/dotfiles"
        return 1
    fi
}

# Removes ~/<target> when it's a symlink into this repo. Earlier versions of
# the setup scripts linked files that are now the machine's own.
unlink_from_repo() {
    local target="$1"
    if [[ -L "$target" && "$(readlink "$target")" == "$DOTFILES_REPO"/* ]]; then
        rm "$target"
    fi
}

apply_config_link() {
    local source="${DOTFILES_REPO}/$1" target="${HOME}/$2" backup
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        return 0
    fi
    mkdir -p "$(dirname "$target")" || return 1
    if [[ -L "$target" ]]; then
        rm "$target" || return 1
    elif [[ -e "$target" ]]; then
        backup="${target}.pre-dotfiles"
        if [[ -e "$backup" || -L "$backup" ]]; then
            backup="${backup}.$(date +%Y%m%d%H%M%S)"
        fi
        mv "$target" "$backup" || return 1
        warning "Moved ~/$2 aside to ${backup/#"$HOME"/\~} to link it"
    fi
    ln -s "$source" "$target"
}

apply_config_copy() {
    local source="${DOTFILES_REPO}/$1" target="${HOME}/$2"
    [[ -e "$target" ]] && return 0
    mkdir -p "$(dirname "$target")" && cp "$source" "$target"
}

apply_config_line() {
    local line="$1" target="${HOME}/$2"
    unlink_from_repo "$target"
    mkdir -p "$(dirname "$target")" || return 1
    grep -qxF -- "$line" "$target" 2> /dev/null && return 0
    # Start on a new line when the file doesn't end with one
    if [[ -s "$target" && -n "$(tail -c 1 "$target")" ]]; then
        echo >> "$target"
    fi
    printf '%s\n' "$line" >> "$target"
}

apply_config_git_include() {
    local include="${DOTFILES_REPO}/$1"
    unlink_from_repo "${HOME}/.gitconfig"
    git config --global --get-all include.path 2> /dev/null | grep -qxF -- "$include" && return 0
    git config --global --add include.path "$include"
}

# Applies every CONFIG_FILES row for this machine, or only the rows whose
# target is named. Prints a line only for problems; returns 1 if any failed.
# Usage: apply_config_files [target...]
# shellcheck disable=SC2120  # setup-mise.sh passes targets
apply_config_files() {
    require_dotfiles_repo || return 1
    local row kind source target machines wanted name status=0
    for row in "${CONFIG_FILES[@]}"; do
        IFS='|' read -r kind source target machines <<< "$row"
        config_file_wanted "$machines" || continue
        if [[ $# -gt 0 ]]; then
            wanted=false
            for name in "$@"; do [[ "$name" == "$target" ]] && wanted=true; done
            [[ "$wanted" == true ]] || continue
        fi
        case "$kind" in
            link) apply_config_link "$source" "$target" ;;
            copy) apply_config_copy "$source" "$target" ;;
            line) apply_config_line "$source" "$target" ;;
            git-include) apply_config_git_include "$source" ;;
            *) error "Unknown kind '${kind}' in CONFIG_FILES" && false ;;
        esac || {
            error "Couldn't set up ~/${target} (${kind} ${source})"
            status=1
        }
    done
    return "$status"
}

# Checks every CONFIG_FILES row for this machine without changing anything.
# Prints one line per problem and a count of the rest; returns 1 if any file
# is missing or wrong (a drifted copy is only a warning).
check_config_files() {
    require_dotfiles_repo || return 1
    local row kind source target machines ok=0 status=0
    for row in "${CONFIG_FILES[@]}"; do
        IFS='|' read -r kind source target machines <<< "$row"
        config_file_wanted "$machines" || continue
        case "$kind" in
            link)
                if [[ -L "${HOME}/${target}" && "$(readlink "${HOME}/${target}")" == "${DOTFILES_REPO}/${source}" ]]; then
                    ok=$((ok + 1))
                elif [[ -L "${HOME}/${target}" ]]; then
                    error "~/${target} links to $(readlink "${HOME}/${target}"), not ~/dotfiles/${source}"
                    status=1
                elif [[ -e "${HOME}/${target}" ]]; then
                    error "~/${target} is a real file, not a link to ~/dotfiles/${source}"
                    status=1
                else
                    error "~/${target} is missing (should link to ~/dotfiles/${source})"
                    status=1
                fi
                ;;
            copy)
                if [[ ! -e "${HOME}/${target}" ]]; then
                    error "~/${target} is missing (a copy of ~/dotfiles/${source})"
                    status=1
                elif ! cmp -s "${DOTFILES_REPO}/${source}" "${HOME}/${target}"; then
                    warning "~/${target} differs from ~/dotfiles/${source} (copy whichever is right over the other)"
                else
                    ok=$((ok + 1))
                fi
                ;;
            line)
                if grep -qxF -- "$source" "${HOME}/${target}" 2> /dev/null; then
                    ok=$((ok + 1))
                else
                    error "~/${target} is missing the line: ${source}"
                    status=1
                fi
                ;;
            git-include)
                if git config --global --get-all include.path 2> /dev/null | grep -qxF -- "${DOTFILES_REPO}/${source}"; then
                    ok=$((ok + 1))
                else
                    error "~/.gitconfig doesn't include ~/dotfiles/${source}"
                    status=1
                fi
                ;;
        esac
    done
    success "${ok} config files in place"
    return "$status"
}

# The git email for this machine and for this repo
setup_git_identity() {
    if is_personal && ! git config --global user.email &> /dev/null; then
        git config --global user.email "$PERSONAL_GIT_EMAIL"
    fi
    git -C "$DOTFILES_REPO" config user.email "$PERSONAL_GIT_EMAIL"
    if ! git config --global user.email &> /dev/null; then
        warning "No global git email; set one with: git config --global user.email <email>"
    fi
}

# The Night Owl theme that config/bat/config selects. Debian and Ubuntu name
# the bat binary batcat.
setup_bat_theme() {
    local themes="${HOME}/.config/bat/themes" bat_cmd
    mkdir -p "$themes"
    if [[ ! -d "${themes}/night-owlish" ]] &&
        ! git clone --depth 1 https://github.com/batpigandme/night-owlish "${themes}/night-owlish" &> /dev/null; then
        warning "Failed to clone the bat theme (re-run with network access)"
    fi
    bat_cmd="$(command -v bat || command -v batcat)"
    if [[ -n "$bat_cmd" ]]; then
        "$bat_cmd" cache --build &> /dev/null
    fi
}

# Everything fresh.sh, linux.sh and refresh.sh set up the same way: the config
# files above, the git email, the bat theme, and Claude Code's settings,
# skills and agents. Safe to run again. Returns 1 if a config file failed, or
# right away, changing nothing, when this copy of the repo isn't ~/dotfiles
# (link_claude_config links to wherever this file lives).
setup_shared_config() {
    local status=0
    require_dotfiles_repo || return 1
    step "Linking config files..."
    if apply_config_files; then
        success "Config files in place"
    else
        status=1
    fi

    step "Configuring git..."
    setup_git_identity
    success "Git configured"

    step "Configuring bat..."
    setup_bat_theme
    success "bat configured"

    # Status line and hooks merged into the machine's own settings.json, and
    # skills and agents linked one by one so machine-local ones stay put
    step "Configuring Claude Code..."
    merge_claude_settings
    link_claude_config
    success "Claude Code configured"
    return "$status"
}
