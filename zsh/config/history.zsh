# History configuration
HISTFILE=$HOME/.zhistory
SAVEHIST=10000
HISTSIZE=9999
setopt share_history 
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# Search history with arrow keys
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward