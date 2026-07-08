# Homebrew (must be early so subsequent configs can find brew-installed tools)
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH

# Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Dotfiles location
export DOTFILES="$HOME/dotfiles"

# Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"

# Starship prompt
export STARSHIP_CONFIG="$HOME/dotfiles/starship/starship.toml"

# Java
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"

# Bun runtime
export BUN_INSTALL="$HOME/.bun"

# pnpm package manager
export PNPM_HOME="$HOME/Library/pnpm"

# Editor
export EDITOR="code --wait"
export VISUAL="code --wait"

# Disable telemetry
export NEXT_TELEMETRY_DISABLED=1
export HOMEBREW_NO_ANALYTICS=1
