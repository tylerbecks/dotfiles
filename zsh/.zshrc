# >>> TEMP startup profiling: logs a timed trace when startup is slow >>>
zmodload zsh/datetime
_zsh_t0=$EPOCHREALTIME
_zsh_trace=$(mktemp -t zsh-startup)
exec {_zsh_stderr}>&2 2>"$_zsh_trace"
PS4='+$EPOCHREALTIME %N:%i> '
setopt xtrace
# <<< TEMP startup profiling <<<

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
export PATH="$HOME/.local/bin:$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# >>> TEMP startup profiling >>>
unsetopt xtrace
exec 2>&$_zsh_stderr {_zsh_stderr}>&-
_zsh_t1=$EPOCHREALTIME
_zsh_first_prompt() {
  local now=$EPOCHREALTIME
  add-zsh-hook -d precmd _zsh_first_prompt
  if (( now - _zsh_t0 > ${ZSH_SLOW_THRESHOLD:-2} )); then
    mkdir -p ~/.cache/zsh-slow
    local out=~/.cache/zsh-slow/$(date +%Y%m%d-%H%M%S)-$$.log
    printf 'zshrc: %.2fs  first prompt: %.2fs\n' $(( _zsh_t1 - _zsh_t0 )) $(( now - _zsh_t0 )) > $out
    cat $_zsh_trace >> $out
  fi
  rm -f $_zsh_trace
}
autoload -Uz add-zsh-hook
# Registered last so it runs after mise's and starship's precmd hooks
precmd_functions+=(_zsh_first_prompt)
# <<< TEMP startup profiling <<<
