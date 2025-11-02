# Path configuration
# Put Homebrew's bin directory at the front of PATH
export PATH=/opt/homebrew/bin:$PATH

# Add dotfiles bin directory for custom scripts
export PATH="$HOME/dotfiles/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
