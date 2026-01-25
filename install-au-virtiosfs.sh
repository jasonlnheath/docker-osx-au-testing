#!/bin/bash
# install-au-virtiosfs.sh - Install AU component with proper metadata handling

set -e

AU_NAME="${1:-AmpBender}"
AU_SOURCE="/host-build/plugins/${AU_NAME}/${AU_NAME}_artefacts/Release/AU/${AU_NAME}.component"
AU_DEST=~/Library/Audio/Plug-Ins/Components/

echo "=== Installing ${AU_NAME} AU (VirtioFS-optimized) ==="

# Check if AU exists
if [ ! -d "${AU_SOURCE}" ]; then
    echo "ERROR: AU component not found at ${AU_SOURCE}"
    echo "Available components:"
    ls -la /host-build/plugins/*/Release/AU/*.component 2>/dev/null || echo "None"
    exit 1
fi

# Copy AU component to macOS native filesystem
echo "Copying ${AU_SOURCE} to ${AU_DEST}"
cp -R "${AU_SOURCE}" "${AU_DEST}"

# Set correct permissions
echo "Setting permissions..."
chmod -R 755 "${AU_DEST}/${AU_NAME}.component"

# Verify extended attributes
echo "Verifying extended attributes..."
xattr -l "${AU_DEST}/${AU_NAME}.component" || echo "No xattrs found (expected for fresh copy)"

# Clear AU cache to force re-scan
echo "Clearing AU cache..."
rm -rf ~/Library/Caches/AudioUnitCache
killall -9 AudioComponentRegistrar 2>/dev/null || true
sleep 2

# Touch component to trigger registration
echo "Triggering component registration..."
touch "${AU_DEST}/${AU_NAME}.component"
sleep 2

echo "=== AU installation complete ==="
echo "Run: auval -v aufx <subtype> <manufacturer>"
