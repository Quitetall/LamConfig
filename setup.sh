#!/usr/bin/env bash
set -euo pipefail

# ╔═══════════════════════════════════════════════════════╗
# ║  LamConfig Setup — Full System Bootstrap             ║
# ║  Usage: setup.sh [--all] [--dev] [--gaming] ...     ║
# ║         setup.sh --cli=lightweight|standard|extended ║
# ╚═══════════════════════════════════════════════════════╝

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/pkgmap.sh"

# CLI tier selection (default: standard)
CLI_TIER="${CLI_TIER:-standard}"

# ══════════════════════════════════════════════════════════
#  CATEGORY: Core CLI Tools  (tiered)
# ══════════════════════════════════════════════════════════
#
#  lightweight — bare minimum on any machine
#  standard    — comfortable power-user setup  (default)
#  extended    — full comfort / rarely needed extras

CLI_LIGHTWEIGHT=(
    git curl wget zsh
    neovim tmux
    fzf ripgrep fd bat eza zoxide
    jq stow openssh rsync
    less tar unzip zip
)

CLI_STANDARD=(
    "${CLI_LIGHTWEIGHT[@]}"
    # Git
    git-lfs git-delta github-cli
    # TUI / navigation
    lazygit yazi btop fastfetch
    # Misc tools
    tree p7zip zstd pv bind
)

CLI_EXTENDED=(
    "${CLI_STANDARD[@]}"
    # Extra editors
    vim micro
    # Alternative multiplexer
    zellij
    # Extra monitoring / search
    htop duf ugrep plocate
    # System utils
    perl diffutils which inetutils
    # Archive
    unrar
)

install_cli_tools() {
    header "Core CLI Tools  [tier: ${CLI_TIER}]"

    local -n tier_pkgs="CLI_${CLI_TIER^^}"
    pkgs_install "${tier_pkgs[@]}"

    ok "CLI tools installed (${CLI_TIER})"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY: Dev / Programming
# ══════════════════════════════════════════════════════════
install_dev() {
    header "Development Tools"

    # ── Build essentials ──────────────────────────────────
    info "Build tools..."
    case "$DISTRO" in
        arch)   pkg_install base-devel cmake ninja gdb lldb clang lld ccache mold ;;
        debian) pkg_install build-essential cmake ninja-build gdb lldb clang lld ccache mold ;;
        fedora) pkg_install gcc gcc-c++ make cmake ninja-build gdb lldb clang lld ccache mold ;;
    esac

    # ── Python ───────────────────────────────────────────
    info "Python..."
    case "$DISTRO" in
        arch)
            pkg_install python python-pip python-virtualenv python-pipx \
                        python-pynvim uv ;;
        debian)
            pkg_install python3 python3-pip python3-venv python3-dev \
                        python3-pynvim pipx ;;
        fedora)
            pkg_install python3 python3-pip python3-virtualenv python3-devel \
                        python3-pynvim pipx ;;
    esac

    # ── Dev utilities ─────────────────────────────────────
    info "Dev utilities..."
    pkgs_install hyperfine just meld

    # ── Containers ───────────────────────────────────────
    info "Containers..."
    case "$DISTRO" in
        arch)   pkg_install podman-docker podman-compose lazydocker ;;
        debian) pkg_install podman podman-compose ;;
        fedora) pkg_install podman podman-compose ;;
    esac

    # ── Virtualization ───────────────────────────────────
    info "Virtualization..."
    pkgs_install virt-manager

    # ── Embedded / RISC-V ────────────────────────────────
    info "Embedded toolchains..."
    case "$DISTRO" in
        arch)
            pkg_install riscv64-elf-gcc riscv64-elf-newlib valgrind openocd ;;
        debian)
            pkg_install gcc-riscv64-unknown-elf valgrind openocd ;;
        fedora)
            pkg_install gcc-riscv64-linux-gnu valgrind openocd ;;
    esac

    # ── CUDA (Arch + NVIDIA only) ─────────────────────────
    if [[ "$DISTRO" == "arch" ]]; then
        info "CUDA..."
        pkg_install cuda 2>/dev/null || warn "CUDA install failed — needs nvidia driver"
    fi

    # ── .NET ─────────────────────────────────────────────
    info ".NET..."
    pkgs_install dotnet-sdk dotnet-runtime

    # ── PyTorch (Arch system packages) ───────────────────
    if [[ "$DISTRO" == "arch" ]]; then
        info "PyTorch..."
        pkg_install python-pytorch-cuda 2>/dev/null || pkg_install python-pytorch
    fi

    # ── Cloud / AI ───────────────────────────────────────
    info "Cloud + AI tools..."
    case "$DISTRO" in
        arch)   pkg_install aws-cli s3cmd s5cmd-bin ;;
        *)      pkg_install awscli s3cmd ;;
    esac
    pkgs_install ollama

    ok "Dev tools installed"
}

# ══════════════════════════════════════════════════════════
#  TOOLCHAINS
# ══════════════════════════════════════════════════════════
install_toolchain_rust() {
    header "Rust Toolchain"
    if command -v rustup &>/dev/null; then
        ok "Rust already installed — updating..."
        rustup update 2>/dev/null || true
        return
    fi
    case "$DISTRO" in
        arch) pkg_install rustup && rustup default stable ;;
        *)    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y ;;
    esac
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    ok "Rust ready"
}

install_toolchain_node() {
    header "Node.js Toolchain"
    if command -v node &>/dev/null; then
        ok "Node already installed ($(node --version))"
    else
        case "$DISTRO" in
            arch) pkg_install nodejs npm ;;
            *)
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
                export NVM_DIR="$HOME/.nvm"
                [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
                nvm install --lts ;;
        esac
    fi
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global" 2>/dev/null || true
    ok "Node ready"
}

install_toolchain_go() {
    header "Go Toolchain"
    if command -v go &>/dev/null; then
        ok "Go already installed ($(go version))"
    else
        pkgs_install go
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
        warn "Node.js required — install Node first (option n)"
        return
    fi
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code installed — run 'claude' to authenticate"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY: Productivity / GUI Apps
# ══════════════════════════════════════════════════════════
install_productivity() {
    header "Productivity & GUI Apps"

    case "$DISTRO" in
        arch)
            # Browsers
            pkg_install firefox
            pkg_install torbrowser-launcher 2>/dev/null || true

            # Terminals + editors
            pkg_install ghostty zed

            # Communication
            pkg_install vesktop 2>/dev/null || pkg_install discord

            # Notes + study
            pkg_install obsidian anki

            # Office
            pkg_install libreoffice-fresh

            # Media
            pkg_install vlc mpv obs-studio audacity
            pkg_install spotify-launcher 2>/dev/null || true

            # Creative
            pkg_install gimp inkscape krita kdenlive blender

            # Desktop utilities
            pkg_install \
                flameshot spectacle \
                ark thunar dolphin \
                wl-clipboard xdg-utils xdg-user-dirs

            # Dev GUI
            pkg_install bruno-bin 2>/dev/null || true
            ;;

        debian|fedora)
            pkg_install \
                firefox vlc mpv obs-studio audacity \
                gimp inkscape krita kdenlive blender \
                libreoffice flameshot thunar dolphin \
                ark wl-clipboard xdg-utils

            ensure_flatpak
            flatpak install -y flathub com.discordapp.Discord    2>/dev/null || true
            flatpak install -y flathub md.obsidian.Obsidian      2>/dev/null || true
            flatpak install -y flathub com.spotify.Client        2>/dev/null || true
            flatpak install -y flathub net.ankiweb.Anki          2>/dev/null || true
            flatpak install -y flathub io.usebruno.Bruno         2>/dev/null || true
            ;;
    esac

    ok "Productivity apps installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY: Gaming
# ══════════════════════════════════════════════════════════
install_gaming() {
    header "Gaming"

    case "$DISTRO" in
        arch)
            # Enable multilib
            if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
                warn "Enabling multilib..."
                sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
                sudo pacman -Sy
            fi

            # Core gaming stack
            pkg_install \
                steam lutris \
                wine-staging wine-mono wine-gecko winetricks \
                gamemode lib32-gamemode \
                mangohud lib32-mangohud \
                gamescope

            # GPU / Vulkan
            pkg_install \
                vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools \
                nvidia-utils nvidia-settings opencl-nvidia \
                lib32-nvidia-utils lib32-opencl-nvidia \
                libva-nvidia-driver egl-wayland

            pkg_install vulkan-intel lib32-vulkan-intel 2>/dev/null || true

            # AUR extras
            pkg_install \
                proton-ge-custom-bin \
                heroic-games-launcher-bin \
                protonup-qt \
                prismlauncher \
                2>/dev/null || true
            ;;

        debian)
            sudo dpkg --add-architecture i386
            sudo apt-get update -qq
            pkg_install \
                steam-installer lutris \
                wine winetricks \
                gamemode mangohud \
                mesa-vulkan-drivers vulkan-tools

            ensure_flatpak
            flatpak install -y flathub com.heroicgameslauncher.hgl 2>/dev/null || true
            flatpak install -y flathub org.prismlauncher.PrismLauncher 2>/dev/null || true
            ;;

        fedora)
            # RPM Fusion
            sudo dnf install -y \
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
                2>/dev/null || true

            pkg_install steam lutris wine winetricks gamemode mangohud vulkan-tools gamescope

            ensure_flatpak
            flatpak install -y flathub com.heroicgameslauncher.hgl 2>/dev/null || true
            flatpak install -y flathub org.prismlauncher.PrismLauncher 2>/dev/null || true
            ;;
    esac

    ok "Gaming packages installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY: System / Fonts / Hardware
# ══════════════════════════════════════════════════════════
install_system() {
    header "System, Fonts & Hardware"

    # ── Fonts ─────────────────────────────────────────────
    info "Fonts..."
    case "$DISTRO" in
        arch)
            pkg_install \
                ttf-jetbrains-mono-nerd ttf-meslo-nerd otf-monaspace-nerdfonts \
                ttf-intel-one-mono inter-font \
                ttf-dejavu ttf-liberation \
                noto-fonts noto-fonts-cjk noto-fonts-emoji \
                cantarell-fonts papirus-icon-theme phinger-cursors
            ;;
        debian)
            pkg_install \
                fonts-jetbrains-mono fonts-firacode fonts-noto \
                fonts-noto-cjk fonts-noto-color-emoji \
                fonts-dejavu fonts-liberation papirus-icon-theme
            ;;
        fedora)
            pkg_install \
                jetbrains-mono-fonts fira-code-fonts \
                google-noto-fonts-common google-noto-cjk-fonts \
                google-noto-emoji-fonts dejavu-sans-fonts \
                liberation-fonts papirus-icon-theme
            ;;
    esac
    fc-cache -f 2>/dev/null || true

    # ── System tools ──────────────────────────────────────
    info "System tools..."
    case "$DISTRO" in
        arch)
            pkg_install \
                man-db man-pages bash-completion \
                reflector pkgfile pacman-contrib \
                smartmontools hdparm dmidecode usbutils \
                fwupd upower cpupower power-profiles-daemon \
                lsb-release hwinfo
            ;;
        debian)
            pkg_install \
                man-db bash-completion \
                smartmontools hdparm dmidecode usbutils \
                fwupd upower power-profiles-daemon lsb-release
            ;;
        fedora)
            pkg_install \
                man-db bash-completion \
                smartmontools hdparm dmidecode usbutils \
                fwupd upower kernel-tools power-profiles-daemon
            ;;
    esac

    # ── Bluetooth ────────────────────────────────────────
    info "Bluetooth..."
    case "$DISTRO" in
        arch)   pkg_install bluez bluez-utils bluez-libs bluez-obex ;;
        debian) pkg_install bluez bluez-tools libbluetooth-dev ;;
        fedora) pkg_install bluez bluez-tools bluez-libs-devel ;;
    esac

    # ── Audio (PipeWire) ─────────────────────────────────
    info "Audio..."
    case "$DISTRO" in
        arch)   pkg_install pipewire-alsa pipewire-pulse wireplumber pavucontrol sof-firmware ;;
        debian) pkg_install pipewire pipewire-pulse wireplumber pavucontrol firmware-sof-signed ;;
        fedora) pkg_install pipewire pipewire-pulseaudio wireplumber pavucontrol ;;
    esac

    # ── Filesystems ──────────────────────────────────────
    info "Filesystem tools..."
    case "$DISTRO" in
        arch)
            pkg_install \
                btrfs-progs e2fsprogs xfsprogs \
                ntfs-3g exfatprogs dosfstools \
                lvm2 cryptsetup mdadm
            ;;
        debian|fedora)
            pkg_install \
                btrfs-progs e2fsprogs xfsprogs \
                ntfs-3g exfatprogs dosfstools \
                lvm2 cryptsetup mdadm
            ;;
    esac

    # Btrfs snapshots (Arch)
    [[ "$DISTRO" == "arch" ]] && \
        pkg_install snapper btrfs-assistant 2>/dev/null || true

    # ── Networking ───────────────────────────────────────
    info "Network tools..."
    case "$DISTRO" in
        arch)
            pkg_install \
                networkmanager networkmanager-openvpn \
                iwd nss-mdns dnsmasq tailscale ufw \
                modemmanager ethtool
            ;;
        debian)
            pkg_install \
                network-manager network-manager-openvpn \
                nss-mdns dnsmasq tailscale ufw \
                modemmanager ethtool
            ;;
        fedora)
            pkg_install \
                NetworkManager NetworkManager-openvpn \
                nss-mdns dnsmasq tailscale firewalld \
                ModemManager ethtool
            ;;
    esac

    # ── Audio / Video codecs ─────────────────────────────
    info "Multimedia codecs..."
    case "$DISTRO" in
        arch)
            pkg_install \
                gst-libav gst-plugin-pipewire \
                gst-plugins-bad gst-plugins-ugly \
                ffmpegthumbnailer poppler-glib \
                opus-tools intel-media-sdk libva-utils
            ;;
        debian)
            pkg_install gstreamer1.0-libav gstreamer1.0-plugins-bad \
                        gstreamer1.0-plugins-ugly ffmpegthumbnailer 2>/dev/null || true
            ;;
        fedora)
            pkg_install gstreamer1-plugin-libav gstreamer1-plugins-bad-free \
                        gstreamer1-plugins-ugly ffmpegthumbnailer
            ;;
    esac

    # ── KDE extras (Arch) ────────────────────────────────
    if [[ "$DISTRO" == "arch" ]]; then
        info "KDE extras..."
        pkg_install \
            plasma-desktop plasma-nm plasma-pa plasma-systemmonitor \
            powerdevil kinfocenter kscreen \
            kde-gtk-config breeze-gtk \
            kdeconnect kwallet-pam kwalletmanager \
            kdeplasma-addons kdegraphics-thumbnailers \
            discover partitionmanager kio-admin konsole \
            2>/dev/null || true
    fi

    # ── Wayland ──────────────────────────────────────────
    pkgs_install wayland-protocols

    # ── Printing ─────────────────────────────────────────
    info "Printing..."
    pkg_install cups cups-filters ghostscript system-config-printer
    [[ "$DISTRO" == "arch" ]] && \
        pkg_install gutenprint foomatic-db foomatic-db-engine \
            foomatic-db-ppds foomatic-db-nonfree 2>/dev/null || true

    # ── QMK (keyboard firmware) ──────────────────────────
    pkgs_install qmk 2>/dev/null || true

    ok "System extras installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY: Dotfiles
# ══════════════════════════════════════════════════════════
install_dotfiles() {
    header "Dotfiles & Configs"

    local DOTFILES="$HOME/dotfiles"
    local REPO="https://github.com/Quitetall/LamConfig.git"

    if [[ -d "$DOTFILES" ]]; then
        info "Dotfiles exist — pulling latest..."
        git -C "$DOTFILES" pull
    else
        info "Cloning dotfiles..."
        git clone "$REPO" "$DOTFILES"
    fi

    [[ -f "$DOTFILES/install.sh" ]] && bash "$DOTFILES/install.sh"

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
    echo -e "  ${BOLD}1)${NC}  Everything               ${DIM}(all categories)${NC}"
    echo -e "  ${BOLD}2)${NC}  Dev / Programming         ${DIM}(build, containers, embedded, AI)${NC}"
    echo -e "  ${BOLD}3)${NC}  Gaming                    ${DIM}(Steam, Lutris, Wine, Proton, MangoHud)${NC}"
    echo -e "  ${BOLD}4)${NC}  Productivity              ${DIM}(browsers, editors, creative, media)${NC}"
    echo -e "  ${BOLD}5)${NC}  System / Fonts / Hardware  ${DIM}(fonts, drivers, bluetooth, KDE)${NC}"
    echo -e "  ${BOLD}6)${NC}  Dotfiles only              ${DIM}(clone & stow configs)${NC}"
    echo ""
    echo -e "  ${BOLD}CLI tier  [current: ${CLI_TIER}]:${NC}"
    echo -e "  ${BOLD}L)${NC}  Lightweight  ${DIM}(git, zsh, nvim, tmux, fzf, ripgrep, bat, eza…)${NC}"
    echo -e "  ${BOLD}S)${NC}  Standard     ${DIM}(+ lazygit, yazi, btop, delta, gh, fastfetch…)${NC}"
    echo -e "  ${BOLD}E)${NC}  Extended     ${DIM}(+ zellij, htop, duf, micro, plocate, ugrep…)${NC}"
    echo ""
    echo -e "  ${BOLD}Toolchains:${NC}  ${BOLD}r)${NC} Rust  ${BOLD}n)${NC} Node  ${BOLD}g)${NC} Go  ${BOLD}c)${NC} Claude  ${BOLD}a)${NC} All"
    echo ""
    echo -e "  ${BOLD}0)${NC}  Exit"
    echo ""
}

# ══════════════════════════════════════════════════════════
#  CLI Argument Parsing
# ══════════════════════════════════════════════════════════
parse_args() {
    for arg in "$@"; do
        case "$arg" in
            --cli=lightweight) CLI_TIER="lightweight" ;;
            --cli=standard)    CLI_TIER="standard" ;;
            --cli=extended)    CLI_TIER="extended" ;;
            --dry-run)         DRY_RUN=1; info "Dry-run mode enabled — nothing will be installed" ;;
        esac
    done
}

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
                did_something=true ;;
            --dev)
                install_aur_helper
                install_cli_tools
                install_dev
                did_something=true ;;
            --gaming)       install_gaming;       did_something=true ;;
            --productivity) install_productivity; did_something=true ;;
            --system)       install_system;       did_something=true ;;
            --dotfiles)     install_dotfiles;     did_something=true ;;
            --rust)         install_toolchain_rust;  did_something=true ;;
            --node)         install_toolchain_node;  did_something=true ;;
            --go)           install_toolchain_go;    did_something=true ;;
            --claude)       install_claude_code;     did_something=true ;;
            --cli=*|--dry-run) ;;  # already parsed
            --help|-h)
                cat <<EOF
Usage: setup.sh [OPTIONS]

  --all              Install everything
  --dev              CLI tools + build tools + containers + embedded
  --gaming           Steam, Lutris, Wine, Proton, MangoHud
  --productivity     Browsers, editors, creative, media
  --system           Fonts, drivers, bluetooth, printing, KDE
  --dotfiles         Clone & stow configs

  --cli=lightweight  Minimal CLI tools
  --cli=standard     Power-user CLI tools (default)
  --cli=extended     Full comfort set

  Toolchains:
  --rust             Rust via rustup
  --node             Node.js via nvm/pacman
  --go               Go
  --claude           Claude Code (requires Node)

  --dry-run          Show what would be installed without installing

  No arguments → interactive menu
EOF
                exit 0 ;;
        esac
    done

    $did_something
}

# ══════════════════════════════════════════════════════════
#  Main
# ══════════════════════════════════════════════════════════
main() {
    parse_args "$@"
    detect_distro

    if [[ $# -gt 0 ]]; then
        if run_from_args "$@"; then
            echo ""
            ok "Setup complete!"
            return
        fi
    fi

    while true; do
        show_menu
        read -rp "  Select: " choice

        case "$choice" in
            1)
                install_aur_helper
                install_cli_tools; install_dev
                install_toolchain_rust; install_toolchain_node
                install_toolchain_go; install_claude_code
                install_productivity; install_gaming
                install_system; install_dotfiles ;;
            2)
                install_aur_helper
                install_cli_tools; install_dev ;;
            3)  install_gaming ;;
            4)  install_productivity ;;
            5)  install_system ;;
            6)  install_dotfiles ;;
            L|l) CLI_TIER="lightweight"; info "CLI tier → lightweight" ;;
            S|s) CLI_TIER="standard";   info "CLI tier → standard" ;;
            E|e) CLI_TIER="extended";   info "CLI tier → extended" ;;
            r)  install_toolchain_rust ;;
            n)  install_toolchain_node ;;
            g)  install_toolchain_go ;;
            c)  install_claude_code ;;
            a)
                install_toolchain_rust; install_toolchain_node
                install_toolchain_go; install_claude_code ;;
            0|q|"") echo ""; ok "Done."; exit 0 ;;
            *)  warn "Invalid: $choice" ;;
        esac

        echo ""
        ok "Done — returning to menu..."
        echo ""
    done
}

main "$@"
