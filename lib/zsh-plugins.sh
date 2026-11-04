#!/usr/bin/env bash

# Clones the zsh plugins into oh-my-zsh's custom dir, plus fzf-git.sh. Shared
# by fresh.sh and linux.sh; refresh.sh keeps them updated.
#
# Usage: source lib/zsh-plugins.sh, then install_zsh_plugins

# All plugins load from the plugins list in zsh/.zshrc. Use $HOME, not ~: tilde
# does not expand inside quotes, which would clone into a literal "~" dir under
# the cwd.
install_omz_plugin() {
    local name="$1" url="$2"
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
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
    install_omz_plugin fzf-tab https://github.com/Aloxaf/fzf-tab
    install_omz_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
    install_omz_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
    install_omz_plugin zsh-autopair https://github.com/hlissner/zsh-autopair
    install_omz_plugin you-should-use https://github.com/MichaelAquilina/zsh-you-should-use.git

    step "Installing fzf-git.sh..."
    if [ -d "$HOME/fzf-git.sh" ]; then
        success "fzf-git.sh already installed"
    elif git clone --depth 1 https://github.com/junegunn/fzf-git.sh.git "$HOME/fzf-git.sh" &> /dev/null; then
        success "fzf-git.sh installed"
    else
        warning "Failed to clone fzf-git.sh"
    fi
}
