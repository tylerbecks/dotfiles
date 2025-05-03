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

# Create a new directory and move into it
function mkcd() {
  mkdir -p "$1" && cd "$1"
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