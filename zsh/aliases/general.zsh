# Navigation and directory operations
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ls="eza --icons=always"
alias ll="eza -la --icons=always"
alias la="eza -a --icons=always"
alias lt="eza -laT --git --icons=always"
alias l="eza -l --icons=always"
alias cdl="cd $1 && ll"
alias mg="mkdir -p $1 && cd $1"

# Application shortcuts

# Development helpers
alias npm-latest="npm info $1 | grep latest"
alias killport="lsof -i tcp:$1 | awk 'NR!=1 {print \$2}' | xargs kill -9"