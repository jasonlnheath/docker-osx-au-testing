#!/bin/bash
# build-and-test-au.sh - Complete AU build/test workflow via SCP
# Runs on Windows host (Git Bash/WSL2)

set -e

AU_NAME="${1:-AmpBender}"
SSH_PORT="${2:-50922}"
SSH_USER="${3:-jasonheath}"
SSH_HOST="${4:-localhost}"

# Source paths
WIN_SOURCE_DIR="/c/dev/HeathAudio"
MAC_SOURCE_DIR="~/HeathAudio"

echo "=== AU Build and Test Workflow for ${AU_NAME} ==="

echo "Step 1: Transferring source code to macOS..."

# Create remote directory
ssh -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" "mkdir -p ${MAC_SOURCE_DIR}"

# Transfer plugins directory (where source code lives)
echo "Transferring plugins directory..."
scp -P "${SSH_PORT}" -r "${WIN_SOURCE_DIR}/plugins" "${SSH_USER}@${SSH_HOST}:${MAC_SOURCE_DIR}/"

# Transfer CMakeLists.txt if it exists at root
if [ -f "${WIN_SOURCE_DIR}/CMakeLists.txt" ]; then
    scp -P "${SSH_PORT}" "${WIN_SOURCE_DIR}/CMakeLists.txt" "${SSH_USER}@${SSH_HOST}:${MAC_SOURCE_DIR}/"
fi

echo "Transfer complete!"

echo "Step 2: Building AU on macOS..."
ssh -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" << 'ENDSSH'
set -e
cd ~/HeathAudio

# Create build directory
mkdir -p build
cd build

# Configure with CMake
cmake -DCMAKE_BUILD_TYPE=Release ..

# Build AU target
cmake --build . --config Release --target ${AU_NAME}_AU

echo "Build complete!"
ENDSSH

echo "Step 3: Installing AU component..."
ssh -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" << ENDSSH
set -e

AU_SOURCE="~/HeathAudio/build/${AU_NAME}_artefacts/Release/AU/${AU_NAME}.component"
AU_DEST="~/Library/Audio/Plug-Ins/Components/"

echo "Copying \${AU_SOURCE} to \${AU_DEST}"
cp -R "\${AU_SOURCE}" "\${AU_DEST}"

echo "Setting permissions..."
chmod -R 755 "\${AU_DEST}${AU_NAME}.component"

echo "Clearing AU cache..."
rm -rf ~/Library/Caches/AudioUnitCache
killall -9 AudioComponentRegistrar 2>/dev/null || true
sleep 2

echo "Triggering registration..."
touch "\${AU_DEST}${AU_NAME}.component"
sleep 2

echo "Installation complete!"
ENDSSH

echo "Step 4: Validating AU with auval..."
ssh -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}" "auval -v -strict aufx AmpB HthA 2>&1 || echo 'AU validation returned non-zero'"

echo "=== Workflow complete ==="
