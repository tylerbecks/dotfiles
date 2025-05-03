# Initialize asdf version manager

# Add asdf shims to the PATH (required)
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Source asdf.sh if it exists
if [[ -f $(brew --prefix asdf)/libexec/asdf.sh ]]; then
  . "$(brew --prefix asdf)/libexec/asdf.sh"
fi

# Add the asdf completions to fpath
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)

# Make sure the asdf completions directory exists
if [[ ! -d "${ASDF_DATA_DIR:-$HOME/.asdf}/completions" ]]; then
  mkdir -p "${ASDF_DATA_DIR:-$HOME/.asdf}/completions"
  
  # Generate the completions file if asdf is installed
  if command -v asdf &> /dev/null; then
    asdf completion zsh > "${ASDF_DATA_DIR:-$HOME/.asdf}/completions/_asdf"
  fi
fi