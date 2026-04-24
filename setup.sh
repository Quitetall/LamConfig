#!/usr/bin/env bash
set -euo pipefail

# ╔═══════════════════════════════════════════════════════╗
# ║  LamConfig Setup — Full System Bootstrap             ║
# ║  Modular installer for any Linux distro              ║
# ╚═══════════════════════════════════════════════════════╝

# ── Colors ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "${CYAN}[*]${NC} $1"; }
ok()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[-]${NC} $1"; }
header() { echo -e "\n${BOLD}${CYAN}═══ $1 ═══${NC}\n"; }

# ── Distro detection ──────────────────────────────────────
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            arch|cachyos|endeavouros|manjaro|garuda|artix)
                DISTRO="arch" ;;
            ubuntu|debian|pop|linuxmint|elementary|zorin)
                DISTRO="debian" ;;
            fedora|nobara|ultramarine)
                DISTRO="fedora" ;;
            opensuse*|sles)
                DISTRO="suse" ;;
            void)
                DISTRO="void" ;;
            *)
                warn "Unknown distro: $ID. Attempting Arch-style install."
                DISTRO="arch" ;;
        esac
    else
        fail "Cannot detect distro"
        exit 1
    fi
    ok "Detected: $PRETTY_NAME ($DISTRO family)"
}

# ── Package manager abstraction ───────────────────────────
pkg_install() {
    case "$DISTRO" in
        arch)
            if command -v paru &>/dev/null; then
                paru -S --needed --noconfirm "$@" 2>/dev/null || true
            elif command -v yay &>/dev/null; then
                yay -S --needed --noconfirm "$@" 2>/dev/null || true
            else
                sudo pacman -S --needed --noconfirm "$@" 2>/dev/null || true
            fi
            ;;
        debian)
            sudo apt-get update -qq
            sudo apt-get install -y "$@" 2>/dev/null || true
            ;;
        fedora)
            sudo dnf install -y "$@" 2>/dev/null || true
            ;;
        suse)
            sudo zypper install -y "$@" 2>/dev/null || true
            ;;
        void)
            sudo xbps-install -Sy "$@" 2>/dev/null || true
            ;;
    esac
}

# Map package names across distros
# Usage: pkg_name "arch_name" "debian_name" "fedora_name"
pkg_map() {
    case "$DISTRO" in
        arch)   echo "$1" ;;
        debian) echo "${2:-$1}" ;;
        fedora) echo "${3:-${2:-$1}}" ;;
        *)      echo "$1" ;;
    esac
}

# ── AUR helper install (Arch only) ────────────────────────
install_aur_helper() {
    if [[ "$DISTRO" != "arch" ]]; then return; fi
    if command -v paru &>/dev/null || command -v yay &>/dev/null; then
        ok "AUR helper already installed"
        return
    fi
    info "Installing paru (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    ok "paru installed"
}

# ── Flatpak setup (non-Arch fallback for GUI apps) ────────
ensure_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        info "Installing Flatpak..."
        pkg_install flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════
#  CATEGORY 1: Core CLI Tools
# ══════════════════════════════════════════════════════════
install_cli_tools() {
    header "Core CLI Tools"

    local pkgs=(
        # Essentials
        $(pkg_map "git" "git" "git")
        $(pkg_map "curl" "curl" "curl")
        $(pkg_map "wget" "wget" "wget")
        $(pkg_map "unzip" "unzip" "unzip")
        $(pkg_map "zip" "zip" "zip")
        $(pkg_map "tar" "tar" "tar")
        $(pkg_map "htop" "htop" "htop")
        $(pkg_map "tree" "tree" "tree")
        $(pkg_map "jq" "jq" "jq")

        # Modern replacements
        $(pkg_map "neovim" "neovim" "neovim")
        $(pkg_map "tmux" "tmux" "tmux")
        $(pkg_map "zsh" "zsh" "zsh")
        $(pkg_map "fzf" "fzf" "fzf")
        $(pkg_map "ripgrep" "ripgrep" "ripgrep")
        $(pkg_map "fd" "fd" "fd-find")
        $(pkg_map "bat" "bat" "bat")
        $(pkg_map "eza" "eza" "eza")
        $(pkg_map "git-delta" "git-delta" "git-delta")
        $(pkg_map "zoxide" "zoxide" "zoxide")
        $(pkg_map "btop" "btop" "btop")
        $(pkg_map "fastfetch" "fastfetch" "fastfetch")
        $(pkg_map "stow" "stow" "stow")
        $(pkg_map "lazygit" "lazygit" "lazygit")

        # Compression
        $(pkg_map "p7zip" "p7zip-full" "p7zip")
        $(pkg_map "zstd" "zstd" "zstd")

        # Networking
        $(pkg_map "openssh" "openssh-client" "openssh-clients")
        $(pkg_map "rsync" "rsync" "rsync")
    )

    info "Installing ${#pkgs[@]} packages..."
    pkg_install "${pkgs[@]}"

    # gh CLI (GitHub)
    if ! command -v gh &>/dev/null; then
        info "Installing GitHub CLI..."
        case "$DISTRO" in
            arch)   pkg_install github-cli ;;
            debian)
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                sudo apt-get update -qq && sudo apt-get install -y gh
                ;;
            fedora) sudo dnf install -y gh ;;
        esac
    fi

    ok "CLI tools installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY 2: Dev / Programming
# ══════════════════════════════════════════════════════════
install_dev() {
    header "Development Tools"

    # Build essentials
    info "Installing build tools..."
    case "$DISTRO" in
        arch)   pkg_install base-devel cmake ninja gdb lldb clang lld ;;
        debian) pkg_install build-essential cmake ninja-build gdb lldb clang lld ;;
        fedora) pkg_install gcc gcc-c++ make cmake ninja-build gdb lldb clang lld ;;
    esac

    # Python
    info "Installing Python..."
    case "$DISTRO" in
        arch)   pkg_install python python-pip python-virtualenv ;;
        debian) pkg_install python3 python3-pip python3-venv python3-dev ;;
        fedora) pkg_install python3 python3-pip python3-virtualenv python3-devel ;;
    esac

    ok "Dev tools installed"
}

install_toolchain_rust() {
    header "Rust Toolchain"
    if command -v rustup &>/dev/null; then
        ok "Rust already installed ($(rustc --version))"
        rustup update
    else
        info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    ok "Rust ready"
}

install_toolchain_node() {
    header "Node.js Toolchain"
    if command -v node &>/dev/null; then
        ok "Node already installed ($(node --version))"
    else
        info "Installing Node.js via nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
        nvm install --lts
    fi
    # npm global dir (no sudo needed)
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
    ok "Node ready"
}

install_toolchain_go() {
    header "Go Toolchain"
    if command -v go &>/dev/null; then
        ok "Go already installed ($(go version))"
    else
        info "Installing Go..."
        pkg_install $(pkg_map "go" "golang" "golang")
    fi
    ok "Go ready"
}

install_claude_code() {
    header "Claude Code"
    if command -v claude &>/dev/null; then
        ok "Claude Code already installed"
        return
    fi
    if ! command -v npm &>/dev/null; then
        warn "Node.js required for Claude Code. Install Node first."
        return
    fi
    info "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code installed. Run 'claude' to authenticate."
}

# ══════════════════════════════════════════════════════════
#  CATEGORY 3: Productivity / GUI Apps
# ══════════════════════════════════════════════════════════
install_productivity() {
    header "Productivity & GUI Apps"

    case "$DISTRO" in
        arch)
            pkg_install \
                firefox \
                ghostty \
                discord \
                obsidian \
                vlc \
                mpv \
                obs-studio \
                flameshot \
                thunar \
                file-roller \
                wl-clipboard \
                xdg-utils \
                xdg-user-dirs
            # AUR packages
            if command -v paru &>/dev/null; then
                paru -S --needed --noconfirm \
                    visual-studio-code-bin \
                    zed-editor \
                    spotify \
                    2>/dev/null || true
            fi
            ;;
        debian)
            pkg_install \
                firefox \
                vlc \
                mpv \
                obs-studio \
                flameshot \
                thunar \
                file-roller \
                wl-clipboard \
                xdg-utils

            # Snap/Flatpak for apps not in apt
            ensure_flatpak
            flatpak install -y flathub com.discordapp.Discord 2>/dev/null || true
            flatpak install -y flathub md.obsidian.Obsidian 2>/dev/null || true
            flatpak install -y flathub com.spotify.Client 2>/dev/null || true
            ;;
        fedora)
            pkg_install \
                firefox \
                vlc \
                mpv \
                obs-studio \
                flameshot \
                thunar \
                file-roller \
                wl-clipboard \
                xdg-utils

            ensure_flatpak
            flatpak install -y flathub com.discordapp.Discord 2>/dev/null || true
            flatpak install -y flathub md.obsidian.Obsidian 2>/dev/null || true
            ;;
    esac

    ok "Productivity apps installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY 4: Gaming
# ══════════════════════════════════════════════════════════
install_gaming() {
    header "Gaming"

    case "$DISTRO" in
        arch)
            # Enable multilib if not already
            if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
                warn "Enabling multilib repository..."
                sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
                sudo pacman -Sy
            fi

            pkg_install \
                steam \
                lutris \
                wine-staging \
                wine-mono \
                wine-gecko \
                winetricks \
                gamemode \
                lib32-gamemode \
                mangohud \
                lib32-mangohud \
                lib32-vulkan-icd-loader \
                vulkan-tools \
                lib32-mesa \
                lib32-nvidia-utils \
                protonup-qt \
                gamescope

            # AUR gaming extras
            if command -v paru &>/dev/null; then
                paru -S --needed --noconfirm \
                    heroic-games-launcher-bin \
                    proton-ge-custom-bin \
                    2>/dev/null || true
            fi
            ;;
        debian)
            # Add 32-bit arch
            sudo dpkg --add-architecture i386
            sudo apt-get update -qq

            pkg_install \
                steam-installer \
                lutris \
                wine \
                winetricks \
                gamemode \
                mangohud \
                mesa-vulkan-drivers \
                mesa-vulkan-drivers:i386 \
                vulkan-tools

            ensure_flatpak
            flatpak install -y flathub com.heroicgameslauncher.hgl 2>/dev/null || true
            ;;
        fedora)
            # RPM Fusion
            sudo dnf install -y \
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
                2>/dev/null || true

            pkg_install \
                steam \
                lutris \
                wine \
                winetricks \
                gamemode \
                mangohud \
                vulkan-tools \
                gamescope

            ensure_flatpak
            flatpak install -y flathub com.heroicgameslauncher.hgl 2>/dev/null || true
            ;;
    esac

    ok "Gaming packages installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY 5: System / Drivers / Extras
# ══════════════════════════════════════════════════════════
install_system() {
    header "System Extras"

    case "$DISTRO" in
        arch)
            pkg_install \
                ttf-jetbrains-mono-nerd \
                ttf-firacode-nerd \
                inter-font \
                noto-fonts \
                noto-fonts-cjk \
                noto-fonts-emoji \
                reflector \
                pkgfile \
                man-db \
                man-pages \
                python-pynvim
            ;;
        debian)
            pkg_install \
                fonts-jetbrains-mono \
                fonts-firacode \
                fonts-noto \
                fonts-noto-cjk \
                fonts-noto-color-emoji \
                man-db \
                manpages-dev \
                python3-pynvim
            ;;
        fedora)
            pkg_install \
                jetbrains-mono-fonts \
                fira-code-fonts \
                google-noto-fonts-common \
                google-noto-cjk-fonts \
                google-noto-emoji-fonts \
                man-db \
                man-pages \
                python3-pynvim
            ;;
    esac

    # Refresh font cache
    fc-cache -f 2>/dev/null || true

    ok "System extras installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY 6: Dotfiles (configs)
# ══════════════════════════════════════════════════════════
install_dotfiles() {
    header "Dotfiles & Configs"

    local DOTFILES="$HOME/dotfiles"
    local REPO="https://github.com/Quitetall/LamConfig.git"

    if [[ -d "$DOTFILES" ]]; then
        info "Dotfiles exist, pulling latest..."
        git -C "$DOTFILES" pull
    else
        info "Cloning dotfiles..."
        git clone "$REPO" "$DOTFILES"
    fi

    # Run the existing install script
    if [[ -f "$DOTFILES/install.sh" ]]; then
        bash "$DOTFILES/install.sh"
    fi

    ok "Dotfiles installed"
}

# ══════════════════════════════════════════════════════════
#  Interactive Menu
# ══════════════════════════════════════════════════════════
show_menu() {
    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║          LamConfig — System Setup                    ║${NC}"
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}1)${NC}  Everything              ${DIM}(all categories below)${NC}"
    echo -e "  ${BOLD}2)${NC}  Dev / Programming        ${DIM}(CLI tools + build tools + editors)${NC}"
    echo -e "  ${BOLD}3)${NC}  Gaming                   ${DIM}(Steam, Lutris, Wine, Proton, MangoHud)${NC}"
    echo -e "  ${BOLD}4)${NC}  Productivity             ${DIM}(Firefox, Discord, OBS, Spotify, etc.)${NC}"
    echo -e "  ${BOLD}5)${NC}  System / Fonts / Extras   ${DIM}(Nerd fonts, Noto, man pages)${NC}"
    echo -e "  ${BOLD}6)${NC}  Dotfiles only             ${DIM}(clone & stow configs)${NC}"
    echo ""
    echo -e "  ${BOLD}Toolchains ${DIM}(add to any selection):${NC}"
    echo -e "  ${BOLD}r)${NC}  Rust         ${BOLD}n)${NC}  Node.js       ${BOLD}g)${NC}  Go"
    echo -e "  ${BOLD}c)${NC}  Claude Code  ${BOLD}a)${NC}  All toolchains"
    echo ""
    echo -e "  ${BOLD}0)${NC}  Exit"
    echo ""
}

# ══════════════════════════════════════════════════════════
#  CLI argument parsing
# ══════════════════════════════════════════════════════════
run_from_args() {
    local did_something=false

    for arg in "$@"; do
        case "$arg" in
            --all)
                install_aur_helper
                install_cli_tools
                install_dev
                install_toolchain_rust
                install_toolchain_node
                install_toolchain_go
                install_claude_code
                install_productivity
                install_gaming
                install_system
                install_dotfiles
                did_something=true
                ;;
            --dev)
                install_aur_helper
                install_cli_tools
                install_dev
                did_something=true
                ;;
            --gaming)       install_gaming; did_something=true ;;
            --productivity) install_productivity; did_something=true ;;
            --system)       install_system; did_something=true ;;
            --dotfiles)     install_dotfiles; did_something=true ;;
            --rust)         install_toolchain_rust; did_something=true ;;
            --node)         install_toolchain_node; did_something=true ;;
            --go)           install_toolchain_go; did_something=true ;;
            --claude)       install_claude_code; did_something=true ;;
            --help|-h)
                echo "Usage: setup.sh [OPTIONS]"
                echo ""
                echo "  --all            Install everything"
                echo "  --dev            CLI tools + build tools"
                echo "  --gaming         Steam, Lutris, Wine, Proton"
                echo "  --productivity   Firefox, Discord, OBS, Spotify"
                echo "  --system         Fonts, man pages, extras"
                echo "  --dotfiles       Clone & stow configs"
                echo "  --rust           Install Rust via rustup"
                echo "  --node           Install Node.js via nvm"
                echo "  --go             Install Go"
                echo "  --claude         Install Claude Code"
                echo ""
                echo "  No arguments = interactive menu"
                exit 0
                ;;
        esac
    done

    $did_something
}

# ══════════════════════════════════════════════════════════
#  Main
# ══════════════════════════════════════════════════════════
main() {
    detect_distro

    # If CLI args provided, run non-interactively
    if [[ $# -gt 0 ]]; then
        if run_from_args "$@"; then
            echo ""
            ok "Setup complete!"
            return
        fi
    fi

    # Interactive mode
    while true; do
        show_menu
        read -rp "  Select [1-6, r/n/g/c/a, 0 to exit]: " choice

        case "$choice" in
            1)
                install_aur_helper
                install_cli_tools
                install_dev
                install_toolchain_rust
                install_toolchain_node
                install_toolchain_go
                install_claude_code
                install_productivity
                install_gaming
                install_system
                install_dotfiles
                ;;
            2)
                install_aur_helper
                install_cli_tools
                install_dev
                install_dotfiles
                ;;
            3)  install_gaming ;;
            4)  install_productivity ;;
            5)  install_system ;;
            6)  install_dotfiles ;;
            r)  install_toolchain_rust ;;
            n)  install_toolchain_node ;;
            g)  install_toolchain_go ;;
            c)  install_claude_code ;;
            a)
                install_toolchain_rust
                install_toolchain_node
                install_toolchain_go
                install_claude_code
                ;;
            0|q|"")
                echo ""
                ok "Done. Open a new terminal to apply changes."
                exit 0
                ;;
            *)
                warn "Invalid choice: $choice"
                ;;
        esac

        echo ""
        ok "Category complete! Returning to menu..."
        echo ""
    done
}

main "$@"
