# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Load prompt settings
source "$HOME/dotfiles/zsh/config/prompt.zsh"

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Load configs
for config_file ($HOME/dotfiles/zsh/config/*.zsh); do
  source $config_file
done

# Load functions
for function_file ($HOME/dotfiles/zsh/functions/*.zsh); do
  source $function_file
done

# Load aliases
for alias_file ($HOME/dotfiles/zsh/aliases/*.zsh); do
  source $alias_file
done

# Load plugins (this should be after custom configs to allow for plugin customization)
source "$HOME/dotfiles/zsh/config/plugins.zsh"