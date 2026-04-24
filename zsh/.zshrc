# ╔═══════════════════════════════════════════════════════╗
# ║                     ~/.zshrc                         ║
# ║             Kanagawa Dragon · CachyOS                ║
# ╚═══════════════════════════════════════════════════════╝

# ── Powerlevel10k instant prompt ──────────────────────────
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
# Must be at the very top, before any output.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Oh My Zsh ─────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search
  sudo           # press Esc twice to prepend sudo
  copypath       # copies current path to clipboard
  dirhistory     # Alt+Left/Right to navigate dir history
  extract        # universal `extract` command
  fzf            # fzf keybindings + completion
)

source $ZSH/oh-my-zsh.sh

# ── Environment ───────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"   # bat for man pages
export BAT_THEME="kanagawa"

# ── Path ──────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ── History ───────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE        # don't save commands starting with space
setopt SHARE_HISTORY            # share history across sessions
setopt EXTENDED_HISTORY         # save timestamps

# ── Autosuggestion style ──────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#626462"   # dragonGray - subtle
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── Syntax highlighting ───────────────────────────────────
# Kanagawa Dragon colors for zsh-syntax-highlighting
ZSH_HIGHLIGHT_STYLES[command]="fg=#7fb4ca"           # crystalBlue
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#7fb4ca"
ZSH_HIGHLIGHT_STYLES[function]="fg=#7fb4ca"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#7fb4ca,bold"
ZSH_HIGHLIGHT_STYLES[path]="fg=#8a9a7b,underline"   # springGreen
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="fg=#c4b28a"  # carpYellow
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="fg=#c4b28a"
ZSH_HIGHLIGHT_STYLES[redirection]="fg=#a292a3"       # oniViolet
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#c4746e,bold" # samuraiRed
ZSH_HIGHLIGHT_STYLES[comment]="fg=#626462,italic"    # dragonGray

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

# ── Key bindings ──────────────────────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^H' backward-kill-word          # Ctrl+Backspace
bindkey '^[[1;5C' forward-word           # Ctrl+Right
bindkey '^[[1;5D' backward-word          # Ctrl+Left

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
alias ~='cd ~'

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

# System tools
alias top='btop'
alias htop='btop'
alias ff='fastfetch'
alias fetch='fastfetch'
alias sysinfo='fastfetch'

# CachyOS / Arch package management
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias pkginfo='pacman -Qi'
alias orphans='pacman -Qdtq'
alias clean='sudo pacman -Sc'

# ── Functions ─────────────────────────────────────────────
# mkdir + cd in one
mkcd() { mkdir -p "$1" && cd "$1" }

# Quick edit configs
conf() {
  case "$1" in
    zsh)      $EDITOR ~/.zshrc ;;
    p10k)     $EDITOR ~/.p10k.zsh ;;
    ghostty)  $EDITOR ~/.config/ghostty/config ;;
    nvim)     $EDITOR ~/.config/nvim/init.lua ;;
    btop)     $EDITOR ~/.config/btop/btop.conf ;;
    fetch)    $EDITOR ~/.config/fastfetch/config.jsonc ;;
    *)        echo "Unknown config: $1" ;;
  esac
}

# ── Powerlevel10k config ───────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
