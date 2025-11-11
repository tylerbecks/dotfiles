# Navigation and directory operations
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls="eza --icons=auto"
alias ll="eza -la --icons=auto"
alias la="eza -a --icons=auto"
alias lt="eza -laT --git --icons=auto"
alias l="eza -l --icons=auto"
alias cdl="cd $1 && ll"
alias mg="mkdir -p $1 && cd $1"

# Safe file operations (interactive + verbose)
alias mv='mv -i -v'
alias cp='cp -i -v'
alias mkdir='mkdir -p -v'

# Application shortcuts

# Development helpers
alias npm-latest="npm info $1 | grep latest"
alias killport="lsof -i tcp:$1 | awk 'NR!=1 {print \$2}' | xargs kill -9"