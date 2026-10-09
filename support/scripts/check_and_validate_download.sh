#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
# Parametrized: VERSION and OUTDIR come from the caller (bootstrap.sh).
# Defaults keep the script runnable standalone.
# Usage: check_and_validate_download.sh [VERSION] [OUTDIR]
# Target the current stable release or change to a desired version (e.g., "2026.08")
VERSION="${1:-2026.08}"
OUTDIR="${2:-$(pwd)}"
mkdir -p "${OUTDIR}"
cd "${OUTDIR}"

TARBALL="buildroot-${VERSION}.tar.xz"
SIGNATURE="${TARBALL}.sign"

DOWNLOAD_URL="https://buildroot.org/downloads/${TARBALL}"
SIG_URL="https://buildroot.org/downloads/${SIGNATURE}"

# Key Identity for Peter Korsgaard (Buildroot Maintainer)
MAINTAINER_EMAIL="peter@korsgaard.com"
# Release-signing key fingerprint. NOTE: releases are signed with Peter's
# 2009 key (uid jacmet@uclibc.org), not his newer 2014 peter@korsgaard.com key.
# The key itself is fetched from public keyserver infrastructure at verify
# time; this fingerprint is the trust anchor.
MAINTAINER_FPR="AB07D806D2CE741FB886EE50B025BA8B59C36319"

# --- Independent Keyring Setup ---
# Create an isolated GNUPGHOME directory to avoid cluttering your personal keyring
GNUPGHOME="$(pwd)/.buildroot_gpg"
export GNUPGHOME
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

echo "=========================================================="
echo "Initializing isolated Buildroot GPG workspace..."
echo "Workspace path: $GNUPGHOME"
echo "=========================================================="

# Fetch the public key securely into our isolated keyring
echo "Fetching maintainer's public key (${MAINTAINER_EMAIL}) from keyserver..."
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$MAINTAINER_FPR"

# --- Download Files ---
echo -e "\nDownloading Buildroot archive and PGP signature..."
curl -fSL -O "$DOWNLOAD_URL"
curl -fSL -O "$SIG_URL"

# --- Verification Phase ---
# The .sign file is a GPG *clearsigned* message (not a detached signature):
# release metadata plus SHA1/SHA256 hashes of the tarball, all signed.
# Cryptographic validity is decided by the GOODSIG status line, not the
# exit code (which also reflects trust/expiry policy, not signature math).
echo -e "\nPerforming cryptographic verification..."
if ! gpg --status-fd 1 --verify "$SIGNATURE" 2>/dev/null | grep -q "^\[GNUPG:\] GOODSIG"; then
    echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CRITICAL WARNING: Buildroot signature verification failed!"
    echo "Do not trust the downloaded archive."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi
echo "Signature is cryptographically valid."
VERIFIED_MSG=$(gpg --decrypt "$SIGNATURE" 2>/dev/null || true)

EXPECTED_SHA=$(printf '%s\n' "$VERIFIED_MSG" | awk -v t="$TARBALL" '$1 == "SHA256:" && $3 == t { print $2 }')
if [ -z "$EXPECTED_SHA" ]; then
    echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CRITICAL WARNING: No signed SHA256 found for '$TARBALL'!"
    echo "Do not trust the downloaded archive."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

ACTUAL_SHA=$(sha256sum "$TARBALL" | awk '{ print $1 }')
if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
    echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "CRITICAL WARNING: SHA256 mismatch - tarball does not match signature!"
    echo "Expected: $EXPECTED_SHA"
    echo "Actual:   $ACTUAL_SHA"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

echo -e "\n##########################################################"
echo "SUCCESS: Buildroot signature verification passed!"
echo "The file '$TARBALL' is authentic (SHA256 matches signed value)."
echo "##########################################################"

