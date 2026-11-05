# fnm (Linux boxes; mise covers Node on the Mac). Switches to the version a
# project pins in .nvmrc / .node-version on cd, and otherwise uses fnm's default.
if command -v fnm &> /dev/null; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi
