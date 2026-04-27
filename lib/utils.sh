#!/usr/bin/env bash
# lib/utils.sh — Colors, logging, package installation

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()   { echo -e "${CYAN}[*]${NC} $1"; }
ok()     { echo -e "${GREEN}[+]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
fail()   { echo -e "${RED}[-]${NC} $1"; }
header() { echo -e "\n${BOLD}${CYAN}═══ $1 ═══${NC}\n"; }

# ── Package installation ───────────────────────────────────────────────────────
# DRY_RUN=1 → print what would be installed without running
DRY_RUN="${DRY_RUN:-0}"

pkg_install() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return

    if [[ "$DRY_RUN" == "1" ]]; then
        echo -e "  ${DIM}[dry-run] would install: ${pkgs[*]}${NC}"
        return
    fi

    case "$DISTRO" in
        arch)
            if command -v paru &>/dev/null; then
                paru -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true
            elif command -v yay &>/dev/null; then
                yay -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true
            else
                sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true
            fi ;;
        debian)
            sudo apt-get update -qq
            sudo apt-get install -y "${pkgs[@]}" 2>/dev/null || true ;;
        fedora)
            sudo dnf install -y "${pkgs[@]}" 2>/dev/null || true ;;
        suse)
            sudo zypper install -y "${pkgs[@]}" 2>/dev/null || true ;;
        void)
            sudo xbps-install -Sy "${pkgs[@]}" 2>/dev/null || true ;;
    esac
}

# ── AUR helper (Arch only) ────────────────────────────────────────────────────
install_aur_helper() {
    [[ "$DISTRO" != "arch" ]] && return
    command -v paru &>/dev/null && { ok "paru already installed"; return; }
    command -v yay  &>/dev/null && { ok "yay already installed";  return; }

    info "Installing paru..."
    sudo pacman -S --needed --noconfirm base-devel git
    local tmp; tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    (cd "$tmp/paru" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    ok "paru installed"
}

# ── Flatpak (non-Arch GUI fallback) ──────────────────────────────────────────
ensure_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        info "Installing flatpak..."
        pkg_install flatpak
    fi
    flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
}
