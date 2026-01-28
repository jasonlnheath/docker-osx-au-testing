#!/bin/bash
# Setup SSH for AU validation - run this in macOS Terminal

echo "Setting up SSH..."

# Enable SSH
sudo systemsetup -setremotelogin on

# Set up SSH key
mkdir -p ~/.ssh
cat > ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFi7Kx9p9yljgpgZPP9OkzG0V+WkB51gfm/+e76h0qO jasonheath@localhost
EOF

chmod 600 ~/.ssh/authorized_keys

echo "SSH setup complete!"
echo "You can now run ./validate-au.sh AmpBender from Windows"
