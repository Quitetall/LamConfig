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
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return
    case "$DISTRO" in
        arch)
            if command -v paru &>/dev/null; then
                paru -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true
            elif command -v yay &>/dev/null; then
                yay -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true
            else
                sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true
            fi
            ;;
        debian)
            sudo apt-get update -qq
            sudo apt-get install -y "${pkgs[@]}" 2>/dev/null || true
            ;;
        fedora)
            sudo dnf install -y "${pkgs[@]}" 2>/dev/null || true
            ;;
        suse)
            sudo zypper install -y "${pkgs[@]}" 2>/dev/null || true
            ;;
        void)
            sudo xbps-install -Sy "${pkgs[@]}" 2>/dev/null || true
            ;;
    esac
}

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
#  CATEGORY: Core CLI Tools
# ══════════════════════════════════════════════════════════
install_cli_tools() {
    header "Core CLI Tools"

    # ── Essentials ──
    pkg_install \
        $(pkg_map git git git) \
        $(pkg_map curl curl curl) \
        $(pkg_map wget wget wget) \
        $(pkg_map less less less) \
        $(pkg_map which which which) \
        $(pkg_map diffutils diffutils diffutils) \
        $(pkg_map perl perl perl)

    # ── Compression ──
    pkg_install \
        $(pkg_map unzip unzip unzip) \
        $(pkg_map zip zip zip) \
        $(pkg_map tar tar tar) \
        $(pkg_map p7zip p7zip-full p7zip) \
        $(pkg_map zstd zstd zstd) \
        $(pkg_map unrar unrar unrar)

    # ── Modern CLI replacements ──
    pkg_install \
        $(pkg_map neovim neovim neovim) \
        $(pkg_map vim vim-enhanced vim) \
        $(pkg_map micro micro micro) \
        $(pkg_map tmux tmux tmux) \
        $(pkg_map zsh zsh zsh) \
        $(pkg_map fzf fzf fzf) \
        $(pkg_map ripgrep ripgrep ripgrep) \
        $(pkg_map fd fd-find fd-find) \
        $(pkg_map bat bat bat) \
        $(pkg_map eza eza eza) \
        $(pkg_map git-delta git-delta git-delta) \
        $(pkg_map zoxide zoxide zoxide) \
        $(pkg_map btop btop btop) \
        $(pkg_map fastfetch fastfetch fastfetch) \
        $(pkg_map stow stow stow) \
        $(pkg_map lazygit lazygit lazygit) \
        $(pkg_map yazi yazi yazi) \
        $(pkg_map zellij zellij zellij) \
        $(pkg_map jq jq jq) \
        $(pkg_map pv pv pv) \
        $(pkg_map tree tree tree) \
        $(pkg_map duf duf duf) \
        $(pkg_map htop htop htop) \
        $(pkg_map ugrep ugrep ugrep) \
        $(pkg_map plocate plocate mlocate)

    # ── Git extras ──
    pkg_install \
        $(pkg_map github-cli gh gh) \
        $(pkg_map git-lfs git-lfs git-lfs)

    # ── Networking ──
    pkg_install \
        $(pkg_map openssh openssh-client openssh-clients) \
        $(pkg_map rsync rsync rsync) \
        $(pkg_map inetutils inetutils net-tools) \
        $(pkg_map bind bind9-dnsutils bind-utils)

    ok "CLI tools installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY: Dev / Programming
# ══════════════════════════════════════════════════════════
install_dev() {
    header "Development Tools"

    # ── Build essentials ──
    info "Installing build tools..."
    case "$DISTRO" in
        arch)
            pkg_install base-devel cmake ninja gdb lldb clang lld ccache mold
            ;;
        debian)
            pkg_install build-essential cmake ninja-build gdb lldb clang lld ccache mold
            ;;
        fedora)
            pkg_install gcc gcc-c++ make cmake ninja-build gdb lldb clang lld ccache mold
            ;;
    esac

    # ── Python ──
    info "Installing Python..."
    case "$DISTRO" in
        arch)
            pkg_install \
                python python-pip python-virtualenv python-pipx \
                python-pynvim python-scipy python-packaging \
                uv
            ;;
        debian)
            pkg_install \
                python3 python3-pip python3-venv python3-dev \
                python3-pynvim python3-scipy pipx
            ;;
        fedora)
            pkg_install \
                python3 python3-pip python3-virtualenv python3-devel \
                python3-pynvim python3-scipy pipx
            ;;
    esac

    # ── Dev utilities ──
    info "Installing dev utilities..."
    pkg_install \
        $(pkg_map hyperfine hyperfine hyperfine) \
        $(pkg_map just just just) \
        $(pkg_map meld meld meld)

    # ── Containers ──
    info "Installing container tools..."
    case "$DISTRO" in
        arch)   pkg_install podman-docker podman-compose lazydocker ;;
        debian) pkg_install podman podman-compose ;;
        fedora) pkg_install podman podman-compose ;;
    esac

    # ── Virtualization ──
    info "Installing virtualization..."
    pkg_install $(pkg_map virt-manager virt-manager virt-manager)

    # ── Embedded / Cross-compilation ──
    info "Installing embedded toolchains..."
    case "$DISTRO" in
        arch)
            pkg_install \
                riscv64-elf-gcc riscv64-elf-newlib \
                valgrind \
                openocd
            ;;
        debian)
            pkg_install \
                gcc-riscv64-unknown-elf \
                valgrind \
                openocd
            ;;
        fedora)
            pkg_install \
                gcc-riscv64-linux-gnu \
                valgrind \
                openocd
            ;;
    esac

    # ── CUDA (Arch only, needs nvidia) ──
    if [[ "$DISTRO" == "arch" ]]; then
        info "Installing CUDA..."
        pkg_install cuda
    fi

    # ── .NET ──
    info "Installing .NET..."
    pkg_install \
        $(pkg_map dotnet-sdk dotnet-sdk-8.0 dotnet-sdk-8.0) \
        $(pkg_map dotnet-runtime dotnet-runtime-8.0 dotnet-runtime-8.0)

    # ── PyTorch (Arch has system packages) ──
    if [[ "$DISTRO" == "arch" ]]; then
        info "Installing PyTorch..."
        pkg_install python-pytorch python-pytorch-cuda 2>/dev/null || \
            pkg_install python-pytorch
    fi

    # ── Cloud tools ──
    info "Installing cloud tools..."
    case "$DISTRO" in
        arch)   pkg_install aws-cli s3cmd s5cmd-bin ;;
        debian) pkg_install awscli s3cmd ;;
        fedora) pkg_install awscli s3cmd ;;
    esac

    # ── AI / LLM ──
    info "Installing AI tools..."
    pkg_install $(pkg_map ollama ollama ollama)

    ok "Dev tools installed"
}

# ── Toolchains ────────────────────────────────────────────

install_toolchain_rust() {
    header "Rust Toolchain"
    if command -v rustup &>/dev/null; then
        ok "Rust already installed ($(rustc --version 2>/dev/null || echo 'no rustc'))"
        rustup update 2>/dev/null || true
    else
        info "Installing Rust via rustup..."
        case "$DISTRO" in
            arch)   pkg_install rustup && rustup default stable ;;
            *)      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y ;;
        esac
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    fi
    ok "Rust ready"
}

install_toolchain_node() {
    header "Node.js Toolchain"
    if command -v node &>/dev/null; then
        ok "Node already installed ($(node --version))"
    else
        info "Installing Node.js..."
        case "$DISTRO" in
            arch)   pkg_install nodejs npm ;;
            *)
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
                nvm install --lts
                ;;
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
        info "Installing Go..."
        pkg_install $(pkg_map go golang golang)
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
#  CATEGORY: Productivity / GUI Apps
# ══════════════════════════════════════════════════════════
install_productivity() {
    header "Productivity & GUI Apps"

    case "$DISTRO" in
        arch)
            # ── Browsers ──
            pkg_install firefox
            pkg_install firefox-nightly-bin google-chrome-canary torbrowser-launcher 2>/dev/null || true

            # ── Terminals & editors ──
            pkg_install ghostty zed
            pkg_install emacs 2>/dev/null || true

            # ── Communication ──
            pkg_install vesktop 2>/dev/null || pkg_install discord

            # ── Notes & docs ──
            pkg_install obsidian anki libreoffice-fresh

            # ── Media ──
            pkg_install vlc-plugins-all mpv obs-studio audacity haruna
            pkg_install spotify-launcher 2>/dev/null || true

            # ── Creative ──
            pkg_install gimp inkscape krita krita-plugin-gmic kdenlive blender freecad
            pkg_install birdfont 2>/dev/null || true

            # ── Utilities ──
            pkg_install \
                flameshot spectacle peek variety \
                ark file-roller thunar dolphin kate \
                kcalc filelight meld \
                wl-clipboard xdg-utils xdg-user-dirs

            # ── API / Downloads ──
            pkg_install bruno-bin jdownloader2 2>/dev/null || true
            ;;
        debian)
            pkg_install \
                firefox vlc mpv obs-studio audacity \
                gimp inkscape krita kdenlive blender \
                libreoffice flameshot thunar dolphin kate \
                ark file-roller wl-clipboard xdg-utils \
                emacs

            ensure_flatpak
            flatpak install -y flathub com.discordapp.Discord 2>/dev/null || true
            flatpak install -y flathub md.obsidian.Obsidian 2>/dev/null || true
            flatpak install -y flathub com.spotify.Client 2>/dev/null || true
            flatpak install -y flathub net.ankiweb.Anki 2>/dev/null || true
            ;;
        fedora)
            pkg_install \
                firefox vlc mpv obs-studio audacity \
                gimp inkscape krita kdenlive blender \
                libreoffice flameshot thunar dolphin kate \
                ark file-roller wl-clipboard xdg-utils \
                emacs

            ensure_flatpak
            flatpak install -y flathub com.discordapp.Discord 2>/dev/null || true
            flatpak install -y flathub md.obsidian.Obsidian 2>/dev/null || true
            flatpak install -y flathub com.spotify.Client 2>/dev/null || true
            flatpak install -y flathub net.ankiweb.Anki 2>/dev/null || true
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
            # Enable multilib if not already
            if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
                warn "Enabling multilib repository..."
                sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
                sudo pacman -Sy
            fi

            # ── Core gaming stack ──
            pkg_install \
                steam lutris \
                wine-staging wine-mono wine-gecko winetricks \
                gamemode lib32-gamemode \
                mangohud lib32-mangohud \
                gamescope

            # ── GPU / Vulkan ──
            pkg_install \
                vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools \
                lib32-nvidia-utils lib32-opencl-nvidia \
                nvidia-utils nvidia-settings opencl-nvidia \
                libva-nvidia-driver egl-wayland mesa-utils

            # Also install Intel Vulkan if hybrid GPU
            pkg_install vulkan-intel lib32-vulkan-intel libva-intel-driver 2>/dev/null || true

            # ── AUR gaming extras ──
            pkg_install \
                proton-ge-custom-bin \
                heroic-games-launcher-bin \
                protonup-qt \
                prismlauncher \
                osu-lazer-bin \
                modrinth-app-bin \
                lug-helper \
                sunshine \
                hidamari \
                winboat-bin \
                2>/dev/null || true
            ;;
        debian)
            sudo dpkg --add-architecture i386
            sudo apt-get update -qq

            pkg_install \
                steam-installer lutris \
                wine winetricks \
                gamemode mangohud \
                mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
                vulkan-tools

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

            pkg_install \
                steam lutris \
                wine winetricks \
                gamemode mangohud \
                vulkan-tools gamescope

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

    # ── Fonts ──
    info "Installing fonts..."
    case "$DISTRO" in
        arch)
            pkg_install \
                ttf-jetbrains-mono-nerd ttf-meslo-nerd otf-monaspace-nerdfonts \
                ttf-intel-one-mono inter-font \
                ttf-dejavu ttf-liberation ttf-bitstream-vera ttf-opensans \
                cantarell-fonts awesome-terminal-fonts \
                noto-fonts noto-fonts-cjk noto-fonts-emoji \
                papirus-icon-theme phinger-cursors
            ;;
        debian)
            pkg_install \
                fonts-jetbrains-mono fonts-firacode \
                fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
                fonts-dejavu fonts-liberation \
                papirus-icon-theme
            ;;
        fedora)
            pkg_install \
                jetbrains-mono-fonts fira-code-fonts \
                google-noto-fonts-common google-noto-cjk-fonts google-noto-emoji-fonts \
                dejavu-sans-fonts liberation-fonts \
                papirus-icon-theme
            ;;
    esac
    fc-cache -f 2>/dev/null || true

    # ── System tools ──
    info "Installing system tools..."
    case "$DISTRO" in
        arch)
            pkg_install \
                man-db man-pages bash-completion \
                reflector pkgfile pacman-contrib rebuild-detector \
                smartmontools hdparm lsb-release dmidecode \
                hwinfo hwdetect lsscsi usbutils \
                fwupd upower cpupower \
                power-profiles-daemon \
                profile-sync-daemon
            ;;
        debian)
            pkg_install \
                man-db manpages-dev bash-completion \
                smartmontools hdparm lsb-release dmidecode \
                hwinfo usbutils \
                fwupd upower cpupower-gui \
                power-profiles-daemon
            ;;
        fedora)
            pkg_install \
                man-db man-pages bash-completion \
                smartmontools hdparm lsb_release dmidecode \
                hwinfo usbutils \
                fwupd upower kernel-tools \
                power-profiles-daemon
            ;;
    esac

    # ── Bluetooth ──
    info "Installing Bluetooth..."
    pkg_install \
        $(pkg_map bluez bluez bluez) \
        $(pkg_map bluez-utils bluez-tools bluez-tools) \
        $(pkg_map bluez-libs libbluetooth-dev bluez-libs-devel) \
        $(pkg_map bluez-obex bluez-obexd bluez-obex) \
        $(pkg_map bluez-hid2hci bluez-hid2hci bluez-hid2hci)

    # ── Audio (PipeWire) ──
    info "Installing audio stack..."
    case "$DISTRO" in
        arch)   pkg_install pipewire-alsa pipewire-pulse wireplumber pavucontrol sof-firmware ;;
        debian) pkg_install pipewire pipewire-pulse wireplumber pavucontrol firmware-sof-signed ;;
        fedora) pkg_install pipewire pipewire-pulseaudio wireplumber pavucontrol ;;
    esac

    # ── Printing ──
    info "Installing printing..."
    pkg_install \
        $(pkg_map cups cups cups) \
        $(pkg_map cups-filters cups-filters cups-filters) \
        $(pkg_map cups-pdf cups-pdf cups-pdf) \
        $(pkg_map system-config-printer system-config-printer system-config-printer) \
        $(pkg_map ghostscript ghostscript ghostscript)
    case "$DISTRO" in
        arch) pkg_install gutenprint foomatic-db foomatic-db-engine \
                foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds \
                foomatic-db-gutenprint-ppds splix gsfonts ;;
    esac

    # ── Filesystems ──
    info "Installing filesystem tools..."
    case "$DISTRO" in
        arch)
            pkg_install \
                btrfs-progs e2fsprogs xfsprogs jfsutils f2fs-tools \
                ntfs-3g exfatprogs dosfstools \
                nilfs-utils dmraid lvm2 cryptsetup mdadm \
                mtools fsarchiver
            ;;
        debian)
            pkg_install \
                btrfs-progs e2fsprogs xfsprogs \
                ntfs-3g exfatprogs dosfstools \
                lvm2 cryptsetup mdadm
            ;;
        fedora)
            pkg_install \
                btrfs-progs e2fsprogs xfsprogs \
                ntfs-3g exfatprogs dosfstools \
                lvm2 cryptsetup mdadm
            ;;
    esac

    # ── Btrfs snapshots (Arch) ──
    if [[ "$DISTRO" == "arch" ]]; then
        pkg_install snapper btrfs-assistant 2>/dev/null || true
    fi

    # ── Networking ──
    info "Installing network tools..."
    case "$DISTRO" in
        arch)
            pkg_install \
                networkmanager networkmanager-openvpn \
                iwd nss-mdns dnsmasq \
                tailscale ufw xl2tpd \
                modemmanager ethtool
            ;;
        debian)
            pkg_install \
                network-manager network-manager-openvpn \
                nss-mdns dnsmasq \
                tailscale ufw \
                modemmanager ethtool
            ;;
        fedora)
            pkg_install \
                NetworkManager NetworkManager-openvpn \
                nss-mdns dnsmasq \
                tailscale firewalld \
                ModemManager ethtool
            ;;
    esac

    # ── Boot / EFI (Arch) ──
    if [[ "$DISTRO" == "arch" ]]; then
        pkg_install \
            efibootmgr efitools mkinitcpio os-prober \
            plymouth 2>/dev/null || true
    fi

    # ── Multimedia codecs ──
    info "Installing multimedia codecs..."
    case "$DISTRO" in
        arch)
            pkg_install \
                gst-libav gst-plugin-pipewire gst-plugin-va \
                gst-plugins-bad gst-plugins-ugly \
                libdvdcss libgsf libmythes libopenraw \
                ffmpegthumbnailer ffmpegthumbs poppler-glib \
                opus-tools sox frei0r-plugins \
                intel-media-sdk libva-utils
            ;;
        debian)
            pkg_install \
                gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
                ffmpegthumbnailer \
                ubuntu-restricted-extras 2>/dev/null || true
            ;;
        fedora)
            pkg_install \
                gstreamer1-plugin-libav gstreamer1-plugins-bad-free gstreamer1-plugins-ugly \
                ffmpegthumbnailer
            ;;
    esac

    # ── Wayland extras ──
    pkg_install $(pkg_map wayland-protocols wayland-protocols wayland-protocols)
    pkg_install $(pkg_map xsettingsd xsettingsd xsettingsd) 2>/dev/null || true

    # ── KDE Plasma extras (Arch) ──
    if [[ "$DISTRO" == "arch" ]]; then
        info "Installing KDE extras..."
        pkg_install \
            plasma-desktop plasma-nm plasma-pa plasma-systemmonitor \
            plasma-firewall plasma-thunderbolt plasma-browser-integration \
            plasma-login-manager \
            kdeplasma-addons powerdevil kinfocenter kscreen \
            kde-gtk-config breeze-gtk \
            kdeconnect kwallet-pam kwalletmanager \
            kdegraphics-thumbnailers \
            phonon-qt6-vlc discover partitionmanager kio-admin \
            konsole \
            2>/dev/null || true
    fi

    # ── QMK (keyboard firmware) ──
    pkg_install $(pkg_map qmk qmk-toolbox qmk) 2>/dev/null || true

    ok "System extras installed"
}

# ══════════════════════════════════════════════════════════
#  CATEGORY: Dotfiles (configs)
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
    echo -e "  ${BOLD}1)${NC}  Everything               ${DIM}(all categories below)${NC}"
    echo -e "  ${BOLD}2)${NC}  Dev / Programming         ${DIM}(CLI, build, containers, embedded, AI)${NC}"
    echo -e "  ${BOLD}3)${NC}  Gaming                    ${DIM}(Steam, Lutris, Wine, Proton, MangoHud)${NC}"
    echo -e "  ${BOLD}4)${NC}  Productivity              ${DIM}(browsers, editors, creative, media)${NC}"
    echo -e "  ${BOLD}5)${NC}  System / Fonts / Hardware  ${DIM}(fonts, drivers, bluetooth, printing, KDE)${NC}"
    echo -e "  ${BOLD}6)${NC}  Dotfiles only              ${DIM}(clone & stow configs)${NC}"
    echo ""
    echo -e "  ${BOLD}Toolchains:${NC}"
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
                echo "  --dev            CLI tools + build tools + containers + embedded"
                echo "  --gaming         Steam, Lutris, Wine, Proton, MangoHud"
                echo "  --productivity   Browsers, editors, creative, media"
                echo "  --system         Fonts, drivers, bluetooth, printing, KDE"
                echo "  --dotfiles       Clone & stow configs"
                echo "  --rust           Rust via rustup"
                echo "  --node           Node.js via nvm/pacman"
                echo "  --go             Go"
                echo "  --claude         Claude Code"
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

    if [[ $# -gt 0 ]]; then
        if run_from_args "$@"; then
            echo ""
            ok "Setup complete!"
            return
        fi
    fi

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
            *)  warn "Invalid choice: $choice" ;;
        esac

        echo ""
        ok "Category complete! Returning to menu..."
        echo ""
    done
}

main "$@"
