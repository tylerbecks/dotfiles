#!/usr/bin/env bash

# Clones the zsh plugins into oh-my-zsh's custom dir, plus fzf-git.sh. Shared
# by fresh.sh and linux.sh; refresh.sh keeps them updated and doctor.sh checks
# them.
#
# Usage: source lib/zsh-plugins.sh, then install_zsh_plugins or check_zsh_plugins

# Every plugin here must also be in the plugins list in zsh/.zshrc. "name|url"
ZSH_PLUGINS=(
    "fzf-tab|https://github.com/Aloxaf/fzf-tab"
    "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
    "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
    "zsh-autopair|https://github.com/hlissner/zsh-autopair"
    "you-should-use|https://github.com/MichaelAquilina/zsh-you-should-use.git"
)

# Use $HOME, not ~: tilde does not expand inside quotes, which would clone into
# a literal "~" dir under the cwd.
zsh_plugins_dir() {
    echo "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
}

install_omz_plugin() {
    local name="$1" url="$2" plugins_dir
    plugins_dir="$(zsh_plugins_dir)"
    step "Installing ${name}..."
    mkdir -p "$plugins_dir"
    if [ -d "${plugins_dir}/${name}" ]; then
        success "${name} already installed"
    elif git clone --depth 1 "$url" "${plugins_dir}/${name}" &> /dev/null; then
        success "${name} installed"
    else
        warning "Failed to clone ${name} from ${url}"
    fi
}

install_zsh_plugins() {
    local plugin
    for plugin in "${ZSH_PLUGINS[@]}"; do
        install_omz_plugin "${plugin%%|*}" "${plugin#*|}"
    done

    step "Installing fzf-git.sh..."
    if [ -d "$HOME/fzf-git.sh" ]; then
        success "fzf-git.sh already installed"
    elif git clone --depth 1 https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh" &> /dev/null; then
        success "fzf-git.sh installed"
    else
        warning "Failed to clone fzf-git.sh"
    fi
}

# Checks oh-my-zsh and every plugin without changing anything. Returns 1 if
# something is missing.
check_zsh_plugins() {
    local plugin name plugins_dir missing=()
    plugins_dir="$(zsh_plugins_dir)"
    if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        error "oh-my-zsh isn't installed"
        return 1
    fi
    for plugin in "${ZSH_PLUGINS[@]}"; do
        name="${plugin%%|*}"
        [ -d "${plugins_dir}/${name}" ] || missing+=("$name")
    done
    [ -d "$HOME/fzf-git.sh" ] || missing+=("fzf-git.sh")
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing zsh plugins: ${missing[*]}"
        return 1
    fi
    success "oh-my-zsh and ${#ZSH_PLUGINS[@]} plugins installed, plus fzf-git.sh"
}
