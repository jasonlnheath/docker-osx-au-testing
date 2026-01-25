#!/bin/bash
# setup-audio-wslg.sh
# Fallback PulseAudio installation for WSL2 when WSLg PulseAudio socket is unavailable
#
# Usage: source setup-audio-wslg.sh (run from WSL2 terminal)

set -e

echo "=== WSL2 PulseAudio Setup Script ==="
echo ""

# Check if running in WSL2
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "ERROR: This script must be run from WSL2"
    exit 1
fi

# Check if PulseAudio is already installed
if command -v pulseaudio &> /dev/null; then
    echo "PulseAudio is already installed:"
    pulseaudio --version
    echo ""
else
    echo "Installing PulseAudio..."
    sudo apt update
    sudo apt install -y pulseaudio pulseaudio-utils
    echo "PulseAudio installed successfully"
fi

# Create pulse directory if it doesn't exist
PULSE_DIR="/run/user/1000/pulse"
if [ ! -d "$PULSE_DIR" ]; then
    echo "Creating PulseAudio directory: $PULSE_DIR"
    mkdir -p "$PULSE_DIR"
fi

# Start PulseAudio if not running
if ! pulseaudio --check -v 2>/dev/null; then
    echo "Starting PulseAudio..."
    pulseaudio --daemonize=no -v
    sleep 2
fi

# Verify PulseAudio is running
if pulseaudio --check -v 2>/dev/null; then
    echo "PulseAudio is running"
else
    echo "WARNING: PulseAudio may not be running properly"
fi

# Check for PulseAudio socket
if [ -S "/run/user/1000/pulse/native" ]; then
    echo "PulseAudio socket found at: /run/user/1000/pulse/native"
else
    echo "WARNING: PulseAudio socket not found at: /run/user/1000/pulse/native"
    echo "The socket may be created when PulseAudio starts properly"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Update docker-compose.yml volume mount to:"
echo "   - /run/user/1000/pulse/native:/tmp/pulseaudio.socket"
echo ""
echo "2. Restart the container:"
echo "   docker-compose down"
echo "   docker-compose up -d"
echo ""
