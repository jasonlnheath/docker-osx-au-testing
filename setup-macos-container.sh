#!/bin/bash
# macOS Docker AU Tester - Container Setup Script
# Run this inside WSL2 after Windows setup

set -e

echo "=== macOS Docker AU Tester - Container Setup ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check KVM
echo -e "\n[1/5] Checking KVM support..."
if [ -e /dev/kvm ]; then
    echo -e "${GREEN}✓ KVM is available${NC}"
else
    echo -e "${YELLOW}✗ KVM not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils cpu-checker
    sudo usermod -aG kvm "$USER"
    sudo usermod -aG libvirt "$USER"
    echo -e "${YELLOW}Please log out and back in for group changes to take effect${NC}"
fi

# Step 2: Check X11 support
echo -e "\n[2/5] Checking X11 support..."
if [ -S /mnt/wslg/.X11-unix/X0 ]; then
    echo -e "${GREEN}✓ WSLg X11 server detected${NC}"
else
    echo -e "${YELLOW}⚠ WSLg not detected. X11 forwarding may not work properly${NC}"
    echo "  Ensure you're running Windows 11 build 22000+ or later with WSLg enabled"
fi

# Step 3: Pull Docker image
echo -e "\n[3/5] Pulling Docker-OSX image..."
docker pull sickcodes/docker-osx:ventura

# Step 4: Create disk image if not exists
echo -e "\n[4/5] Checking macOS disk image..."
if [ ! -f ./macos-disk.img ]; then
    echo "Creating new macOS disk image (this will happen on first container start)..."
    echo "The disk image will be created automatically by Docker-OSX"
fi

# Step 5: Start container
echo -e "\n[5/5] Starting macOS container..."
echo -e "${GREEN}Run: docker compose up -d${NC}"
echo -e "${GREEN}Or for interactive mode: docker compose up${NC}"

echo -e "\n=== Container Ready ==="
echo -e "\nNext steps:"
echo "  1. Start container: docker compose up -d"
echo "  2. Wait 2-3 minutes for macOS to boot"
echo "  3. SSH into container: ssh -p 50922 user@localhost"
echo "     (password: alpine)"
echo "  4. Run: ./install-tools.sh inside macOS to install pluginval and REAPER"
echo -e "\nFor VNC access (if not using WSLg):"
echo "  Connect VNC to: localhost:8888"

# Get VNC password if container is running
if docker ps | grep -q macos-au-tester; then
    echo -e "\n${GREEN}Container is already running!${NC}"
    echo -e "VNC password:"
    docker exec macos-au-tester cat vncpasswd_file 2>/dev/null || echo "(run container first)"
fi
