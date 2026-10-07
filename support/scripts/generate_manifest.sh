#!/bin/bash
# Local helper to aggregate the last 6 generations of Buildroot releases
set -e

MANIFEST_FILE="../../verified_manifest.txt"
TEMP_DIR=$(mktemp -d)

# Clear or initialize the manifest file
echo "# Verified Buildroot Archive Hashes (Audited Out-Of-Band)" > "$MANIFEST_FILE"
echo "# Generated on $(date -u '+%Y-%m-%d %H:%M:%S UTC')" >> "$MANIFEST_FILE"
echo "" >> "$MANIFEST_FILE"

# Buildroot typically releases 4 times a year (Feb, May, Aug, Nov)
# Let's dynamically calculate the current year and generate the version matrix
CURRENT_YEAR=$(date +%Y)
PREV_YEAR=$((CURRENT_YEAR - 1))

# Generate the last 6 standard version targets (YYYY.02, YYYY.05, YYYY.08, YYYY.11)
VERSIONS=(
    "${CURRENT_YEAR}.08" "${CURRENT_YEAR}.05" "${CURRENT_YEAR}.02"
    "${PREV_YEAR}.11"    "${PREV_YEAR}.08"    "${PREV_YEAR}.05"
)

echo "Fetching archives and generating manifest fingerprints..."

for VER in "${VERSIONS[@]}"; do
    FILENAME="buildroot-${VER}.tar.xz"
    URL="https://buildroot.org/downloads/${FILENAME}"
    
    echo -n "Processing ${FILENAME}... "
    
    # Download the file silently into temp directory
    if curl -s --fail -o "${TEMP_DIR}/${FILENAME}" "$URL"; then
        # Calculate SHA256 locally
        SHA_HASH=$(sha256sum "${TEMP_DIR}/${FILENAME}" | awk '{print $1}')
        
        # Append nicely to your manifest file
        echo "${SHA_HASH}  ${FILENAME}" >> "$MANIFEST_FILE"
        echo "Done."
    else
        # If the absolute latest version isn't published yet (e.g. early in the month)
        echo "Skipped (Not yet published upstream)."
    fi
done


# Add this right before the 'rm -rf "$TEMP_DIR"' line in generate_manifest.sh
echo "Signing the new manifest automatically..."
gpg --yes --local-user "Maurice.Smulders@gmail.com" --output "${MANIFEST_FILE}.sig" --detach-sign "$MANIFEST_FILE"

# Clean up temp files
rm -rf "$TEMP_DIR"

echo "--------------------------------------------------------"
echo "Success! Your local '$MANIFEST_FILE' has been refreshed."

