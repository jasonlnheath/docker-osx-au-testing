#!/bin/bash
# macOS Docker AU Tester - Validation Script
# Run this from Windows to validate AU builds

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PLUGIN_NAME="${1:-AmpBender}"
PLUGIN_COMPONENT="${PLUGIN_NAME}.component"
HOST_PLUGINS_PATH="/host-plugins"
MACOS_PLUGINS_PATH="/Library/Audio/Plug-Ins/Components"

echo "=== AU Plugin Validation ==="
echo "Plugin: $PLUGIN_NAME"

# Check container is running
echo -e "\n[1/6] Checking container status..."
if ! docker ps | grep -q macos-au-tester; then
    echo -e "${RED}Container not running!${NC}"
    echo "Start with: docker compose up -d"
    exit 1
fi
echo -e "${GREEN}✓ Container is running${NC}"

# Check SSH connectivity
echo -e "\n[2/6] Checking SSH connectivity..."
if ! ssh -p 50922 -o ConnectTimeout=5 -o StrictHostKeyChecking=no user@localhost "echo 'SSH OK'" 2>/dev/null; then
    echo -e "${YELLOW}⚠ SSH not ready. macOS may still be booting...${NC}"
    echo "Wait 2-3 minutes and try again"
    exit 1
fi
echo -e "${GREEN}✓ SSH connected${NC}"

# Check pluginval is installed
echo -e "\n[3/6] Checking pluginval..."
if ! ssh -p 50922 user@localhost "command -v pluginval" 2>/dev/null; then
    echo -e "${YELLOW}⚠ pluginval not installed${NC}"
    echo "Install with: ssh -p 50922 user@localhost 'bash -s' < install-tools.sh"
    exit 1
fi
echo -e "${GREEN}✓ pluginval installed${NC}"

# Copy AU component to container
echo -e "\n[4/6] Copying AU component..."
HOST_BUILD_PATH="../../build/plugins/${PLUGIN_COMPONENT}"
if [ ! -d "$HOST_BUILD_PATH" ]; then
    echo -e "${RED}✗ Plugin not found at: $HOST_BUILD_PATH${NC}"
    echo "Build the plugin first with CMake"
    exit 1
fi
echo -e "${GREEN}✓ Plugin found${NC}"

# Create temp directory and copy plugin
ssh -p 50922 user@localhost "mkdir -p ~/tmp-au" 2>/dev/null
echo "Copying plugin to container..."
scp -P 50922 -r "$HOST_BUILD_PATH" user@localhost:~/tmp-au/ 2>/dev/null
echo -e "${GREEN}✓ Plugin copied${NC}"

# Install plugin (requires sudo)
echo -e "\n[5/6] Installing AU component..."
ssh -p 50922 user@localhost << 'EOF'
    echo "alpine" | sudo -S cp -R ~/tmp-au/*.component /Library/Audio/Plug-Ins/Components/
    echo "alpine" | sudo -S chmod -R 755 /Library/Audio/Plug-Ins/Components/*.component
EOF
echo -e "${GREEN}✓ Plugin installed${NC}"

# Run pluginval
echo -e "\n[6/6] Running pluginval validation..."
ssh -p 50922 user@localhost "pluginval --strictness-level 5 --timeout-in-seconds 300 /Library/Audio/Plug-Ins/Components/${PLUGIN_COMPONENT}"

# Check result
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}=== Validation PASSED ===${NC}"
else
    echo -e "\n${RED}=== Validation FAILED ===${NC}"
    echo "Check the output above for details"
    exit 1
fi

echo -e "\nFor manual testing in REAPER:"
echo "  1. VNC connect: localhost:8888"
echo "  2. Or use WSLg GUI (automatic)"
echo "  3. Open REAPER64.app"
echo "  4. Create track, insert AU: $PLUGIN_NAME"
