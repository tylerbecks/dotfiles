# Initialize mise version manager (Linux boxes may use system runtimes instead)
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi