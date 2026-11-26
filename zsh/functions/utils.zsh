# Create a directory and enter it
function mg() {
  mkdir -p "$@" && cd "$@" || return
}

# Change to a directory and list its contents
function cdl() {
  cd "$@" && ls
}

# Check the latest version of an npm package
function npm-latest() {
  npm info "$1" | grep latest
}

# Kill processes on a specific port
function killport() {
  lsof -i tcp:"$*" | awk 'NR!=1 {print $2}' | xargs kill -9
}

# Extract most know archives
function extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Find all files containing a pattern
function findtext() {
  rg --color=always "$1" | less -RX
}

# Open VS Code with the given directory/file
function c() {
  code "${1:-.}"
}

# Generate a new SSH key
function genssh() {
  ssh-keygen -t ed25519 -C "$1"
}

# Make a new temporary directory and cd into it
function tempd() {
  local dir
  dir="$(mktemp -d)" && cd "$dir" && echo "$dir"
}

# Desktop notification, e.g. `make build; notify "build done"`.
# Usage: notify <message> [title]
function notify() {
  if [[ $# -lt 1 ]]; then
    echo "Usage: notify <message> [title]" >&2
    return 1
  fi
  local message="$1" title="${2:-Terminal}"
  if command -v osascript &> /dev/null; then
    # Passed as arguments rather than spliced into the script, so quotes in
    # the message can't break it
    osascript -e 'on run argv' \
      -e 'display notification (item 1 of argv) with title (item 2 of argv)' \
      -e 'end run' "$message" "$title"
  elif command -v notify-send &> /dev/null; then
    notify-send "$title" "$message"
  else
    echo "[$title] $message"
  fi
}
