#!/bin/bash
# install-au-scp.sh - Install AU component via SCP (Windows/WSL2 compatible)
# This script runs on the Windows host (via Git Bash or WSL)

set -e

AU_NAME="${1:-AmpBender}"
SSH_PORT="${2:-50922}"
SSH_USER="${3:-jasonheath}"
SSH_HOST="${4:-localhost}"

# Windows paths (Git Bash/MSYS2 format)
WIN_BUILD_DIR="/c/dev/HeathAudio/build/plugins/${AU_NAME}/${AU_NAME}_artefacts/Release/AU"

# macOS paths
MAC_AU_SOURCE="~/Desktop/${AU_NAME}.component"
MAC_AU_DEST="~/Library/Audio/Plug-Ins/Components/"

echo "=== Installing ${AU_NAME} AU via SCP ==="

# Check if AU exists locally
if [ ! -d "${WIN_BUILD_DIR}/${AU_NAME}.component" ]; then
    echo "ERROR: AU component not found at ${WIN_BUILD_DIR}/${AU_NAME}.component"
    echo "Available components:"
    ls -la "/c/dev/HeathAudio/build/plugins/"*/Release/AU/*.component 2>/dev/null || echo "None"
    exit 1
fi

echo "Copying AU component from Windows to macOS Desktop..."
scp -P "${SSH_PORT}" -r "${WIN_BUILD_DIR}/${AU_NAME}.component" "${SSH_USER}@${SSH_HOST}:Desktop/"

echo "Installing AU component inside macOS..."
ssh -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" << 'ENDSSH'
set -e

AU_NAME="$1"
MAC_AU_DEST="~/Library/Audio/Plug-Ins/Components/"

echo "Copying ~/Desktop/${AU_NAME}.component to ${MAC_AU_DEST}"
cp -R ~/Desktop/${AU_NAME}.component ${MAC_AU_DEST}

echo "Setting permissions..."
chmod -R 755 "${MAC_AU_DEST}${AU_NAME}.component"

echo "Verifying extended attributes..."
xattr -l "${MAC_AU_DEST}${AU_NAME}.component" || echo "No xattrs found (expected for fresh copy)"

echo "Clearing AU cache..."
rm -rf ~/Library/Caches/AudioUnitCache
killall -9 AudioComponentRegistrar 2>/dev/null || true
sleep 2

echo "Triggering component registration..."
touch "${MAC_AU_DEST}${AU_NAME}.component"
sleep 2

echo "=== AU installation complete ==="
echo "Run: auval -v aufx <subtype> <manufacturer>"
ENDSSH

echo "=== Transfer complete ==="
echo "AU component installed on macOS"
