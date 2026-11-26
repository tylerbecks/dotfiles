# Plugins are defined in .zshrc before oh-my-zsh is sourced

# Set up fzf key bindings and fuzzy completion. `fzf --zsh` needs fzf 0.48+;
# older distro packages (Ubuntu 24.04 ships 0.44) install the scripts instead.
if command -v fzf &> /dev/null && _fzf_init="$(fzf --zsh 2> /dev/null)"; then
  eval "$_fzf_init"
elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
fi
unset _fzf_init

# fzf-tab configuration
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'