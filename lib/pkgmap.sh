#!/usr/bin/env bash
# lib/pkgmap.sh — Canonical package name → distro-specific name
#
# Usage:  pkg_name <canonical-name>
# Returns the distro-specific package name for $DISTRO.
# Falls back to the canonical name if no override exists.

pkg_name() {
    local p="$1"
    case "${p}:${DISTRO}" in
        # ── fd ──────────────────────────────────────────────
        fd:debian)              echo "fd-find" ;;
        fd:fedora)              echo "fd-find" ;;

        # ── git-delta ───────────────────────────────────────
        git-delta:arch)         echo "git-delta" ;;
        git-delta:*)            echo "delta" ;;

        # ── github-cli ──────────────────────────────────────
        github-cli:arch)        echo "github-cli" ;;
        github-cli:*)           echo "gh" ;;

        # ── bat ─────────────────────────────────────────────
        # Arch: bat  Debian/Fedora: bat (no change)

        # ── openssh ─────────────────────────────────────────
        openssh:debian)         echo "openssh-client" ;;
        openssh:fedora)         echo "openssh-clients" ;;

        # ── p7zip ───────────────────────────────────────────
        p7zip:debian)           echo "p7zip-full" ;;

        # ── which ───────────────────────────────────────────
        which:debian)           echo "debianutils" ;;

        # ── inetutils ───────────────────────────────────────
        inetutils:debian)       echo "inetutils-tools" ;;
        inetutils:fedora)       echo "hostname" ;;

        # ── bind / nslookup ─────────────────────────────────
        bind:debian)            echo "bind9-dnsutils" ;;
        bind:fedora)            echo "bind-utils" ;;

        # ── plocate ─────────────────────────────────────────
        plocate:fedora)         echo "mlocate" ;;

        # ── ugrep ───────────────────────────────────────────
        # Available on all major distros as "ugrep"

        # ── go ──────────────────────────────────────────────
        go:debian)              echo "golang" ;;
        go:fedora)              echo "golang" ;;

        # ── virt-manager ────────────────────────────────────
        # Same name everywhere

        # ── gcc riscv ───────────────────────────────────────
        riscv64-elf-gcc:debian) echo "gcc-riscv64-unknown-elf" ;;
        riscv64-elf-gcc:fedora) echo "gcc-riscv64-linux-gnu" ;;
        riscv64-elf-newlib:debian) echo "" ;;  # not packaged
        riscv64-elf-newlib:fedora) echo "" ;;

        # ── dotnet ──────────────────────────────────────────
        dotnet-sdk:debian)      echo "dotnet-sdk-8.0" ;;
        dotnet-sdk:fedora)      echo "dotnet-sdk-8.0" ;;
        dotnet-runtime:debian)  echo "dotnet-runtime-8.0" ;;
        dotnet-runtime:fedora)  echo "dotnet-runtime-8.0" ;;

        # Default: canonical name works everywhere
        *)                      echo "$p" ;;
    esac
}

# Install a list of canonical package names (resolves each via pkg_name)
pkgs_install() {
    local resolved=()
    for p in "$@"; do
        local name
        name=$(pkg_name "$p")
        [[ -n "$name" ]] && resolved+=("$name")
    done
    [[ ${#resolved[@]} -gt 0 ]] && pkg_install "${resolved[@]}"
}
