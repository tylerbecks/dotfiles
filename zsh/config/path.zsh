# Path configuration
# Put Homebrew's bin directory at the front of PATH
export PATH=/opt/homebrew/bin:$PATH

# Add dotfiles bin directory for custom scripts
export PATH="$HOME/dotfiles/bin:$PATH"

# Android SDK (ANDROID_HOME set in env.zsh)
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# bun (BUN_INSTALL set in env.zsh)
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm (PNPM_HOME set in env.zsh)
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
