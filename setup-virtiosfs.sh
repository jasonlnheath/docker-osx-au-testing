#!/bin/bash
# setup-virtiosfs.sh - Run inside macOS VM to configure VirtioFS mounts

set -e

echo "=== Setting up VirtioFS mounts ==="

# Create mount points
sudo mkdir -p /host-source
sudo mkdir -p /host-build

# Backup fstab
sudo cp /etc/fstab /etc/fstab.backup-$(date +%Y%m%d)

# Remove old entries if exist
sudo sed -i '.bak' '/host-source/d' /etc/fstab 2>/dev/null || true
sudo sed -i '.bak' '/host-build/d' /etc/fstab 2>/dev/null || true

# Add VirtioFS mounts to /etc/fstab
echo "host-source /host-source virtfs ro,local 0 0" | sudo tee -a /etc/fstab
echo "host-build /host-build virtfs rw,local 0 0" | sudo tee -a /etc/fstab

# Mount filesystems
sudo mount -t virtfs host-source /host-source 2>/dev/null || echo "Note: virtfs may already be mounted or uses different syntax"
sudo mount -t virtfs host-build /host-build 2>/dev/null || echo "Note: virtfs may already be mounted or uses different syntax"

# Verify mounts
echo "=== Current mounts ==="
df -h | grep host || echo "No host mounts found (may be using different mount type)"
mount | grep -E "(host|virtfs)" || echo "No virtfs mounts found"

# Test extended attributes support (CRITICAL for AU components)
echo "=== Testing extended attributes ==="
touch /host-build/test-xattr.txt 2>/dev/null || echo "Cannot write to /host-build"
if [ -f /host-build/test-xattr.txt ]; then
    xattr -w com.apple.test.attr "testvalue" /host-build/test-xattr.txt 2>/dev/null && echo "PASS: xattr write succeeded" || echo "WARN: xattr write failed"
    xattr -l /host-build/test-xattr.txt 2>/dev/null && echo "PASS: xattr read succeeded" || echo "WARN: xattr read failed"
    rm /host-build/test-xattr.txt
fi

echo "=== VirtioFS setup complete ==="
