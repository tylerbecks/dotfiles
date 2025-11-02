# Load prompt settings
source "$HOME/dotfiles/zsh/config/prompt.zsh"

# Define plugins before loading Oh-My-Zsh
plugins=(fzf-tab zsh-syntax-highlighting zsh-autosuggestions you-should-use zsh-autopair)

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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# bun completions
[ -s "/Users/tyler/.bun/_bun" ] && source "/Users/tyler/.bun/_bun"