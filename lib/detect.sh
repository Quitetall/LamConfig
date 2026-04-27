#!/usr/bin/env bash
# lib/detect.sh — Distro detection

detect_distro() {
    [[ -n "${DISTRO:-}" ]] && return

    if [[ ! -f /etc/os-release ]]; then
        fail "/etc/os-release not found — cannot detect distro"
        exit 1
    fi

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
            warn "Unknown distro: $ID — assuming arch"
            DISTRO="arch" ;;
    esac

    ok "Detected: ${PRETTY_NAME:-$ID} (${DISTRO} family)"
}
