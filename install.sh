#!/usr/bin/env bash
set -euo pipefail

# ╔═══════════════════════════════════════════════════════╗
# ║  LamConfig Installer                                 ║
# ║  Clone → install deps → stow → ready                ║
# ╚═══════════════════════════════════════════════════════╝

DOTFILES="$HOME/dotfiles"
REPO="https://github.com/Quitetall/LamConfig.git"

# ── Colors ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[-]${NC} $1"; exit 1; }

# ── Detect package manager ────────────────────────────────
install_pkg() {
    if command -v paru &>/dev/null; then
        paru -S --needed --noconfirm "$@"
    elif command -v yay &>/dev/null; then
        yay -S --needed --noconfirm "$@"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --needed --noconfirm "$@"
    elif command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y "$@"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$@"
    elif command -v brew &>/dev/null; then
        brew install "$@"
    else
        fail "No supported package manager found"
    fi
}

# ── Clone repo ────────────────────────────────────────────
if [[ -d "$DOTFILES" ]]; then
    info "Dotfiles already exist at $DOTFILES, pulling latest..."
    git -C "$DOTFILES" pull
else
    info "Cloning $REPO..."
    git clone "$REPO" "$DOTFILES"
fi

cd "$DOTFILES"

# ── Install dependencies ─────────────────────────────────
info "Installing core packages..."

PACKAGES=(
    neovim
    tmux
    zsh
    git
    stow
    fzf
    ripgrep
    fd
    bat
    eza
    delta
    zoxide
    lazygit
    btop
    fastfetch
)

install_pkg "${PACKAGES[@]}" || warn "Some packages may not be available on this distro"

# ── Install Oh My Zsh ─────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    ok "Oh My Zsh already installed"
fi

# ── Install zsh plugins ──────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]]; then
    info "Installing zsh-history-substring-search..."
    git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
fi

if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# ── Install TPM (tmux plugin manager) ────────────────────
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ── Backup existing configs ──────────────────────────────
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
BACKED_UP=false

backup_if_exists() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        if [[ "$BACKED_UP" == false ]]; then
            mkdir -p "$BACKUP_DIR"
            BACKED_UP=true
        fi
        warn "Backing up $target -> $BACKUP_DIR/"
        mv "$target" "$BACKUP_DIR/"
    elif [[ -L "$target" ]]; then
        rm -f "$target"
    fi
}

info "Checking for existing configs to backup..."
backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.p10k.zsh"
backup_if_exists "$HOME/.gitconfig"
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.config/tmux/tmux.conf"
backup_if_exists "$HOME/.config/ghostty/config"
backup_if_exists "$HOME/.config/fastfetch/config.jsonc"
backup_if_exists "$HOME/.config/fastfetch/dragon.png"
backup_if_exists "$HOME/.config/btop/btop.conf"
backup_if_exists "$HOME/.config/zed/settings.json"
backup_if_exists "$HOME/.config/zed/keymap.json"

if [[ "$BACKED_UP" == true ]]; then
    ok "Old configs backed up to $BACKUP_DIR"
fi

# ── Create target directories ────────────────────────────
mkdir -p "$HOME/.config"/{nvim,tmux,ghostty,fastfetch,btop,zed}

# ── Stow all packages ────────────────────────────────────
info "Stowing configs..."

STOW_PACKAGES=(nvim tmux zsh git ghostty fastfetch btop zed)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ -d "$DOTFILES/$pkg" ]]; then
        stow -d "$DOTFILES" -t "$HOME" "$pkg" && ok "Stowed $pkg"
    fi
done

# ── Install bat kanagawa theme ───────────────────────────
info "Setting up bat theme..."
mkdir -p "$(bat --config-dir 2>/dev/null || echo "$HOME/.config/bat")/themes"

# Theme will be available after first nvim launch installs kanagawa.nvim
# For now, set a fallback
if command -v bat &>/dev/null; then
    bat cache --build &>/dev/null || true
fi

# ── Install tmux plugins ─────────────────────────────────
info "Installing tmux plugins..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins" &>/dev/null || warn "Run tmux, then press Ctrl+Space Shift+I to install plugins"

# ── Set zsh as default shell ─────────────────────────────
if [[ "$SHELL" != */zsh ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)" || warn "Run: chsh -s $(which zsh)"
fi

# ── Summary ───────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  LamConfig installed!                                ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Next steps:"
echo "    1. Open a new terminal (or run: exec zsh)"
echo "    2. Run: nvim (wait for plugins to install)"
echo "    3. Run: tmux (press Ctrl+Space Shift+I for plugins)"
echo ""
if [[ "$BACKED_UP" == true ]]; then
    echo -e "  ${YELLOW}Old configs saved to: $BACKUP_DIR${NC}"
    echo ""
fi
