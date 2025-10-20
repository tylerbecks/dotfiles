# Silence beep sounds from autocomplete
unsetopt BEEP

# Path to your dotfiles
export DOTFILES=$HOME/dotfiles

# Custom Git Function for diff tools
git() {
    if [[ $1 == "show" ]]; then
        command git "$@" --ext-diff
    elif [[ $1 == "log" && "$*" == *"-p"* ]]; then
        command git "$@" --ext-diff
    else
        command git "$@"
    fi
}

# 1Password autocomplete
eval "$(op completion zsh)"; compdef _op op