#!/bin/bash
# macOS Docker AU Tester - Tool Installation Script
# Run this INSIDE the macOS container via SSH

set -e

echo "=== Installing AU Testing Tools ==="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check we're running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This script must be run inside the macOS container"
    exit 1
fi

# Install Homebrew if not present
echo -e "\n[1/4] Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✓ Homebrew already installed${NC}"
fi

# Install pluginval
echo -e "\n[2/4] Installing pluginval..."
if ! command -v pluginval &> /dev/null; then
    brew install --cask pluginval
    echo -e "${GREEN}✓ pluginval installed${NC}"
else
    echo -e "${GREEN}✓ pluginval already installed${NC}"
fi

# Install REAPER
echo -e "\n[3/4] Installing REAPER..."
if ! command -v /Applications/REAPER64.app/Contents/MacOS/REAPER &> /dev/null; then
    echo "Downloading REAPER for macOS..."
    cd ~/Downloads
    curl -L -o reaper.dmg "https://www.reaper.fm/files/7.x/reaper713_x86_64.dmg"
    hdiutil attach reaper.dmg
    cp -R /Volumes/Install\ REAPER64/REAPER64.app /Applications/
    hdiutil detach /Volumes/Install\ REAPER64
    rm reaper.dmg
    echo -e "${GREEN}✓ REAPER installed${NC}"
else
    echo -e "${GREEN}✓ REAPER already installed${NC}"
fi

# Create mount point for host plugins
echo -e "\n[4/4] Setting up host plugin mount..."
mkdir -p ~/host-plugins
sudo -S mount_9p hostshare 2>/dev/null || echo "Host plugins will be available at ~/host-plugins after mounting"

echo -e "\n=== Installation Complete ==="
echo -e "\nInstalled versions:"
pluginval --version 2>/dev/null || echo "pluginval: installed"

echo -e "\nNext steps:"
echo "  1. Build your AU plugin on Windows"
echo "  2. Build with CMake targeting macOS:"
echo "     cmake -B build-macos -DCMAKE_SYSTEM_NAME=Darwin -DCMAKE_OSX_ARCHITECTURES=x86_64"
echo "  3. Copy AU component to: /Library/Audio/Plug-Ins/Components/"
echo "  4. Run pluginval: pluginval --validate /path/to/plugin.component"
echo "  5. Test in REAPER: Open /Applications/REAPER64.app"
