# Navigation and directory operations
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
# eza older than 0.15 (some Linux packages) takes a bare --icons
if eza --icons=auto --version &> /dev/null; then
  _eza_icons="--icons=auto"
else
  _eza_icons="--icons"
fi
alias ls="eza $_eza_icons"
alias ll="eza -la $_eza_icons"
alias la="eza -a $_eza_icons"
alias lt="eza -laT --git $_eza_icons"
alias l="eza -l $_eza_icons"
unset _eza_icons

# Safe file operations (interactive + verbose)
alias mv='mv -i -v'
alias cp='cp -i -v'
alias mkdir='mkdir -p -v'
