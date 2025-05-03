# Prompt configuration using Starship
# https://starship.rs/

export STARSHIP_CONFIG=~/dotfiles/starship/starship.toml

# Initialize Starship prompt
eval "$(starship init zsh)"

# Make sure ZSH theme is empty to avoid conflicts
ZSH_THEME=""