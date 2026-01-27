---
description: Create a named backup of the macOS Docker container with metadata
---

# macOS Backup Skill

Creates a timestamped backup of the macOS Docker container with a name and description stored in metadata.

## What this skill does

1. Prompts the user for a backup name
2. Prompts the user for a description
3. Stops the macOS Docker container
4. Creates a compressed tarball backup of the macos-disk volume
5. Writes metadata to `./backups/backups.json`
6. Restarts the container
7. Displays success message with backup details

## Usage

Run `/macos-backup` and follow the prompts.

## Implementation

1. Get backup name from user
2. Get description from user
3. Run: `./backup-macos.sh --name "<name>" --description "<description>"`
