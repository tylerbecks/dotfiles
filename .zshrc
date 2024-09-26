# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export VOLTA_HOME="$HOME/.volta"
export PATH=$VOLTA_HOME/bin:/opt/homebrew/bin:$HOME/Library/pnpm:$PATH

# Path to your dotfiles.
export DOTFILES=$HOME/dotfiles

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf-tab zsh-syntax-highlighting zsh-autosuggestions)

# Silecne beep sounds from autocomplete
unsetopt BEEP

source $ZSH/oh-my-zsh.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure`
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# fzf-tab config
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# pnpm
export PNPM_HOME="/Users/tylerbecks/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

mg () { mkdir "$@" && cd "$@" || exit; }
cdl() { cd "$@" && ll; }
npm-latest() { npm info "$1" | grep latest; }
killport() { lsof -i tcp:"$*" | awk 'NR!=1 {print $2}' | xargs kill -9 ;}

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Custom Git Function: Automatically append '--ext-diff' to 'git show' and 'git log -p' commands.
# This ensures that Difftastic or any specified external diff tool is used for these commands,
# enhancing the diff display without needing to specify '--ext-diff' manually each time.
git() {
    if [[ $1 == "show" ]]; then
        command git "$@" --ext-diff
    elif [[ $1 == "log" && "$*" == *"-p"* ]]; then
        command git "$@" --ext-diff
    else
        command git "$@"
    fi
}

# setup 1password autocomplete
eval "$(op completion zsh)"; compdef _op op

# Github Copilot CLI alias
eval "$(gh copilot alias -- zsh)"

# ---- Eza (better ls) -----

alias ls="eza --icons=always --hyperlink"