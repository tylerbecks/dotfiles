# Load environment variables first (needed for oh-my-zsh)
source "$HOME/dotfiles/zsh/config/env.zsh"

# Load prompt settings
source "$HOME/dotfiles/zsh/config/prompt.zsh"

# Define plugins before loading Oh-My-Zsh
plugins=(fzf-tab zsh-syntax-highlighting zsh-autosuggestions you-should-use zsh-autopair)

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Load remaining configs (skip env.zsh since already loaded)
for config_file ($HOME/dotfiles/zsh/config/*.zsh); do
  [[ "$config_file" == *"/env.zsh" ]] && continue
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
# Added by Antigravity
export PATH="/Users/tyler/.antigravity/antigravity/bin:$PATH"
