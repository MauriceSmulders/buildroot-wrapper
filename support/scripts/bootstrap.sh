#!/usr/bin/env bash
# ==============================================================================
#  UNIVERSAL HOST BOOTSTRAP, DEPENDENCY TRACKER & BUILDROOT CORE RUNTIME ENGINE
# ==============================================================================
set -euo pipefail
# Capture absolute workspace roots cleanly relative to the script execution path
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Track host package markers inside an untracked, hidden file
FLAG_FILE="${WORKSPACE_DIR}/.host_configured"

# Parameterized configurations handed down from the parent Makefile proxy
REQ_TYPE="${1:-LTS}"
REQ_VER="${2:-2025.02}"
BR_DIR_RAW="${3:-.buildroot-core}"

# Standardize path routing if a relative variable pass arrives from the Makefile
case "${BR_DIR_RAW}" in
    /*) BR_DIR="${BR_DIR_RAW}" ;;
    *)  BR_DIR="${WORKSPACE_DIR}/${BR_DIR_RAW}" ;;
esac

TARBALL_FILE="buildroot-${REQ_VER}.tar.xz"
SIGN_FILE="buildroot-${REQ_VER}.tar.xz.sign"

# Explicit browser spoof configuration to shatter aggressive anti-bot router guards
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# Unified package dependency mappings for Buildroot compilation (Includes compilation tools)
DEBIAN_DEPS="build-essential sed make binutils diffutils gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc findutils gawk wget libncurses-dev m4 bison flex gnupg"
ARCH_DEPS="base-devel sed make binutils diffutils gcc bash patch gzip bzip2 perl tar cpio unzip rsync file bc findutils gawk wget ncurses m4 bison flex gnupg"
RPM_DEPS="bash bc binutils bzip2 cpio diffutils file findutils gawk gcc gcc-c++ gzip make ncurses-devel patch perl rsync sed tar unzip wget m4 bison flex gnupg"
SUSE_DEPS="bash bc binutils bzip2 cpio diffutils file findutils gawk gcc gcc-c++ gzip make ncurses-devel patch perl rsync sed tar unzip wget m4 bison flex gnupg"

# ------------------------------------------------------------------------------
# STAGE 1: Host Dependency Verification Loop (Idempotent Environment Check)
# ------------------------------------------------------------------------------
install_host_dependencies() {
    if [ -f "${FLAG_FILE}" ]; then
        echo "[*] Host system toolchains verified via local flagfile. Skipping package updates."
        return 0
    fi

    echo "[*] Initializing Host Environment System Audit..."
    
    # 1. Debian / Ubuntu / Linux Mint
    if [ -x "$(command -v apt-get)" ]; then
        echo "[*] Detected Debian/Ubuntu-based host platform."
        sudo apt-get update -qq
        sudo apt-get install -y ${DEBIAN_DEPS}

    # 2. RedHat / Fedora / CentOS Stream
    elif [ -x "$(command -v dnf)" ]; then
        echo "[*] Detected RPM/RedHat-based host platform."
        sudo dnf install --assumeyes ${RPM_DEPS}

    # 3. Arch Linux / Manjaro
    elif [ -x "$(command -v pacman)" ]; then
        echo "[*] Detected Arch-based host platform."
        sudo pacman -Sy --needed --noconfirm ${ARCH_DEPS}

    # 4. openSUSE
    elif [ -x "$(command -v zypper)" ]; then
        echo "[*] Detected openSUSE-based host platform."
        sudo zypper --non-interactive install ${SUSE_DEPS}

    else
        echo "[-] ERROR: Unknown system package manager. Please ensure Buildroot prerequisites are manualy deployed."
        exit 1
    fi

    touch "${FLAG_FILE}"
    echo "[+] Host core configuration verified successfully."
}

# ------------------------------------------------------------------------------
# STAGE 2: Buildroot Core Fetching, Verification, and Allocation Patching
# ------------------------------------------------------------------------------
bootstrap_buildroot_core() {
    # Check if target sandbox is already populated
    if [ -d "${BR_DIR}" ] && [ -f "${BR_DIR}/Makefile" ]; then
        echo "[*] Sandbox core runtime environment already initialized. Skipping mirror synchronization."
        return 0
    fi

    # Pre-flight Check: Ensure target has a viable network gateway to the mirror source
    echo "[*] Verifying remote network mirror availability..."
    if ! curl -sI --connect-timeout 5 -A "${USER_AGENT}" "https://buildroot.org" > /dev/null 2>&1; then
        echo "[-] ERROR: Cannot reach buildroot.org. Verify network interface connections or proxy routing configurations."
        exit 1
    fi

    echo "[*] Launching Workspace Bootstrap Platform [${REQ_TYPE} Release v${REQ_VER}]..."
    mkdir -p "${BR_DIR}"

    # Steps 2.1-2.3: Delegate download + PGP verification to the decoupled
    # check_and_validate_download.sh. Fail-closed: any failure aborts here.
    # (The old inline warn-and-continue GPG check is gone.)
    echo "[*] Steps 1-3/4: Syncing source tarball and verifying PGP signature..."
    "${SCRIPT_DIR}/check_and_validate_download.sh" "${REQ_VER}" "${WORKSPACE_DIR}" || {
        echo "[-] ERROR: Source archive download or PGP verification failed.";
        rm -rf "${BR_DIR}";
        exit 1;
    }
    TARBALL_PATH="${WORKSPACE_DIR}/buildroot-${REQ_VER}.tar.xz"

    # Step 2.4: Extract verified data packets directly into the hidden sandbox partition
    echo "[*] Step 4/4: Expanding binary containers into sandbox workspace..."
    tar -xJ --strip-components=1 \
        -C "${BR_DIR}" \
        -f "${TARBALL_PATH}" || {
            echo "[-] ERROR: Archive extraction sequence collapsed. Download chunk corrupted.";
            rm -f "${TARBALL_PATH}" "${TARBALL_PATH}.sign";
            rm -rf "${BR_DIR}";
            exit 1;
        }

    # Step 2.5: Inject the critical path allocation upgrade to fix the Kconfig multi-external path overflow bug
    UTIL_C_PATH="${BR_DIR}/support/kconfig/util.c"
    if [ -f "$UTIL_C_PATH" ]; then
        echo "[*] Modifying legacy Kconfig buffer thresholds to cleanly accommodate multi-layer BR2_EXTERNAL strings..."
        sed -i 's/buf2\[PATH_MAX+1\]/buf2\[(PATH_MAX*2)+1\]/g' "$UTIL_C_PATH"
    fi

    # Clean workspace staging artifacts cleanly
    rm -f "${TARBALL_PATH}" "${TARBALL_PATH}.sign"
    echo "[+] SUCCESS: Core operational sandbox fully synchronized and configured."
}

# Linear Execution Chain
install_host_dependencies
bootstrap_buildroot_core

