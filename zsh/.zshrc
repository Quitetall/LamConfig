# ╔═══════════════════════════════════════════════════════╗
# ║                     ~/.zshrc                         ║
# ║             Kanagawa Dragon · CachyOS                ║
# ╚═══════════════════════════════════════════════════════╝

# ── Powerlevel10k instant prompt ──────────────────────────
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Oh My Zsh ─────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  sudo
  copypath
  dirhistory
  extract
  fzf
)

source "$ZSH/oh-my-zsh.sh"

# ── Environment ───────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="kanagawa"

# ── Path (deduplicated) ──────────────────────────────────
typeset -U path
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.npm-global/bin"
  "$HOME/bin"
  $path
)

# ── History ───────────────────────────────────────────────
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# ── Completion ────────────────────────────────────────────
setopt AUTO_CD
setopt GLOB_DOTS
setopt INTERACTIVE_COMMENTS

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

# ── Autosuggestion style ──────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#626462"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── Syntax highlighting ───────────────────────────────────
ZSH_HIGHLIGHT_STYLES[command]="fg=#7fb4ca"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#7fb4ca"
ZSH_HIGHLIGHT_STYLES[function]="fg=#7fb4ca"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#7fb4ca,bold"
ZSH_HIGHLIGHT_STYLES[path]="fg=#8a9a7b,underline"
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#c4b28a"
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#c4b28a"
ZSH_HIGHLIGHT_STYLES[redirection]="fg=#a292a3"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#c4746e,bold"
ZSH_HIGHLIGHT_STYLES[comment]="fg=#626462,italic"

# ── fzf ───────────────────────────────────────────────────
export FZF_DEFAULT_OPTS="
  --color=bg+:#1e1e1e,bg:#0d0c0c,spinner:#c4746e,hl:#8a9a7b
  --color=fg:#c5c9c5,header:#7fb4ca,info:#a292a3,pointer:#c4746e
  --color=marker:#87a987,fg+:#dcd7ba,prompt:#7fb4ca,hl+:#e46876
  --border=rounded
  --prompt='  '
  --pointer=' '
  --marker='󰄬 '
  --height=40%
  --layout=reverse
"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"

# ── zoxide ────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── Key bindings ──────────────────────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^H' backward-kill-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ── Aliases ───────────────────────────────────────────────
# System
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias df='df -h'
alias du='du -sh'
alias mkdir='mkdir -p'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Dev
alias vim='nvim'
alias v='nvim'
alias g='git'
alias gc='git commit'
alias gst='git status'
alias gd='git diff'
alias gp='git push'
alias gl='git pull'
alias lg='lazygit'
alias cc='claude'

# System tools
alias top='btop'
alias htop='btop'
alias ff='fastfetch'

# CachyOS / Arch
alias update='paru -Syu'
alias install='paru -S'
alias remove='paru -Rns'
alias search='paru -Ss'
alias pkginfo='paru -Qi'
alias orphans='paru -Qdtq'
alias clean='paru -Sc'

# ── Functions ─────────────────────────────────────────────
mkcd() {
  mkdir -p "$1" && cd "$1"
}

conf() {
  case "$1" in
    zsh)     "$EDITOR" ~/.zshrc ;;
    p10k)    "$EDITOR" ~/.p10k.zsh ;;
    ghostty) "$EDITOR" ~/.config/ghostty/config ;;
    nvim)    "$EDITOR" ~/.config/nvim/init.lua ;;
    tmux)    "$EDITOR" ~/.config/tmux/tmux.conf ;;
    git)     "$EDITOR" ~/.gitconfig ;;
    btop)    "$EDITOR" ~/.config/btop/btop.conf ;;
    fetch)   "$EDITOR" ~/.config/fastfetch/config.jsonc ;;
    *)       echo "Usage: conf [zsh|p10k|ghostty|nvim|tmux|git|btop|fetch]" ;;
  esac
}

# ── Powerlevel10k config ──────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ── envman ────────────────────────────────────────────────
[[ -s "$HOME/.config/envman/load.sh" ]] && source "$HOME/.config/envman/load.sh"
