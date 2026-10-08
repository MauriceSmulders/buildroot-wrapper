#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
# Target the current stable release or change to a desired version (e.g., "2026.08")
VERSION="2026.08"
TARBALL="buildroot-${VERSION}.tar.xz"
SIGNATURE="${TARBALL}.sign"

DOWNLOAD_URL="https://buildroot.org/downloads/${TARBALL}"
SIG_URL="https://buildroot.org/downloads/${SIGNATURE}"

# Key Identity for Peter Korsgaard (Buildroot Maintainer)
MAINTAINER_EMAIL="peter@korsgaard.com"

# --- Independent Keyring Setup ---
# Create an isolated GNUPGHOME directory to avoid cluttering your personal keyring
export GNUPGHOME="$(pwd)/.buildroot_gpg"
mkdir -p -m 700 "$GNUPGHOME"

echo "=========================================================="
echo "Initializing isolated Buildroot GPG workspace..."
echo "Workspace path: $GNUPGHOME"
echo "=========================================================="

# Fetch the public key securely into our isolated keyring
echo "Fetching maintainer's public key (${MAINTAINER_EMAIL}) from keyserver..."
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$MAINTAINER_EMAIL"

# --- Download Files ---
echo -e "\nDownloading Buildroot archive and PGP signature..."
curl -fSL -O "$DOWNLOAD_URL"
curl -fSL -O "$SIG_URL"

# --- Verification Phase ---
echo -e "\nPerforming cryptographic verification..."
# We explicitly invoke gpg using the scoped GNUPGHOME context
if gpg --verify "$SIGNATURE" "$TARBALL"; then
    echo -e "\n##########################################################"
    echo "SUCCESS: Buildroot signature verification passed!"
    echo "The file '$TARBALL' is authentic."
    echo "##########################################################"
else
    echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CRITICAL WARNING: Buildroot signature verification failed!"
    echo "Do not trust the extracted archive contents."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

