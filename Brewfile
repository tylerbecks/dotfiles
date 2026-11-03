# Homebrew packages and apps, installed by brew.sh with `brew bundle`.
# `brew bundle check` lists anything missing; `brew bundle cleanup` lists
# anything installed with Homebrew that isn't here.

# Mirrors lib/profile.sh. brew.sh passes its result as HOMEBREW_DOTFILES_PROFILE
# because brew drops environment variables that don't start with HOMEBREW_.
work = ENV.fetch("HOMEBREW_DOTFILES_PROFILE") { File.directory?("/var/facebook") ? "work" : "personal" } == "work"

# Work laptops preinstall some apps outside Homebrew, and installing the cask on
# top of them fails, so skip a cask when its app exists but Homebrew didn't
# install it.
def app(name, app_name)
  installed_elsewhere = File.exist?("/Applications/#{app_name}.app") &&
                        !File.directory?("#{HOMEBREW_PREFIX}/Caskroom/#{name}")
  cask name unless installed_elsewhere
end

# Core utilities
brew "coreutils"
brew "gnu-sed"
brew "bash"
brew "bash-completion@2"
brew "grep"

# Development
brew "mise"
brew "gh"
brew "difftastic"
brew "git-delta"
brew "shellcheck"
brew "rtk" unless work

# CLI tools
brew "ack"
brew "fd"
brew "ripgrep"
brew "fzf"
brew "jq"
brew "bat"
brew "eza"
brew "zoxide"
brew "btop"
brew "starship"
brew "smudge/smudge/nightlight"
brew "mas"

# Apps
app "cleanshot", "CleanShot X"
app "raycast", "Raycast"
app "logi-options+", "logioptionsplus"
app "thebrowsercompany-dia", "Dia"
app "wezterm", "WezTerm"
app "1password", "1Password"
cask "1password-cli"
app "slack", "Slack"
app "zoom", "zoom.us"
app "spotify", "Spotify"
cask "font-meslo-lg-nerd-font"

unless work
  app "visual-studio-code", "Visual Studio Code"
  app "claude", "Claude"
  cask "claude-code"
  app "dropbox", "Dropbox"
  app "whatsapp", "WhatsApp"
end

mas "Things 3", id: 904280696
