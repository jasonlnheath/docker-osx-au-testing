#!/bin/bash
# Restore macOS installation from a backup archive
# Usage: ./restore-macos.sh <backup-file.tar.gz> OR ./restore-macos.sh --list

set -e

BACKUP_DIR="./backups"
METADATA_FILE="$BACKUP_DIR/backups.json"

# List backups mode
if [ "$1" = "--list" ]; then
  if [ ! -f "$METADATA_FILE" ]; then
    echo "❌ No backup metadata found. Run ./backup-macos.sh first."
    exit 1
  fi

  echo "Available Backups:"
  echo "=================="
  jq -r '.backups | to_entries[] | "
[\(.key + 1)] \(.value.name)
    Description: \(.value.description)
    Created: \(.value.timestamp)
    File: \(.value.filename)
    Size: \(.value.size_gb) GB"' "$METADATA_FILE"
  exit 0
fi

# Check for metadata file
if [ -f "$METADATA_FILE" ]; then
  # Check if argument is a number (index)
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    BACKUP_INDEX=$(($1 - 1))
    BACKUP_FILE="$BACKUP_DIR/$(jq -r ".backups[$BACKUP_INDEX].filename" "$METADATA_FILE")"
    BACKUP_NAME=$(jq -r ".backups[$BACKUP_INDEX].name" "$METADATA_FILE")
  else
    # Use as filename directly
    BACKUP_FILE="$1"
    # Try to find matching backup in metadata
    BACKUP_FILENAME=$(basename "$BACKUP_FILE")
    BACKUP_NAME=$(jq -r ".backups[] | select(.filename == \"$BACKUP_FILENAME\") | .name" "$METADATA_FILE" 2>/dev/null || echo "")
  fi
else
  BACKUP_FILE="$1"
  BACKUP_NAME=""
fi

# Default to first argument if not set
if [ -z "$BACKUP_FILE" ] && [ -n "$1" ]; then
  BACKUP_FILE="$1"
fi

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Error: Please specify a backup file"
  echo "   Usage: $0 <backup-file.tar.gz>"
  echo "   Usage: $0 <backup-number>  (use --list to see numbers)"
  echo "   Usage: $0 --list           (list all backups)"
  echo ""
  echo "Available backups:"
  ls -lh ./backups/*.tar.gz 2>/dev/null || echo "   No backups found in ./backups/"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

# Check if container is running
CONTAINER_RUNNING=$(docker inspect -f '{{.State.Running}}' macos-au-tester 2>/dev/null || echo "false")

echo "📦 Restoring macOS from backup..."
if [ -n "$BACKUP_NAME" ]; then
  echo "   Name: $BACKUP_NAME"
fi
echo "   Source: $BACKUP_FILE"

if [ "$CONTAINER_RUNNING" = "true" ]; then
  echo "   Status: Container is currently running"
fi

# Confirm restoration
read -p "⚠️  This will REPLACE your current macOS installation. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "❌ Restoration cancelled."
  exit 0
fi

# Stop and remove container
echo "⏹️  Stopping and removing container..."
docker-compose down

# Remove the old volume
echo "🗑️  Removing old macos-disk volume..."
docker volume rm docker-osx-au-testing_macos-disk || docker volume rm macos-disk

# Create a new volume
echo "➕ Creating new macos-disk volume..."
docker volume create docker-osx-au-testing_macos-disk

# Restore the backup
echo "💾 Restoring backup (this may take 10-30 minutes)..."
docker run --rm \
  -v docker-osx-au-testing_macos-disk:/data \
  -v "$PWD/$(dirname $BACKUP_FILE)":/backup \
  alpine tar xzf "/backup/$(basename $BACKUP_FILE)" -C /data

# Start container
echo "▶️  Starting container..."
docker-compose up -d

echo ""
echo "✅ Restoration complete!"
if [ -n "$BACKUP_NAME" ]; then
  echo "   Restored: $BACKUP_NAME"
fi
echo "   Your macOS installation has been restored."
