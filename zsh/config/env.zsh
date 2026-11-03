# Homebrew (must be early so subsequent configs can find brew-installed tools)
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
# Homebrew completions; must be on fpath before oh-my-zsh runs compinit
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Dotfiles location
export DOTFILES="$HOME/dotfiles"

# Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
# Keep the completion cache out of $HOME; zsh skips saving it when the home
# dir fails its writability check, which makes every shell rebuild it
ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
[[ -d ${ZSH_COMPDUMP:h} ]] || mkdir -p ${ZSH_COMPDUMP:h}

# Starship prompt
export STARSHIP_CONFIG="$HOME/dotfiles/starship/starship.toml"

# Bun runtime
export BUN_INSTALL="$HOME/.bun"

# Editor
export EDITOR="code --wait"
export VISUAL="code --wait"

# Disable telemetry
export NEXT_TELEMETRY_DISABLED=1
export HOMEBREW_NO_ANALYTICS=1
