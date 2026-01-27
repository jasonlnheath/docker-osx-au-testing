#!/bin/bash
# Backup macOS installation to a tar archive
# Usage: ./backup-macos.sh [--name "<name>"] [--description "<description>"]
# Run this periodically or before making major changes

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/macos-backup-$TIMESTAMP.tar.gz"
METADATA_FILE="$BACKUP_DIR/backups.json"

# Parse arguments
BACKUP_NAME=""
BACKUP_DESCRIPTION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      BACKUP_NAME="$2"
      shift 2
      ;;
    --description)
      BACKUP_DESCRIPTION="$2"
      shift 2
      ;;
    *)
      echo "❌ Error: Unknown option $1"
      echo "   Usage: $0 [--name \"<name>\"] [--description \"<description>\"]"
      exit 1
      ;;
  esac
done

# Prompt for missing metadata
if [ -z "$BACKUP_NAME" ]; then
  read -p "Enter backup name: " BACKUP_NAME
fi

if [ -z "$BACKUP_DESCRIPTION" ]; then
  read -p "Enter backup description: " BACKUP_DESCRIPTION
fi

# Validate inputs
if [ -z "$BACKUP_NAME" ]; then
  echo "❌ Error: Backup name is required"
  exit 1
fi

echo "📦 Creating macOS backup..."
echo "   Name: $BACKUP_NAME"
echo "   Description: $BACKUP_DESCRIPTION"
echo "   Target: $BACKUP_FILE"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Initialize metadata file if it doesn't exist
if [ ! -f "$METADATA_FILE" ]; then
  echo '{"backups":[]}' > "$METADATA_FILE"
fi

# Stop container to ensure consistent backup
echo "⏹️  Stopping container..."
docker-compose stop

# Export the macos-disk volume
echo "💾 Exporting macos-disk volume (this may take 10-30 minutes)..."
docker run --rm \
  -v docker-osx-au-testing_macos-disk:/data:ro \
  -v "$PWD/$BACKUP_DIR":/backup \
  alpine tar czf "/backup/$(basename $BACKUP_FILE)" -C /data .

# Get file size in bytes and convert to GB
BACKUP_SIZE_BYTES=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_FILE")
BACKUP_SIZE_GB=$(awk "BEGIN {printf \"%.1f\", $BACKUP_SIZE_BYTES / 1024 / 1024 / 1024}")

# Get ISO 8601 timestamp
TIMESTAMP_ISO=$(date -Iseconds)

# Create backup ID
BACKUP_ID="$TIMESTAMP"

# Add metadata to JSON using temporary file
TMP_FILE=$(mktemp)
jq --arg id "$BACKUP_ID" \
   --arg name "$BACKUP_NAME" \
   --arg description "$BACKUP_DESCRIPTION" \
   --arg filename "$(basename $BACKUP_FILE)" \
   --arg timestamp "$TIMESTAMP_ISO" \
   --arg size_gb "$BACKUP_SIZE_GB" \
   '.backups += [{
     "id": $id,
     "name": $name,
     "description": $description,
     "filename": $filename,
     "timestamp": $timestamp,
     "size_gb": ($size_gb | tonumber)
   }]' "$METADATA_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$METADATA_FILE"

# Restart container
echo "▶️  Restarting container..."
docker-compose start

echo ""
echo "✅ Backup complete!"
echo "   ID: $BACKUP_ID"
echo "   Name: $BACKUP_NAME"
echo "   File: $BACKUP_FILE"
echo "   Size: ${BACKUP_SIZE_GB} GB"
echo ""
echo "To restore, run:"
echo "   ./restore-macos.sh $BACKUP_FILE"
echo "   or use: /macos-restore"
