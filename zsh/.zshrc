# Load environment variables first (needed for oh-my-zsh)
source "$HOME/dotfiles/zsh/config/env.zsh"

# Load prompt settings
source "$HOME/dotfiles/zsh/config/prompt.zsh"

# Define plugins before loading Oh-My-Zsh. zsh-syntax-highlighting must stay
# last: it wraps the widgets the other plugins create.
plugins=(fzf-tab zsh-autosuggestions you-should-use zsh-autopair zsh-syntax-highlighting)

# Load Oh-My-Zsh (skipped until linux.sh has cloned it on a new box)
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# Load remaining configs (env.zsh and prompt.zsh are already loaded)
for config_file ($HOME/dotfiles/zsh/config/*.zsh); do
  [[ "$config_file" == */(env|prompt).zsh ]] && continue
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

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# zoxide (`z <part of a path>` jumps to frequent dirs); its docs want it last
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi
