# History configuration
HISTFILE=$HOME/.zhistory
# Lines kept in memory must be at least the lines saved, or
# hist_expire_dups_first has no spare room to drop duplicates from first
HISTSIZE=110000
SAVEHIST=100000
setopt share_history          # every open shell sees each other's commands
setopt extended_history       # save when each command ran
setopt hist_expire_dups_first # drop duplicates first when trimming
setopt hist_ignore_dups       # don't save a command twice in a row
setopt hist_find_no_dups      # skip duplicates when searching
setopt hist_ignore_space      # don't save commands that start with a space
setopt hist_reduce_blanks     # trim extra spaces before saving
setopt hist_verify            # show !! expansions before running them

# Search history with arrow keys
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
