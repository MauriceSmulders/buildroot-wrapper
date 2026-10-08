#!/bin/sh
# setup.sh - Universal, Idempotent Host Dependency Bootstrap
set -e

TOP_DIR="$(cd "$(dirname "$0")" && pwd)"
FLAG_FILE="${TOP_DIR}/.host_configured"

# Unified package dependency mappings for Buildroot compilation
DEBIAN_DEPS="build-essential sed make binutils diffutils gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc findutils awk wget libncurses-dev"
ARCH_DEPS="base-devel sed make binutils diffutils gcc bash patch gzip bzip2 perl tar cpio unzip rsync file bc findutils gawk wget ncurses"
RPM_DEPS="bash bc binutils bzip2 cpio diffutils file findutils gawk gcc gcc-c++ gzip make ncurses-devel patch perl rsync sed tar unzip wget"
SUSE_DEPS="bash bc binutils bzip2 cpio diffutils file findutils gawk gcc gcc-c++ gzip make ncurses-devel patch perl rsync sed tar unzip wget"

install_dependencies() {
    echo "Checking system host dependencies..."
    
    # 1. Debian / Ubuntu / Mint
    if [ -x "$(command -v apt-get)" ]; then
        echo "Detected Debian/Ubuntu-based system."
        sudo apt-get update -qq
        sudo apt-get install -y $DEBIAN_DEPS

    # 2. RedHat / Fedora / CentOS
    elif [ -x "$(command -v dnf)" ]; then
        echo "Detected RPM/RedHat-based system."
        # --assumeyes forces unattended install; updates if old, skips if current
        sudo dnf install --assumeyes $RPM_DEPS

    # 3. Arch Linux / Manjaro
    elif [ -x "$(command -v pacman)" ]; then
        echo "Detected Arch-based system."
        # --needed skips packages that match the current version
        sudo pacman -Sy --needed --noconfirm $ARCH_DEPS

    # 4. openSUSE (Kept ready for stage 2 implementation)
    elif [ -x "$(command -v zypper)" ]; then
        echo "Detected openSUSE system."
        # --non-interactive skips prompts; automatically resolves unchanged items
        sudo zypper --non-interactive install $SUSE_DEPS

    else
        echo "ERROR: Unknown package manager. Please manually install the Buildroot core toolchain requirements."
        exit 1
    fi
}

# Idempotent State Loop
if [ -f "$FLAG_FILE" ]; then
    echo "Host dependencies verified via local flagfile. Skipping setup loop (No-Op)."
else
    install_dependencies
    touch "$FLAG_FILE"
    echo "Host setup complete. Environment is now verified for Stage 1 compilation."
fi

