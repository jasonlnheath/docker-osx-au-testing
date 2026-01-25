#!/bin/bash
# Run this in macOS terminal to diagnose SSH setup

echo "=== Checking .ssh directory ==="
ls -la ~/.ssh/

echo -e "\n=== Checking authorized_keys ==="
if [ -f ~/.ssh/authorized_keys ]; then
    echo "authorized_keys exists. Contents:"
    cat ~/.ssh/authorized_keys
else
    echo "authorized_keys NOT found!"
fi

echo -e "\n=== Expected key (copy this entire line): ==="
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFi7Kx9p9yljgpgZPP9OkzG0V+WkB51gfm/+e76h0qO jasonheath@localhost"

echo -e "\n=== To fix, run: ==="
echo 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
echo 'echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFi7Kx9p9yljgpgZPP9OkzG0V+WkB51gfm/+e76h0qO jasonheath@localhost" > ~/.ssh/authorized_keys'
echo 'chmod 600 ~/.ssh/authorized_keys'
