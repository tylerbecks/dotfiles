# Prompt configuration using Starship
# https://starship.rs/

# Initialize Starship prompt
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Make sure ZSH theme is empty to avoid conflicts
ZSH_THEME=""