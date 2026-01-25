#!/bin/bash
# Run this in macOS terminal to set up SSH key authentication
# Access via http://localhost:8006 or VNC localhost:5999

# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add Windows public key to authorized_keys
cat >> ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFi7Kx9p9yljgpgZPP9OkzG0V+WkB51gfm/+e76h0qO jasonheath@localhost
EOF

chmod 600 ~/.ssh/authorized_keys

echo "SSH key configured. Now test from Windows:"
echo "ssh -p 50922 user@localhost"
